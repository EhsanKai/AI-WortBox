import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/free_model_policy.dart';

/// Non-secret AI state in the local database (`app_settings`): preferences,
/// free-usage counters, the result cache and unfinished jobs. Never holds
/// the API key, which stays in OS secure storage.
abstract interface class AiKeyValueStore {
  Future<String?> read(String key);

  /// All keys starting with [prefix].
  Future<Map<String, String>> readPrefix(String prefix);

  /// Writes all [values] in one transaction (null deletes a key).
  Future<void> writeAll(Map<String, String?> values);

  Future<void> deletePrefix(String prefix);
}

class DatabaseAiKeyValueStore implements AiKeyValueStore {
  DatabaseAiKeyValueStore(this._db);

  final AppDatabase _db;

  @override
  Future<String?> read(String key) => _guard('ai.read', () async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  });

  @override
  Future<Map<String, String>> readPrefix(String prefix) =>
      _guard('ai.readPrefix', () async {
        final rows = await (_db.select(
          _db.appSettings,
        )..where((s) => _prefix(s, prefix))).get();
        return {for (final r in rows) r.key: r.value};
      });

  @override
  Future<void> writeAll(Map<String, String?> values) => _guard('ai.write', () {
    return _db.transaction(() async {
      for (final MapEntry(:key, :value) in values.entries) {
        if (value == null) {
          await (_db.delete(
            _db.appSettings,
          )..where((s) => s.key.equals(key))).go();
        } else {
          await _db
              .into(_db.appSettings)
              .insertOnConflictUpdate(
                AppSettingsCompanion.insert(key: key, value: value),
              );
        }
      }
    });
  });

  @override
  Future<void> deletePrefix(String prefix) => _guard('ai.deletePrefix', () {
    return (_db.delete(_db.appSettings)..where((s) => _prefix(s, prefix))).go();
  });

  /// A range comparison instead of LIKE, so `_` and `%` in keys are literal.
  static Expression<bool> _prefix($AppSettingsTable s, String prefix) =>
      s.key.isBiggerOrEqualValue(prefix) &
      s.key.isSmallerThanValue('$prefix\u{10FFFF}');

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}

/// The user's AI choices. Free-only is on unless the user turns it off.
@immutable
class AiPreferences {
  const AiPreferences({
    this.freeOnly = true,
    this.mode = FreeRoutingMode.autoFree,
    this.wordsPerRequest = AppConfig.aiDefaultWordsPerRequest,
  });

  final bool freeOnly;
  final FreeRoutingMode mode;

  /// Words per request, 1 to [AppConfig.aiMaxWordsPerRequest].
  final int wordsPerRequest;

  AiPreferences copyWith({
    bool? freeOnly,
    FreeRoutingMode? mode,
    int? wordsPerRequest,
  }) => AiPreferences(
    freeOnly: freeOnly ?? this.freeOnly,
    mode: mode ?? this.mode,
    wordsPerRequest: wordsPerRequest ?? this.wordsPerRequest,
  );

  @override
  bool operator ==(Object other) =>
      other is AiPreferences &&
      other.freeOnly == freeOnly &&
      other.mode == mode &&
      other.wordsPerRequest == wordsPerRequest;

  @override
  int get hashCode => Object.hash(freeOnly, mode, wordsPerRequest);
}

/// Free-usage figures. Counts are what this app sent; the remaining
/// figure is only what OpenRouter last reported (`GET /key`).
@immutable
class AiUsage {
  const AiUsage({
    this.requestsToday = 0,
    this.pausedUntil,
    this.remoteRemaining,
    this.remoteLimit,
    this.remoteCheckedAt,
    this.requestsSinceCheck = 0,
    this.lastModelUsed,
    this.lastModelUsedAt,
    this.cacheHits = 0,
    this.cacheMisses = 0,
  });

  /// Requests sent by this app in the current UTC day.
  final int requestsToday;

  /// Free requests are paused (daily quota used up) until then, UTC.
  final DateTime? pausedUntil;

  /// Free-model requests left today and the daily limit, as reported by
  /// OpenRouter at [remoteCheckedAt]; null when never checked.
  final int? remoteRemaining;
  final int? remoteLimit;
  final DateTime? remoteCheckedAt;

  /// Requests this app sent after [remoteCheckedAt].
  final int requestsSinceCheck;

  /// The model that actually answered the last request.
  final String? lastModelUsed;
  final DateTime? lastModelUsedAt;

  final int cacheHits;
  final int cacheMisses;

  bool isPaused(DateTime nowUtc) =>
      pausedUntil != null && nowUtc.isBefore(pausedUntil!);

  /// [remoteRemaining] minus what this app sent since, while the report is
  /// from the current UTC day; null otherwise.
  int? estimatedRemaining(DateTime nowUtc) {
    final remaining = remoteRemaining;
    final checked = remoteCheckedAt;
    if (remaining == null || checked == null) return null;
    if (utcDay(checked) != utcDay(nowUtc)) return null;
    final left = remaining - requestsSinceCheck;
    return left < 0 ? 0 : left;
  }
}

/// `yyyy-mm-dd` of [utc]. OpenRouter resets free daily limits at 00:00 UTC.
String utcDay(DateTime utc) => utc.toUtc().toIso8601String().substring(0, 10);

/// The next 00:00 UTC after [utc].
DateTime nextUtcMidnight(DateTime utc) {
  final u = utc.toUtc();
  return DateTime.utc(u.year, u.month, u.day + 1);
}

