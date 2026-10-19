import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../data/ai_local_store.dart';
import '../data/free_model_catalog.dart';
import '../data/request_scheduler.dart';
import '../domain/free_model_policy.dart';

/// What the "Free usage" section of the AI settings shows.
@immutable
class FreeUsageState {
  const FreeUsageState({
    required this.preferences,
    required this.usage,
    required this.cacheCount,
    required this.rate,
    this.catalog,
    this.refreshing = false,
    this.refreshFailed = false,
  });

  final AiPreferences preferences;
  final AiUsage usage;

  /// Saved AI results.
  final int cacheCount;
  final RateLimitStatus rate;

  /// The verified free list, when loaded and still fresh.
  final FreeCatalogSnapshot? catalog;
  final bool refreshing;
  final bool refreshFailed;

  /// The model the next request will start with.
  String plannedModel(String paidModel) {
    if (!preferences.freeOnly) return paidModel;
    final ranked = catalog?.ranked ?? const [];
    return preferences.mode == FreeRoutingMode.qualityFree && ranked.isNotEmpty
        ? ranked.first.id
        : FreeModelPolicy.routerModel;
  }

  /// Quality Free is selected but no verified list is available, so the
  /// free router is used.
  bool get qualityUnverified =>
      preferences.freeOnly &&
      preferences.mode == FreeRoutingMode.qualityFree &&
      (catalog?.ranked.isEmpty ?? true);

  FreeUsageState copyWith({
    AiPreferences? preferences,
    bool? refreshing,
    bool? refreshFailed,
  }) => FreeUsageState(
    preferences: preferences ?? this.preferences,
    usage: usage,
    cacheCount: cacheCount,
    rate: rate,
    catalog: catalog,
    refreshing: refreshing ?? this.refreshing,
    refreshFailed: refreshFailed ?? this.refreshFailed,
  );
}

class FreeUsageController extends AsyncNotifier<FreeUsageState> {
  @override
  Future<FreeUsageState> build() => _read();

  Future<FreeUsageState> _read({bool refreshFailed = false}) async {
    final local = ref.read(aiLocalStateProvider);
    return FreeUsageState(
      preferences: await local.readPreferences(),
      usage: await local.readUsage(),
      cacheCount: await ref.read(enrichmentCacheProvider).count(),
      rate: await ref.read(requestSchedulerProvider).status(),
      catalog: ref.read(freeModelCatalogProvider).current,
      refreshFailed: refreshFailed,
    );
  }

  FreeUsageState get _current => state.requireValue;

  /// Throws [StorageException] when the choice could not be saved; the
  /// previous choice stays in effect.
  Future<void> setFreeOnly(bool freeOnly) =>
      _save(_current.preferences.copyWith(freeOnly: freeOnly));

  Future<void> setMode(FreeRoutingMode mode) =>
      _save(_current.preferences.copyWith(mode: mode));

  Future<void> setWordsPerRequest(int words) =>
      _save(_current.preferences.copyWith(wordsPerRequest: words));

  Future<void> _save(AiPreferences preferences) async {
    await ref.read(aiLocalStateProvider).writePreferences(preferences);
    state = AsyncData(_current.copyWith(preferences: preferences));
  }

  /// Re-reads local figures (e.g. after an enrichment run).
  Future<void> reload() async {
    state = AsyncData(await _read());
  }

  /// Asks OpenRouter for the free requests left today (with the saved
  /// key, only to OpenRouter) and re-verifies the free model list.
  Future<void> refresh() async {
    state = AsyncData(
      _current.copyWith(refreshing: true, refreshFailed: false),
    );
    var failed = false;
    try {
      final key = (await ref.read(aiSettingsStoreProvider).readApiKey())
          ?.trim();
      if (key != null && key.isNotEmpty) {
        final info = await ref.read(openRouterClientProvider).keyInfo(key);
        await recordQuota(ref, info.freeDailyRemaining, info.freeDailyLimit);
      }
      if (_current.preferences.freeOnly) {
        await ref.read(freeModelCatalogProvider).load(refresh: true);
      }
    } on AppException {
      failed = true;
    }
    if (!ref.mounted) return;
    state = AsyncData(await _read(refreshFailed: failed));
  }

  /// Deletes all saved AI results and their statistics.
  Future<void> clearCache() async {
    await ref.read(enrichmentCacheProvider).clear();
    await ref.read(aiLocalStateProvider).resetCacheStats();
    state = AsyncData(await _read());
  }
}

/// Stores OpenRouter's report of the free requests left today, when it
/// reported one.
Future<void> recordQuota(Ref ref, int? remaining, int? limit) async {
  if (remaining == null) return;
  try {
    await ref
        .read(aiLocalStateProvider)
        .recordRemoteQuota(remaining: remaining, limit: limit);
  } on StorageException {
    // Informational only.
  }
}

final freeUsageControllerProvider =
    AsyncNotifierProvider<FreeUsageController, FreeUsageState>(
      FreeUsageController.new,
    );
