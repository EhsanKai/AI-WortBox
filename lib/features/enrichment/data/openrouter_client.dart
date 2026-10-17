import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../domain/enrichment.dart';

/// Key details reported by `GET /api/v1/key`. Amounts are OpenRouter
/// credits (USD), exactly as reported; nothing is estimated.
@immutable
class OpenRouterKeyInfo {
  const OpenRouterKeyInfo({
    this.label,
    this.usage,
    this.limit,
    this.limitRemaining,
  });

  factory OpenRouterKeyInfo.fromJson(Map<String, Object?> json) {
    double? number(Object? v) => v is num ? v.toDouble() : null;
    return OpenRouterKeyInfo(
      label: json['label'] is String ? json['label']! as String : null,
      usage: number(json['usage']),
      limit: number(json['limit']),
      limitRemaining: number(json['limit_remaining']),
    );
  }

  final String? label;

  /// Credits used by this key so far.
  final double? usage;

  /// Credit limit of the key; null when unlimited.
  final double? limit;
  final double? limitRemaining;
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
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final http.Client _http;
  final String baseUrl;
  final Duration requestTimeout;
  final Duration checkTimeout;
  final int maxRetries;
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
  /// Generation is billed, so a request is repeated automatically only when
  /// OpenRouter has clearly rejected it before any model ran
  /// ([isRejectedBeforeGeneration]: 429, 503, and 402 with `Retry-After`),
  /// up to [maxRetries] times with backoff, honouring `Retry-After` up to
  /// [AppConfig.aiMaxRetryDelay].
  ///
  /// Everything else fails at once. In particular, a client timeout, a
  /// dropped connection, 408/500/502, or a 200 carrying an error do not
  /// prove that nothing was generated or billed; repeating them is left to
  /// the user ("Retry failed items").
  Future<Map<String, Object?>> chatCompletion({
    required String apiKey,
    required Map<String, Object?> body,
    EnrichmentCancellation? cancellation,
  }) async {
    final payload = jsonEncode(body);
    for (var attempt = 0; ; attempt++) {
      _throwIfCancelled(cancellation);
      Duration? retryAfter;
      try {
        final response = await _cancellable(
          _http
              .post(
                Uri.parse('$baseUrl/chat/completions'),
                headers: {..._auth(apiKey), 'Content-Type': 'application/json'},
                body: payload,
              )
              .timeout(requestTimeout),
          cancellation,
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
        final error = _errorFor(status, errorBody is Map ? errorBody : null);
        retryAfter = _retryAfter(response);
        if (!isRejectedBeforeGeneration(status, retryAfter: retryAfter) ||
            attempt >= maxRetries) {
          throw error;
        }
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
      await _cancellable(
        _sleep(retryAfter ?? Duration(seconds: 1 << attempt)),
        cancellation,
      );
    }
  }

  /// `GET /key`: checks that [apiKey] is valid and reports its usage.
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
  static EnrichmentException _errorFor(int status, Object? error) {
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
    return EnrichmentException(kind, statusCode: status);
  }

  static Duration? _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    if (seconds == null || seconds < 0) return null;
    final delay = Duration(seconds: seconds);
    return delay > AppConfig.aiMaxRetryDelay
        ? AppConfig.aiMaxRetryDelay
        : delay;
  }

  static void _throwIfCancelled(EnrichmentCancellation? cancellation) {
    if (cancellation?.isCancelled ?? false) {
      throw const EnrichmentException(EnrichmentError.cancelled);
    }
  }

  /// Completes with [future], or throws `cancelled` as soon as the user
  /// cancels. A request already sent may still finish (and be billed) on
  /// the server; its result is discarded.
  static Future<T> _cancellable<T>(
    Future<T> future,
    EnrichmentCancellation? cancellation,
  ) {
    if (cancellation == null) return future;
    return Future.any([
      future,
      cancellation.whenCancelled.then<T>(
        (_) => throw const EnrichmentException(EnrichmentError.cancelled),
      ),
    ]);
  }
}
