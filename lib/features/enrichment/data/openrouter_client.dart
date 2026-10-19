import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/time/clock.dart';
import '../domain/enrichment.dart';
import '../domain/free_model_policy.dart';
import 'ai_local_store.dart';
import 'request_scheduler.dart';

/// Key details reported by `GET /api/v1/key`. Amounts are OpenRouter
/// credits (USD), exactly as reported; nothing is estimated.
@immutable
class OpenRouterKeyInfo {
  const OpenRouterKeyInfo({
    this.label,
    this.usage,
    this.limit,
    this.limitRemaining,
    this.isFreeTier,
    this.freeDailyUsed,
    this.freeDailyLimit,
    this.freeDailyRemaining,
  });

  factory OpenRouterKeyInfo.fromJson(Map<String, Object?> json) {
    double? number(Object? v) => v is num ? v.toDouble() : null;
    int? integer(Object? v) => v is num ? v.toInt() : null;
    final free = json['free_model_daily_requests'];
    final daily = free is Map ? free : const {};
    return OpenRouterKeyInfo(
      label: json['label'] is String ? json['label']! as String : null,
      usage: number(json['usage']),
      limit: number(json['limit']),
      limitRemaining: number(json['limit_remaining']),
      isFreeTier: json['is_free_tier'] is bool
          ? json['is_free_tier']! as bool
          : null,
      freeDailyUsed: integer(daily['used']),
      freeDailyLimit: integer(daily['limit']),
      freeDailyRemaining: integer(daily['remaining']),
    );
  }

  final String? label;

  /// Credits used by this key so far.
  final double? usage;

  /// Credit limit of the key; null when unlimited.
  final double? limit;
  final double? limitRemaining;

  /// Whether the account has never bought credits.
  final bool? isFreeTier;

  /// Free-model requests in the current UTC day (`free_model_daily_requests`).
  final int? freeDailyUsed;
  final int? freeDailyLimit;
  final int? freeDailyRemaining;
}

/// Retries left for one logical request, shared by same-model retries and
/// free-model fallbacks, so one batch never sends more than
/// `1 + AppConfig.aiMaxRetries` requests.
class RetryBudget {
  RetryBudget([this.remaining = AppConfig.aiMaxRetries]);

  int remaining;

  bool tryConsume() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}

/// Minimal client for the documented OpenRouter API
/// (https://openrouter.ai/docs): chat completions, key info, model list.
///
/// The API key is passed per call (never stored here), sent only in the
/// `Authorization` header to [baseUrl], and never logged or put into
/// exceptions.
class OpenRouterClient {
  OpenRouterClient(
    this._http, {
    this.baseUrl = AppConfig.openRouterBaseUrl,
    this.requestTimeout = AppConfig.aiRequestTimeout,
    this.checkTimeout = AppConfig.aiCheckTimeout,
    this.maxRetries = AppConfig.aiMaxRetries,
    this.backoffBase = AppConfig.aiBackoffBase,
    this.scheduler,
    this._clock = const SystemClock(),
    Random? random,
    Future<void> Function(Duration)? sleep,
  }) : _random = random ?? Random(),
       _sleep = sleep ?? Future<void>.delayed;

  final http.Client _http;
  final String baseUrl;
  final Duration requestTimeout;
  final Duration checkTimeout;
  final int maxRetries;
  final Duration backoffBase;

  /// Paces requests app-wide; none in isolated tests.
  final RequestScheduler? scheduler;
  final Clock _clock;
  final Random _random;
  final Future<void> Function(Duration) _sleep;

  /// App attribution headers (optional, documented by OpenRouter). They
  /// contain no user data.
  static const _attribution = {'X-OpenRouter-Title': AppConfig.productName};

  Map<String, String> _auth(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    ..._attribution,
  };

