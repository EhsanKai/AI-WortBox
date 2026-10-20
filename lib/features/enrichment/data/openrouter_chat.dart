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
  const ChatAnswer(this.value, {required this.model, this.cost});

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

  /// Sends the request [body] builds for each attempt and returns [parse]'s
  /// result for the first usable answer. [parse] receives the model's text
  /// and throws `EnrichmentException(malformedResponse)` for an unusable
  /// answer (another free model may then be tried).
  Future<ChatAnswer<T>> send<T>({
    required String apiKey,
    required AiPreferences prefs,
    required Map<String, Object?> Function(ModelAttempt attempt) body,
    required T Function(String content) parse,
    EnrichmentCancellation? cancellation,
  }) async {
    final (attempts, verifiedIds) = await _plan(prefs);
    final budget = RetryBudget(client.maxRetries);
    for (var a = 0; ; a++) {
      final attempt = attempts[a];
      try {
        final json = await client.chatCompletion(
          apiKey: apiKey,
          body: body(attempt),
          cancellation: cancellation,
          budget: budget,
          free: prefs.freeOnly,
        );
        final usedModel = json['model'] is String
            ? json['model']! as String
            : attempt.model;
        if (prefs.freeOnly) _enforceZeroCost(json, usedModel, verifiedIds);
        final value = parse(_content(json));
        await _quietly(() async => _localState?.recordModelUsed(usedModel));
        return ChatAnswer(value, model: usedModel, cost: _cost(json));
      } on EnrichmentException catch (e) {
        final hasNext = a + 1 < attempts.length;
        if (!prefs.freeOnly || !hasNext || !_canFallBack(e)) rethrow;
        // Another free model may succeed; it counts against the same
        // retry budget as same-model retries.
        if (!budget.tryConsume()) rethrow;
      }
    }
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
    // A truncated answer is not valid JSON we can trust.
    if (content is! String ||
        (first is Map && first['finish_reason'] == 'length')) {
      throw const EnrichmentException(EnrichmentError.malformedResponse);
    }
    return content;
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
