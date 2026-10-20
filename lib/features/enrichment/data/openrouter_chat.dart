import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../domain/ai_model_catalog.dart';
import '../domain/enrichment.dart';
import '../domain/free_model_policy.dart';
import 'ai_local_store.dart';
import 'ai_settings_store.dart';
import 'free_model_catalog.dart';
import 'openrouter_client.dart';

/// A validated answer of one chat request.
class ChatAnswer<T> {
  const ChatAnswer(
    this.value, {
    required this.model,
    this.cost,
    this.attempts = const [],
  });

  /// Every attempt, the last one successful.
  final List<AiAttempt> attempts;

  final T value;

  /// The model that actually answered.
  final String model;

  /// Cost reported by OpenRouter for the request, if it reported one.
  final double? cost;
}

/// Sends one logical request to OpenRouter under the user's AI settings:
/// their own key (D27/D28) and the free-only policy (D41). Shared by every
/// AI feature, so they all follow exactly the same rules:
///
/// - free-only mode (the default) uses only the free router or models
///   verified free in the live list; every request carries a zero
///   `max_price`; every answer is checked and a non-free one stops the
///   request with `paidModelBlocked`;
/// - fallbacks go only to other free attempts and only for failures another
///   model may fix; they share one retry budget with the client's own
///   retries, so a request never sends more than `1 + aiMaxRetries`
///   requests;
/// - pacing, rate limits, the daily quota and the D32 rule (no automatic
///   repeat of possibly billed requests) are enforced by [OpenRouterClient].
///
/// With free-only mode turned off by the user, the chosen catalog model is
/// used. No request is ever sent without a saved key.
class OpenRouterChat {
  OpenRouterChat({
    required this.client,
    required this._settings,
    this._localState,
    this._catalog,
  });

  final OpenRouterClient client;
  final AiSettingsStore _settings;
  final AiLocalState? _localState;
  final FreeModelCatalog? _catalog;

  /// Price ceiling sent with free-only requests (USD; zero = free only).
  static const zeroMaxPrice = {'prompt': 0, 'completion': 0, 'request': 0};

