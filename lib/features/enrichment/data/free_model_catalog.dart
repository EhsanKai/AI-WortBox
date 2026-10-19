import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/time/clock.dart';
import '../domain/free_model_policy.dart';
import 'openrouter_client.dart';

/// The verified free models at [fetchedAt], best first.
@immutable
class FreeCatalogSnapshot {
  const FreeCatalogSnapshot({
    required this.ranked,
    required this.routerListed,
    required this.fetchedAt,
  });

  /// Verified free models, ranked by [FreeModelQuality].
  final List<OpenRouterModelInfo> ranked;

  /// Whether the free router itself was listed and verified as free.
  final bool routerListed;
  final DateTime fetchedAt;

  Set<String> get verifiedIds => {for (final m in ranked) m.id};
}

/// Loads OpenRouter's public model list and keeps only models that pass
/// [FreeModelPolicy.isVerifiedFree]. A list is reused for [ttl]; when it
/// cannot be loaded or verified, [load] throws and callers fall back to
/// the free router (never to a paid model).
class FreeModelCatalog {
  FreeModelCatalog(
    this._client, {
    required this._clock,
    this.quality = const FreeModelQuality(),
    this.ttl = AppConfig.aiFreeCatalogTtl,
  });

  final OpenRouterClient _client;
  final Clock _clock;
  final FreeModelQuality quality;
  final Duration ttl;

  FreeCatalogSnapshot? _snapshot;

  /// The last verified list, if still fresh.
  FreeCatalogSnapshot? get current {
    final s = _snapshot;
    if (s == null || _clock.nowUtc().difference(s.fetchedAt) > ttl) {
      return null;
    }
    return s;
  }

  /// Throws [EnrichmentException] when the list cannot be loaded.
  Future<FreeCatalogSnapshot> load({bool refresh = false}) async {
    if (!refresh) {
      if (current case final fresh?) return fresh;
    }
    final now = _clock.nowUtc();
    final models = await _client.listModels();
    final router = models
        .where((m) => m.id == FreeModelPolicy.routerModel)
        .firstOrNull;
    return _snapshot = FreeCatalogSnapshot(
      ranked: List.unmodifiable(quality.rank(models, now)),
      routerListed:
          router != null && FreeModelPolicy.isVerifiedFree(router, now),
      fetchedAt: now,
    );
  }

  void invalidate() => _snapshot = null;
}
