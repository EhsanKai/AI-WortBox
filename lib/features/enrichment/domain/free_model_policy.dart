import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';

/// How the free models are chosen.
enum FreeRoutingMode {
  /// OpenRouter's free router (`openrouter/free`) picks a free model.
  autoFree,

  /// The highest-scoring verified free models are asked first, with the
  /// free router as the last resort.
  qualityFree,
}

/// How a request asks for JSON.
enum StructuredOutputMode {
  /// `response_format: json_schema` (strict), only on endpoints that
  /// support it (`provider.require_parameters`).
  jsonSchema,

  /// `response_format: json_object`.
  jsonObject,

  /// No `response_format`; the prompt describes the JSON. The parser
  /// validates the answer either way.
  promptOnly,
}

/// One model entry of `GET /api/v1/models`, reduced to what the free-only
/// policy needs. Unknown or missing values are kept as null so that the
/// policy can treat them as unverified.
@immutable
class OpenRouterModelInfo {
  const OpenRouterModelInfo({
    required this.id,
    this.pricing,
    this.hasPricingOverrides = false,
    this.supportedParameters = const {},
    this.outputModalities,
    this.expirationDate,
    this.contextLength,
  });

  /// Parses one entry; null when it has no id.
  static OpenRouterModelInfo? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final rawPricing = json['pricing'];
    Map<String, Object?>? pricing;
    var overrides = false;
    if (rawPricing is Map) {
      pricing = {};
      for (final MapEntry(:key, :value) in rawPricing.entries) {
        if (key == 'overrides') {
          // Conditional prices: not verifiable as free.
          overrides = value != null && !(value is List && value.isEmpty);
        } else if (key is String) {
          pricing[key] = value;
        }
      }
    }
    final params = json['supported_parameters'];
    final architecture = json['architecture'];
    final outputs = architecture is Map
        ? architecture['output_modalities']
        : null;
    final expiration = json['expiration_date'];
    final context = json['context_length'];
    return OpenRouterModelInfo(
      id: id,
      pricing: pricing,
      hasPricingOverrides: overrides,
      supportedParameters: {
        if (params is List)
          for (final p in params)
            if (p is String) p,
      },
      outputModalities: outputs is List
          ? [
              for (final o in outputs)
                if (o is String) o,
            ]
          : null,
      expirationDate: expiration is String
          ? DateTime.tryParse(expiration)?.toUtc()
          : null,
      contextLength: context is num ? context.toInt() : null,
    );
  }

  final String id;

  /// Prices as reported (strings in USD per token / request / unit), or
  /// null when the entry had no pricing.
  final Map<String, Object?>? pricing;
  final bool hasPricingOverrides;
  final Set<String> supportedParameters;
  final List<String>? outputModalities;
  final DateTime? expirationDate;
  final int? contextLength;

  StructuredOutputMode get bestOutputMode =>
      supportedParameters.contains('structured_outputs')
      ? StructuredOutputMode.jsonSchema
      : supportedParameters.contains('response_format')
      ? StructuredOutputMode.jsonObject
      : StructuredOutputMode.promptOnly;
}

/// The zero-cost rules. A model counts as free only when *everything*
/// below holds; anything missing, unparseable or unexpected means "not
/// verified", and unverified models are never used in free-only mode.
abstract final class FreeModelPolicy {
  static const routerModel = AppConfig.aiFreeRouterModel;

  /// Whether [model] is verifiably free at [nowUtc]:
  /// - its id is a `:free` variant (or the free router itself) — zero token
  ///   prices alone are not enough: some paid media models list "0" token
  ///   prices and charge per output instead;
  /// - it lists prompt and completion prices, and every listed price is
  ///   exactly zero;
  /// - it has no conditional price overrides;
  /// - it produces text and has not expired.
  static bool isVerifiedFree(OpenRouterModelInfo model, DateTime nowUtc) {
    if (!model.id.endsWith(':free') && model.id != routerModel) return false;
    final pricing = model.pricing;
    if (pricing == null ||
        !pricing.containsKey('prompt') ||
        !pricing.containsKey('completion') ||
        model.hasPricingOverrides) {
      return false;
    }
    for (final value in pricing.values) {
      if (!_isZero(value)) return false;
    }
    if (model.outputModalities case final outputs?
        when !outputs.contains('text')) {
      return false;
    }
    if (model.expirationDate case final expires?
        when !expires.isAfter(nowUtc)) {
      return false;
    }
    return true;
  }

  /// Exactly zero. Null, negative or unparseable prices are not "free".
  static bool _isZero(Object? value) => switch (value) {
    num() => value == 0,
    String() => double.tryParse(value.trim()) == 0,
    _ => false,
  };