  /// The saved key. Throws `notConfigured` when there is none, so nothing
  /// is ever sent without it.
  Future<String> requireApiKey() async {
    final apiKey = (await _settings.readApiKey())?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const EnrichmentException(EnrichmentError.notConfigured);
    }
    return apiKey;
  }

  /// The user's AI preferences; free-only when they cannot be read.
  Future<AiPreferences> preferences() async {
    try {
      return await _localState?.readPreferences() ?? const AiPreferences();
    } on StorageException {
      // Unreadable preferences: the safe default is free-only.
      return const AiPreferences();
    }
  }

  /// Output room reserved for (low-effort) reasoning on top of the
  /// visible answer. Every free model on OpenRouter is a reasoning model
  /// (October 2026), and reasoning tokens count against `max_tokens`: with
  /// too small a limit the model spends it all reasoning and returns no
  /// answer (`finish_reason: length`, empty content).
  static const reasoningAllowance = 3000;

  /// Highest `max_tokens` sent (within every free model's output limit).
  static const maxOutputTokens = 8000;

  /// `max_tokens` and reasoning controls for an answer of about
  /// [visibleTokens] tokens. In free-only mode reasoning is asked to be
  /// brief and left out of the response; with free-only off nothing is
  /// added (the chosen catalog model may not support the parameter, and
  /// `require_parameters` would then find no endpoint).
  static Map<String, Object?> outputControls({
    required int visibleTokens,
    required bool freeOnly,
  }) => {
    'max_tokens': min(maxOutputTokens, reasoningAllowance + visibleTokens),
    if (freeOnly) 'reasoning': {'effort': 'low', 'exclude': true},
  };

  /// Sends the request [body] builds for each attempt and returns [parse]'s
  /// result for the first usable answer. [parse] receives the model's text
  /// and throws `EnrichmentException(malformedResponse)` for an unusable
  /// answer (another free model may then be tried).
  ///
  /// [tag] names the feature in the diagnostic log; every attempt is logged
  /// and attached to a failure ([EnrichmentException.attempts]) without the
  /// key or any content.
  Future<ChatAnswer<T>> send<T>({
    required String apiKey,
    required AiPreferences prefs,
    required Map<String, Object?> Function(ModelAttempt attempt) body,
    required T Function(String content) parse,
    EnrichmentCancellation? cancellation,
    Duration? timeout,
    String tag = 'ai',
  }) async {
    final (attempts, verifiedIds) = await _plan(prefs);
    final budget = RetryBudget(client.maxRetries);
    final log = <AiAttempt>[];
    for (var a = 0; ; a++) {
      final attempt = attempts[a];
      Map<String, Object?>? json;
      try {
        json = await client.chatCompletion(
          apiKey: apiKey,
          body: body(attempt),
          cancellation: cancellation,
          budget: budget,
          free: prefs.freeOnly,
          timeout: timeout,
        );
        final usedModel = json['model'] is String
            ? json['model']! as String
            : attempt.model;
        if (prefs.freeOnly) _enforceZeroCost(json, usedModel, verifiedIds);
        final value = parse(_content(json));
        _record(tag, log, attempt, json, null);
        await _quietly(() async => _localState?.recordModelUsed(usedModel));
        return ChatAnswer(
          value,
          model: usedModel,
          cost: _cost(json),
          attempts: List.unmodifiable(log),
        );
      } on EnrichmentException catch (e) {
        _record(tag, log, attempt, json, e);
        final hasNext = a + 1 < attempts.length;
        final fallBack =
            prefs.freeOnly &&
            hasNext &&
            _canFallBack(e) &&
            // Another free model may succeed; it counts against the same
            // retry budget as same-model retries.
            budget.tryConsume();
        if (!fallBack) throw e.withAttempts(log);
      }
    }
  }

  static void _record(
    String tag,
    List<AiAttempt> log,
    ModelAttempt attempt,
    Map<String, Object?>? json,
    EnrichmentException? error,
  ) {
    final usage = json?['usage'];
    final details = usage is Map ? usage['completion_tokens_details'] : null;
    final choices = json?['choices'];
    final first = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    int? number(Object? v) => v is num ? v.toInt() : null;
    final entry = AiAttempt(
      model: attempt.model,
      outputMode: attempt.outputMode.name,
      answeredBy: json?['model'] is String ? json!['model']! as String : null,
      statusCode: error?.statusCode ?? (json == null ? null : 200),
      error: error?.error,
      problem: error?.problem,
      finishReason: first is Map && first['finish_reason'] is String
          ? first['finish_reason']! as String
          : null,
      completionTokens: usage is Map
          ? number(usage['completion_tokens'])
          : null,
      reasoningTokens: details is Map
          ? number(details['reasoning_tokens'])
          : null,
      contentLength: content is String ? content.length : null,
      detail: error?.detail,
    );
    log.add(entry);
    // Local diagnostics only: model ids, statuses and counts.
    debugPrint('[$tag] attempt ${log.length}: $entry');
  }

  Future<(List<ModelAttempt>, Set<String>)> _plan(AiPreferences prefs) async {
    final paidModel = AiModelCatalog.resolve(
      prefs.freeOnly ? null : await _settings.readModel(),
    );
    var ranked = const <OpenRouterModelInfo>[];
    if (prefs.freeOnly && prefs.mode == FreeRoutingMode.qualityFree) {
      try {
        ranked = (await _catalog?.load())?.ranked ?? const [];
      } on EnrichmentException {
        // Not verifiable now: only the free router is used.
        ranked = const [];
      }
    }
    return (
      planAttempts(
        freeOnly: prefs.freeOnly,
        mode: prefs.mode,
        paidModel: paidModel,
        rankedFree: ranked,
      ),
      {for (final m in ranked) m.id},
    );
  }

  /// Failures where a different free model may succeed. Never: invalid
  /// key, credits, forbidden, account rate limits, the daily quota,
  /// network, timeouts (it may still be running) or cancellation.
  static bool _canFallBack(EnrichmentException e) => switch (e.error) {
    EnrichmentError.modelUnavailable ||
    EnrichmentError.badRequest ||
    EnrichmentError.server ||
    EnrichmentError.malformedResponse => true,
    EnrichmentError.rateLimited => e.upstream,
    _ => false,
  };

  /// Free-only safety net after the fact. The request has been answered;
  /// if it was not free, nothing more is sent.
  static void _enforceZeroCost(
    Map<String, Object?> json,
    String model,
    Set<String> verifiedIds,
  ) {
    final cost = _cost(json);
    if (cost != null && cost > 0) {
      throw const EnrichmentException(EnrichmentError.paidModelBlocked);
    }
    if (!FreeModelPolicy.isFreeModelId(model, verifiedIds: verifiedIds) &&
        cost != 0) {
      throw const EnrichmentException(EnrichmentError.paidModelBlocked);
    }
  }

  static String _content(Map<String, Object?> json) {
    final choices = json['choices'];
    final first = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    final text = content is String ? content.trim() : '';
    // A truncated answer is not valid JSON we can trust.
    if (first is Map && first['finish_reason'] == 'length') {
      throw EnrichmentException(
        EnrichmentError.malformedResponse,
        problem: text.isEmpty
            ? ResponseProblem.cutOffWhileReasoning
            : ResponseProblem.cutOff,
      );
    }
    if (text.isEmpty) {
      throw const EnrichmentException(
        EnrichmentError.malformedResponse,
        problem: ResponseProblem.empty,
      );
    }
    return text;
  }

  static double? _cost(Map<String, Object?> json) {
    final usage = json['usage'];
    return usage is Map && usage['cost'] is num
        ? (usage['cost']! as num).toDouble()
        : null;
  }

  /// Local bookkeeping must never fail a request.
  static Future<void> _quietly(Future<void> Function() write) async {
    try {
      await write();
    } on StorageException {
      // Informational only.
    }
  }
}