/// Typed access to the AI state in [AiKeyValueStore].
class AiLocalState {
  AiLocalState(this.store, {required this.clock});

  final AiKeyValueStore store;
  final Clock clock;

  static const _freeOnly = 'ai.freeOnly';
  static const _mode = 'ai.routing';
  static const _words = 'ai.wordsPerRequest';
  static const _day = 'ai.usage.day';
  static const _requests = 'ai.usage.requests';
  static const _paused = 'ai.usage.pausedUntil';
  static const _remaining = 'ai.usage.remoteRemaining';
  static const _limit = 'ai.usage.remoteLimit';
  static const _checked = 'ai.usage.remoteCheckedAt';
  static const _sinceCheck = 'ai.usage.sinceCheck';
  static const _lastModel = 'ai.usage.lastModel';
  static const _lastModelAt = 'ai.usage.lastModelAt';
  static const _hits = 'ai.stats.cacheHits';
  static const _misses = 'ai.stats.cacheMisses';
  static const jobPrefix = 'ai.job.';

  Future<AiPreferences> readPreferences() async {
    final values = await store.readPrefix('ai.');
    final words = int.tryParse(values[_words] ?? '');
    return AiPreferences(
      // Anything but an explicit "false" keeps free-only on.
      freeOnly: values[_freeOnly] != 'false',
      mode:
          FreeRoutingMode.values
              .where((m) => m.name == values[_mode])
              .firstOrNull ??
          FreeRoutingMode.autoFree,
      wordsPerRequest: words == null
          ? AppConfig.aiDefaultWordsPerRequest
          : words.clamp(1, AppConfig.aiMaxWordsPerRequest),
    );
  }

  Future<void> writePreferences(AiPreferences p) => store.writeAll({
    _freeOnly: '${p.freeOnly}',
    _mode: p.mode.name,
    _words: '${p.wordsPerRequest.clamp(1, AppConfig.aiMaxWordsPerRequest)}',
  });

  Future<AiUsage> readUsage() async {
    final v = await store.readPrefix('ai.');
    DateTime? time(String key) =>
        v[key] == null ? null : DateTime.tryParse(v[key]!)?.toUtc();
    int count(String key) => int.tryParse(v[key] ?? '') ?? 0;
    final today = utcDay(clock.nowUtc());
    return AiUsage(
      requestsToday: v[_day] == today ? count(_requests) : 0,
      pausedUntil: time(_paused),
      remoteRemaining: int.tryParse(v[_remaining] ?? ''),
      remoteLimit: int.tryParse(v[_limit] ?? ''),
      remoteCheckedAt: time(_checked),
      requestsSinceCheck: count(_sinceCheck),
      lastModelUsed: v[_lastModel],
      lastModelUsedAt: time(_lastModelAt),
      cacheHits: count(_hits),
      cacheMisses: count(_misses),
    );
  }

  /// Counts one request sent to OpenRouter.
  Future<void> recordRequest() async {
    final v = await store.readPrefix('ai.usage.');
    final today = utcDay(clock.nowUtc());
    final count = v[_day] == today ? int.tryParse(v[_requests] ?? '') ?? 0 : 0;
    await store.writeAll({
      _day: today,
      _requests: '${count + 1}',
      _sinceCheck: '${(int.tryParse(v[_sinceCheck] ?? '') ?? 0) + 1}',
    });
  }

  Future<void> pauseUntil(DateTime? utc) =>
      store.writeAll({_paused: utc?.toUtc().toIso8601String()});

  /// Stores OpenRouter's report of the free daily requests. A report of
  /// none left pauses free requests until the next reset; a report of some
  /// left lifts a pause (e.g. after the user bought credits).
  Future<void> recordRemoteQuota({required int remaining, int? limit}) {
    final now = clock.nowUtc();
    return store.writeAll({
      _remaining: '$remaining',
      _limit: limit?.toString(),
      _checked: now.toIso8601String(),
      _sinceCheck: '0',
      _paused: remaining <= 0 ? nextUtcMidnight(now).toIso8601String() : null,
    });
  }

  Future<void> recordModelUsed(String model) => store.writeAll({
    _lastModel: model,
    _lastModelAt: clock.nowUtc().toIso8601String(),
  });

  Future<void> recordCacheLookups({
    required int hits,
    required int misses,
  }) async {
    if (hits == 0 && misses == 0) return;
    final v = await store.readPrefix('ai.stats.');
    await store.writeAll({
      _hits: '${(int.tryParse(v[_hits] ?? '') ?? 0) + hits}',
      _misses: '${(int.tryParse(v[_misses] ?? '') ?? 0) + misses}',
    });
  }

  Future<void> resetCacheStats() =>
      store.writeAll({_hits: null, _misses: null});

  /// Entry ids of the unfinished batch job for [deckId], if any.
  Future<List<String>?> readJob(String deckId) async {
    final raw = await store.read('$jobPrefix$deckId');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['entryIds'] is List) {
        return [
          for (final id in decoded['entryIds'] as List)
            if (id is String) id,
        ];
      }
    } on FormatException {
      // A damaged record is dropped below.
    }
    await clearJob(deckId);
    return null;
  }

  Future<void> writeJob(String deckId, List<String> entryIds) =>
      store.writeAll({
        '$jobPrefix$deckId': jsonEncode({
          'entryIds': entryIds,
          'createdAt': clock.nowUtc().toIso8601String(),
        }),
      });

  Future<void> clearJob(String deckId) =>
      store.writeAll({'$jobPrefix$deckId': null});
}
