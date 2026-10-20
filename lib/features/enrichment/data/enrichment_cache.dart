import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/text_normalizer.dart';
import '../../../core/time/clock.dart';
import '../domain/enrichment.dart';
import '../domain/enrichment_parser.dart';
import 'ai_local_store.dart';

/// A validated result from the cache.
@immutable
class CachedEnrichment {
  const CachedEnrichment({
    required this.parsed,
    required this.model,
    required this.generatedAt,
  });

  final ParsedEnrichment parsed;
  final String model;
  final DateTime generatedAt;
}

/// Validated AI results, keyed by everything that was sent (word, sentence,
/// existing meanings, languages) and the prompt version. A word that was
/// already answered is never sent again while its result is cached: a
/// failed batch, a cancelled run or a closed app loses no completed work.
///
/// Stored in the local database next to other non-secret AI state.
/// Contains only vocabulary data, never keys.
class EnrichmentCache {
  EnrichmentCache(
    this._store, {
    required this._clock,
    this.ttl = AppConfig.aiCacheTtl,
    this.maxEntries = AppConfig.aiMaxCacheEntries,
  });

  final AiKeyValueStore _store;
  final Clock _clock;
  final Duration ttl;
  final int maxEntries;

  /// Bump when the prompt or validation changes in a way that makes old
  /// results unsuitable.
  static const version = 2;
  static const prefix = 'aicache.';

  static String keyFor(EnrichmentRequest r) {
    String exact(String s) =>
        TextNormalizer.collapseWhitespace(TextNormalizer.composeCharacters(s));
    final material = jsonEncode([
      version,
      r.sourceLanguage.code,
      r.definitionLanguage.code,
      // Case matters in German ("Essen" vs "essen").
      exact(r.original),
      exact(r.sourceContext ?? ''),
      [for (final m in r.existingMeanings) TextNormalizer.meaningKey(m)]
        ..sort(),
      // A meanings-only result must never answer a full request. Full keys
      // are unchanged, so existing cache entries stay valid.
      if (r.scope != EnrichmentScope.full) r.scope.name,
    ]);
    return '$prefix${sha256.convert(utf8.encode(material))}';
  }

  /// Cached results for [requests] (by index). Unreadable or expired
  /// entries count as misses. Storage failures are misses too: the cache
  /// only ever saves work.
  Future<Map<int, CachedEnrichment>> lookup(
    List<EnrichmentRequest> requests,
  ) async {
    final found = <int, CachedEnrichment>{};
    for (final (i, r) in requests.indexed) {
      try {
        final raw = await _store.read(keyFor(r));
        final entry = raw == null ? null : _decode(raw);
        if (entry != null) found[i] = entry;
      } on StorageException {
        // Treated as a miss.
      }
    }
    return found;
  }

  /// Stores validated results; then keeps the cache within [maxEntries].
  Future<void> store(
    List<({EnrichmentRequest request, ParsedEnrichment parsed, String model})>
    results,
  ) async {
    if (results.isEmpty) return;
    final now = _clock.nowUtc();
    try {
      await _store.writeAll({
        for (final r in results)
          keyFor(r.request): jsonEncode({
            'at': now.toIso8601String(),
            'model': r.model,
            'data': _encodeParsed(r.parsed),
          }),
      });
      await _evict();
    } on StorageException {
      // Not cached; the results are still returned to the user.
    }
  }

  Future<int> count() async => (await _store.readPrefix(prefix)).length;

  Future<void> clear() => _store.deletePrefix(prefix);

  Future<void> _evict() async {
    final all = await _store.readPrefix(prefix);
    if (all.length <= maxEntries) return;
    final dated = [
      for (final MapEntry(:key, :value) in all.entries) (key, _at(value)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    await _store.writeAll({
      for (final (key, _) in dated.take(all.length - maxEntries)) key: null,
    });
  }

  static DateTime _at(String raw) {
    try {
      final at = (jsonDecode(raw) as Map)['at'];
      return DateTime.tryParse(at as String) ?? DateTime.utc(1970);
    } on Object {
      return DateTime.utc(1970);
    }
  }

  CachedEnrichment? _decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final at = DateTime.parse(json['at']! as String).toUtc();
      if (_clock.nowUtc().difference(at) > ttl) return null;
      final data = json['data']! as Map<String, Object?>;
      final meanings = [
        for (final m in data['meanings']! as List)
          ProposedMeaning(
            (m as Map)['text']! as String,
            explanation: m['explanation'] as String?,
          ),
      ];
      if (meanings.isEmpty) return null;
      return CachedEnrichment(
        parsed: ParsedEnrichment(
          meanings: List.unmodifiable(meanings),
          partOfSpeech: data['partOfSpeech'] as String?,
          grammarInfo: data['grammarInfo'] as String?,
          lemma: data['lemma'] as String?,
          exampleSentence: data['exampleSentence'] as String?,
          exampleTranslation: data['exampleTranslation'] as String?,
          isAmbiguous: data['isAmbiguous'] == true,
        ),
        model: json['model']! as String,
        generatedAt: at,
      );
    } on Object {
      // Damaged entries are ignored and overwritten on the next success.
      return null;
    }
  }

  static Map<String, Object?> _encodeParsed(ParsedEnrichment p) => {
    'meanings': [
      for (final m in p.meanings)
        {'text': m.text, 'explanation': m.explanation},
    ],
    'partOfSpeech': p.partOfSpeech,
    'grammarInfo': p.grammarInfo,
    'lemma': p.lemma,
    'exampleSentence': p.exampleSentence,
    'exampleTranslation': p.exampleTranslation,
    'isAmbiguous': p.isAmbiguous,
  };
}