  /// `POST /chat/completions`. Returns the decoded response body.
  ///
  /// A request is repeated automatically only when OpenRouter has clearly
  /// rejected it before any model ran ([isRejectedBeforeGeneration]: 429,
  /// 503, and 402 with `Retry-After`), while [budget] allows (default:
  /// [maxRetries]). The wait honours `Retry-After` (or the rate-limit
  /// reset) exactly; when that is longer than [AppConfig.aiMaxRetryDelay]
  /// the request fails at once with [EnrichmentException.retryAt] set.
  /// Otherwise it backs off exponentially with random jitter.
  ///
  /// A 429 for the daily free-model quota is never retried: free requests
  /// are paused until the quota resets ([free] requests only).
  ///
  /// Everything else fails at once. In particular, a client timeout, a
  /// dropped connection, 408/500/502, or a 200 carrying an error do not
  /// prove that nothing was generated or billed; repeating them is left to
  /// the user ("Retry failed items") or, for free models, to the fallback.
  Future<Map<String, Object?>> chatCompletion({
    required String apiKey,
    required Map<String, Object?> body,
    EnrichmentCancellation? cancellation,
    RetryBudget? budget,
    bool free = false,
  }) async {
    final payload = jsonEncode(body);
    final retries = budget ?? RetryBudget(maxRetries);
    for (var attempt = 0; ; attempt++) {
      _throwIfCancelled(cancellation);
      Duration wait;
      try {
        final response = await _send(
          () => cancellable(
            _http
                .post(
                  Uri.parse('$baseUrl/chat/completions'),
                  headers: {
                    ..._auth(apiKey),
                    'Content-Type': 'application/json',
                  },
                  body: payload,
                )
                .timeout(requestTimeout),
            cancellation,
          ),
          free: free,
          cancellation: cancellation,
        );
        final json = _decodeBody(response);
        final status = response.statusCode;
        final errorBody = json?['error'];
        if (status == 200) {
          // Errors after the provider accepted the request arrive as 200
          // with an `error` object and no choices. Generation may already
          // have run, so these are never repeated automatically.
          if (errorBody is Map) {
            final code = errorBody['code'];
            throw _errorFor(code is int && code >= 400 ? code : 502, errorBody);
          }
          if (json == null) {
            throw const EnrichmentException(EnrichmentError.malformedResponse);
          }
          return json;
        }
        final limit = status == 429 ? _rateLimit(response, errorBody) : null;
        if (limit != null && limit.daily) {
          final until = limit.reset ?? nextUtcMidnight(_clock.nowUtc());
          if (free) await scheduler?.pauseFreeUntil(until);
          throw EnrichmentException(
            EnrichmentError.dailyQuotaExhausted,
            statusCode: status,
            retryAt: until,
          );
        }
        final retryAfter = _retryAfter(response) ?? limit?.resetIn;
        final retryAt = retryAfter == null
            ? null
            : _clock.nowUtc().add(retryAfter);
        final error = _errorFor(
          status,
          errorBody is Map ? errorBody : null,
          retryAt: retryAt,
          upstream: limit != null && !limit.platform,
        );
        if (!isRejectedBeforeGeneration(
              status,
              retryAfter: _retryAfter(response),
            ) ||
            // A free model's provider is saturated: another free model is
            // tried instead (by the caller) rather than this one again.
            (free && error.upstream)) {
          throw error;
        }
        if (retryAfter != null && retryAfter > AppConfig.aiMaxRetryDelay) {
          // Honour the full wait instead of retrying early.
          if (limit?.platform ?? false) scheduler?.coolDownUntil(retryAt!);
          throw error;
        }
        if (!retries.tryConsume()) {
          if (retryAt != null && (limit?.platform ?? false)) {
            scheduler?.coolDownUntil(retryAt);
          }
          throw error;
        }
        wait = retryAfter ?? backoff(attempt);
      } on TimeoutException {
        // The request may still be running (and billed) on the server.
        throw const EnrichmentException(EnrichmentError.timeout);
      } on EnrichmentException {
        rethrow;
      } on Object catch (e) {
        // The request may have been sent before the connection failed.
        if (_isNetworkError(e)) {
          throw const EnrichmentException(EnrichmentError.network);
        }
        rethrow;
      }
      _throwIfCancelled(cancellation);
      await cancellable(_sleep(wait), cancellation);
    }
  }

  /// Exponential backoff: [backoffBase] × 2^[retry], plus up to 50 %
  /// random jitter so that retries do not line up.
  @visibleForTesting
  Duration backoff(int retry) {
    final base = backoffBase * (1 << retry);
    return base + base * (_random.nextDouble() * 0.5);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() post, {
    required bool free,
    EnrichmentCancellation? cancellation,
  }) {
    final s = scheduler;
    return s == null
        ? post()
        : s.run(post, free: free, cancellation: cancellation);
  }

  /// `GET /key`: checks that [apiKey] is valid and reports its usage and
  /// the free-model daily requests left.
  Future<OpenRouterKeyInfo> keyInfo(String apiKey) async {
    final response = await _get(Uri.parse('$baseUrl/key'), _auth(apiKey));
    final json = _decodeBody(response);
    if (response.statusCode != 200) {
      throw _errorFor(response.statusCode, json?['error']);
    }
    final data = json?['data'];
    if (data is! Map) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    return OpenRouterKeyInfo.fromJson(data.cast<String, Object?>());
  }

  /// The public model list (`GET /models`, text models). No key is sent.
  Future<List<OpenRouterModelInfo>> listModels() async {
    final response = await _get(Uri.parse('$baseUrl/models'), _attribution);
    final json = _decodeBody(response);
    if (response.statusCode != 200) {
      throw _errorFor(response.statusCode, json?['error']);
    }
    final data = json?['data'];
    if (data is! List) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    return [
      for (final m in data)
        if (m is Map) ?OpenRouterModelInfo.fromJson(m.cast<String, Object?>()),
    ];
  }