  /// Whether a model id reported in a response is recognisably free: a
  /// `:free` variant, the free router, or one of [verifiedIds].
  static bool isFreeModelId(String id, {Set<String> verifiedIds = const {}}) =>
      id.endsWith(':free') || id == routerModel || verifiedIds.contains(id);
}

/// Configurable quality scores for Quality Free mode. Higher is better.
///
/// Scores are matched by the longest id prefix; models matching
/// [excluded] are never chosen (not suited to dictionary work). The
/// defaults reflect OpenRouter's free list of October 2026 and are a
/// heuristic: adjust them as the free catalogue changes.
@immutable
class FreeModelQuality {
  const FreeModelQuality({
    this.scores = defaultScores,
    this.defaultScore = 50,
    this.excluded = defaultExcluded,
    this.structuredOutputBonus = 15,
    this.jsonModeBonus = 5,
  });

  static const defaultScores = {
    'google/gemma-4-31b': 86,
    'google/gemma-4': 80,
    'nvidia/nemotron-3-ultra': 84,
    'nvidia/nemotron-3.5-super': 82,
    'nvidia/nemotron-3-super': 80,
    'minimax/': 78,
    'thinkingmachines/inkling-small': 60,
    'thinkingmachines/inkling': 76,
    'xingchen-agi/': 60,
    'nvidia/nemotron-3.5-lightning': 55,
    'nvidia/nemotron-3-nano': 45,
    'liquid/': 25,
  };

  static const defaultExcluded = [
    'content-safety',
    'guard',
    'code',
    'lyria',
    'embed',
    'ocr',
  ];

  final Map<String, int> scores;
  final int defaultScore;
  final List<String> excluded;
  final int structuredOutputBonus;
  final int jsonModeBonus;

  bool isExcluded(String id) => excluded.any(id.contains);

  int scoreOf(OpenRouterModelInfo model) {
    var best = -1;
    var score = defaultScore;
    for (final MapEntry(:key, :value) in scores.entries) {
      if (model.id.startsWith(key) && key.length > best) {
        best = key.length;
        score = value;
      }
    }
    return score +
        switch (model.bestOutputMode) {
          StructuredOutputMode.jsonSchema => structuredOutputBonus,
          StructuredOutputMode.jsonObject => jsonModeBonus,
          StructuredOutputMode.promptOnly => 0,
        };
  }

  /// Verified free, non-excluded models from [models], best first. The
  /// free router itself is not included.
  List<OpenRouterModelInfo> rank(
    Iterable<OpenRouterModelInfo> models,
    DateTime nowUtc,
  ) {
    final ranked = [
      for (final m in models)
        if (m.id != FreeModelPolicy.routerModel &&
            !isExcluded(m.id) &&
            FreeModelPolicy.isVerifiedFree(m, nowUtc))
          m,
    ];
    ranked.sort((a, b) {
      final byScore = scoreOf(b).compareTo(scoreOf(a));
      return byScore != 0 ? byScore : a.id.compareTo(b.id);
    });
    return ranked;
  }
}

/// One way to send a request: the model and how JSON is asked for.
@immutable
class ModelAttempt {
  const ModelAttempt(this.model, this.outputMode);

  final String model;
  final StructuredOutputMode outputMode;

  @override
  bool operator ==(Object other) =>
      other is ModelAttempt &&
      other.model == model &&
      other.outputMode == outputMode;

  @override
  int get hashCode => Object.hash(model, outputMode);

  @override
  String toString() => 'ModelAttempt($model, ${outputMode.name})';
}

/// The models to try, in order, for one request. Fallback moves to the
/// next attempt only for failures where another model may help; every
/// attempt in free-only mode is free.
///
/// - Paid (free-only off): the user's chosen model only, as before.
/// - Auto Free: the free router with a schema, then without one (some free
///   models cannot do structured outputs).
/// - Quality Free: the top [qualityCandidates] ranked models, then the
///   free router. Without a verified list it behaves like Auto Free.
List<ModelAttempt> planAttempts({
  required bool freeOnly,
  required FreeRoutingMode mode,
  required String paidModel,
  List<OpenRouterModelInfo> rankedFree = const [],
  int qualityCandidates = 2,
}) {
  if (!freeOnly) {
    return [ModelAttempt(paidModel, StructuredOutputMode.jsonSchema)];
  }
  const router = [
    ModelAttempt(FreeModelPolicy.routerModel, StructuredOutputMode.jsonSchema),
    ModelAttempt(FreeModelPolicy.routerModel, StructuredOutputMode.promptOnly),
  ];
  if (mode == FreeRoutingMode.autoFree || rankedFree.isEmpty) return router;
  return [
    for (final m in rankedFree.take(qualityCandidates))
      ModelAttempt(m.id, m.bestOutputMode),
    router.first,
  ];
}