  /// Whether [modelId] is currently listed with structured-output support.
  /// The model list is public: no key is sent.
  Future<bool> supportsStructuredOutputs(String modelId) async {
    final response = await _get(
      Uri.parse('$baseUrl/models?supported_parameters=structured_outputs'),
      _attribution,
    );
    final json = _decodeBody(response);
    if (response.statusCode != 200) {
      throw _errorFor(response.statusCode, json?['error']);
    }
    final data = json?['data'];
    if (data is! List) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    return data.any((m) => m is Map && m['id'] == modelId);
  }

  Future<http.Response> _get(Uri uri, Map<String, String> headers) async {
    try {
      return await _http.get(uri, headers: headers).timeout(checkTimeout);
    } on TimeoutException {
      throw const EnrichmentException(EnrichmentError.timeout);
    } on Object catch (e) {
      if (_isNetworkError(e)) {
        throw const EnrichmentException(EnrichmentError.network);
      }
      rethrow;
    }
  }

  /// Statuses with which OpenRouter refuses a request before routing it to
  /// a model, so repeating it cannot produce a second billed generation:
  /// 429 (rate limited), 503 (no provider available for the routing
  /// requirements) and 402 with `Retry-After` (a temporary in-flight budget
  /// limit). A 402 without `Retry-After` means the credits are exhausted.
  ///
  /// 408, 500 and 502 can occur after a provider has started generating,
  /// so they are not on this list.
  @visibleForTesting
  static bool isRejectedBeforeGeneration(int status, {Duration? retryAfter}) =>
      status == 429 || status == 503 || (status == 402 && retryAfter != null);

  /// Reads a 429. OpenRouter's own limits carry `X-RateLimit-*` headers;
  /// a 429 without them was passed on from the model provider. The daily
  /// free-model limit is recognised by its message, or by a platform 429
  /// with nothing remaining and a reset more than a minute away (the
  /// per-minute limit resets within a minute).
  ({bool platform, bool daily, DateTime? reset, Duration? resetIn}) _rateLimit(
    http.Response response,
    Object? errorBody,
  ) {
    final h = response.headers;
    final platform =
        h.containsKey('x-ratelimit-limit') ||
        h.containsKey('x-ratelimit-remaining') ||
        h.containsKey('x-ratelimit-reset');
    final reset = _epoch(h['x-ratelimit-reset']);
    final now = _clock.nowUtc();
    final resetIn = reset != null && reset.isAfter(now)
        ? reset.difference(now)
        : null;
    final message = errorBody is Map && errorBody['message'] is String
        ? (errorBody['message']! as String).toLowerCase()
        : '';
    final daily =
        RegExp(r'per[- ]day|daily|requests per day').hasMatch(message) ||
        (platform &&
            h['x-ratelimit-remaining']?.trim() == '0' &&
            resetIn != null &&
            resetIn > const Duration(seconds: 65));
    return (platform: platform, daily: daily, reset: reset, resetIn: resetIn);
  }

  /// A Unix time in milliseconds (OpenRouter) or seconds.
  static DateTime? _epoch(String? raw) {
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      value > 100000000000 ? value : value * 1000,
      isUtc: true,
    );
  }

  static bool _isNetworkError(Object e) =>
      e is http.ClientException || e is SocketException || e is TlsException;

  static Map<String, Object?>? _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  /// Maps documented OpenRouter statuses. Only the status is kept: error
  /// messages may quote input text and are not stored.
  static EnrichmentException _errorFor(
    int status,
    Object? error, {
    DateTime? retryAt,
    bool upstream = false,
  }) {
    final message = error is Map && error['message'] is String
        ? (error['message']! as String).toLowerCase()
        : '';
    final kind = switch (status) {
      400 when message.contains('model') => EnrichmentError.modelUnavailable,
      400 => EnrichmentError.badRequest,
      401 => EnrichmentError.invalidKey,
      402 => EnrichmentError.insufficientCredits,
      403 => EnrichmentError.forbidden,
      404 => EnrichmentError.modelUnavailable,
      408 => EnrichmentError.timeout,
      429 => EnrichmentError.rateLimited,
      502 || 503 => EnrichmentError.modelUnavailable,
      _ => EnrichmentError.server,
    };
    return EnrichmentException(
      kind,
      statusCode: status,
      retryAt: retryAt,
      upstream: upstream,
    );
  }

  static Duration? _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  static void _throwIfCancelled(EnrichmentCancellation? cancellation) {
    if (cancellation?.isCancelled ?? false) {
      throw const EnrichmentException(EnrichmentError.cancelled);
    }
  }
}
