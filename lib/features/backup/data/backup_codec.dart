import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/text_normalizer.dart';
import '../../../data/database/app_database.dart';
import '../../card_appearance/domain/card_appearance.dart';
import '../../review/domain/flashcard.dart';
import '../../review/domain/review_event.dart';
import '../../sentence_practice/domain/sentence_practice.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';

/// Every learning record of the database, as stored. Settings are not part
/// of it: the AI key lives in OS secure storage and is never here, and
/// `app_settings` (AI preferences and usage, the result cache, reminders,
/// review direction) is device configuration, not learning data.
@immutable
class BackupSnapshot {
  const BackupSnapshot({
    this.decks = const [],
    this.entries = const [],
    this.meanings = const [],
    this.flashcards = const [],
    this.tags = const [],
    this.entryTags = const [],
    this.reviewEvents = const [],
    this.sentencePractice = const [],
    this.cardAppearances = const [],
  });

  final List<DeckRow> decks;

  /// `search_key` is derived and recomputed on restore.
  final List<VocabularyEntryRow> entries;
  final List<VocabularyMeaningRow> meanings;

  /// FSRS scheduling state, exactly as stored.
  final List<FlashcardRow> flashcards;
  final List<TagRow> tags;
  final List<EntryTagRow> entryTags;
  final List<ReviewEventRow> reviewEvents;
  final List<SentencePracticeEventRow> sentencePractice;

  /// Card appearance per word (schema v4; absent in older files).
  final List<CardAppearanceRow> cardAppearances;

  BackupCounts get counts => BackupCounts(
    decks: decks.length,
    entries: entries.length,
    meanings: meanings.length,
    flashcards: flashcards.length,
    tags: tags.length,
    entryTags: entryTags.length,
    reviewEvents: reviewEvents.length,
    sentencePractice: sentencePractice.length,
    cardAppearances: cardAppearances.length,
  );
}

@immutable
class BackupCounts {
  const BackupCounts({
    required this.decks,
    required this.entries,
    required this.meanings,
    required this.flashcards,
    required this.tags,
    required this.entryTags,
    required this.reviewEvents,
    required this.sentencePractice,
    this.cardAppearances = 0,
  });

  final int decks;
  final int entries;
  final int meanings;
  final int flashcards;
  final int tags;
  final int entryTags;
  final int reviewEvents;
  final int sentencePractice;
  final int cardAppearances;

  Map<String, int> toJson() => {
    'decks': decks,
    'entries': entries,
    'meanings': meanings,
    'flashcards': flashcards,
    'tags': tags,
    'entryTags': entryTags,
    'reviewEvents': reviewEvents,
    'sentencePractice': sentencePractice,
    'cardAppearances': cardAppearances,
  };

  @override
  bool operator ==(Object other) =>
      other is BackupCounts && mapEquals(other.toJson(), toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

/// What a backup file says about itself.
@immutable
class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.counts,
    this.appVersion,
    this.appBuild,
  });

  final int formatVersion;

  /// Database schema version of the app that wrote the file.
  final int schemaVersion;

  /// UTC.
  final DateTime exportedAt;
  final BackupCounts counts;
  final String? appVersion;
  final String? appBuild;
}

/// A backup file that passed every check. Nothing has been written yet.
@immutable
class ValidatedBackup {
  const ValidatedBackup(this.manifest, this.snapshot);

  final BackupManifest manifest;
  final BackupSnapshot snapshot;
}

/// The AI WortBox backup file: UTF-8 JSON with a manifest, a SHA-256
/// checksum of the data and one list per table. See docs/backup-format.md.
abstract final class BackupCodec {
  /// Identifies the file type.
  static const formatName = 'ai-wortbox-backup';

  /// Current (and highest readable) format version. Independent of the
  /// database schema version, which the file records separately.
  static const formatVersion = 1;

  static Uint8List encode(
    BackupSnapshot snapshot, {
    required DateTime exportedAt,
    required int schemaVersion,
    String? appVersion,
    String? appBuild,
  }) {
    final data = <String, Object?>{
      'decks': [for (final d in snapshot.decks) _deck(d)],
      'entries': [for (final e in snapshot.entries) _entry(e)],
      'meanings': [for (final m in snapshot.meanings) _meaning(m)],
      'flashcards': [for (final c in snapshot.flashcards) _card(c)],
      'tags': [for (final t in snapshot.tags) _tag(t)],
      'entryTags': [for (final t in snapshot.entryTags) _entryTag(t)],
      'reviewEvents': [for (final r in snapshot.reviewEvents) _review(r)],
      'sentencePractice': [
        for (final s in snapshot.sentencePractice) _practice(s),
      ],
      'cardAppearances': [
        for (final a in snapshot.cardAppearances) _appearance(a),
      ],
    };
    final file = {
      'format': formatName,
      'formatVersion': formatVersion,
      'exportedAt': _date(exportedAt),
      'app': {'version': appVersion, 'build': appBuild},
      'schemaVersion': schemaVersion,
      'counts': snapshot.counts.toJson(),
      'checksum': {'algorithm': 'sha256', 'value': _checksum(data)},
      'data': data,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(file)));
  }

  /// Parses and fully validates [bytes]. Throws [BackupException] for any
  /// problem; a returned backup is internally consistent (unique ids, all
  /// references resolved, valid values) and safe to restore.
  static ValidatedBackup decode(Uint8List bytes, {required int schemaVersion}) {
    if (bytes.length > AppConfig.maxBackupBytes) {
      throw const BackupException(BackupError.tooLarge);
    }
    Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupException(BackupError.notBackup);
    }
    if (json is! Map || json['format'] != formatName) {
      throw const BackupException(BackupError.notBackup);
    }
    final root = _Reader(json.cast<String, Object?>(), '');
    final version = root.integer('formatVersion');
    if (version < 1 || version > formatVersion) {
      throw const BackupException(
        BackupError.unsupportedVersion,
        location: 'formatVersion',
      );
    }
    final fileSchema = root.integer('schemaVersion');
    if (fileSchema > schemaVersion) {
      throw const BackupException(
        BackupError.newerSchema,
        location: 'schemaVersion',
      );
    }
    final data = root.map('data');
    final checksum = root.map('checksum');
    if (checksum.string('algorithm') != 'sha256') {
      throw const BackupException(
        BackupError.unsupportedVersion,
        location: 'checksum.algorithm',
      );
    }
    if (checksum.string('value') != _checksum(data.json)) {
      throw const BackupException(BackupError.corrupted);
    }

    final snapshot = _Validator(data).run();
    final counts = root.map('counts');
    final expected = snapshot.counts.toJson();
    for (final MapEntry(:key, :value) in expected.entries) {
      // Lists added in later schema versions are absent (with their count)
      // from older files.
      if (value == 0 && counts.json[key] == null) continue;
      if (counts.integer(key) != value) {
        throw BackupException(
          BackupError.invalidValue,
          location: 'counts.$key',
        );
      }
    }
    final app = root.json['app'] is Map ? root.map('app') : null;
    return ValidatedBackup(
      BackupManifest(
        formatVersion: version,
        schemaVersion: fileSchema,
        exportedAt: root.date('exportedAt'),
        counts: snapshot.counts,
        appVersion: app?.optString('version'),
        appBuild: app?.optString('build'),
      ),
      snapshot,
    );
  }

  static String _checksum(Map<String, Object?> data) =>
      sha256.convert(utf8.encode(jsonEncode(data))).toString();

  static String _date(DateTime value) => value.toUtc().toIso8601String();

  static String? _optDate(DateTime? value) =>
      value == null ? null : _date(value);

  static Map<String, Object?> _deck(DeckRow d) => {
    'id': d.id,
    'name': d.name,
    'sourceLanguage': d.sourceLanguage,
    'definitionLanguage': d.definitionLanguage,
    'dailyNewCardLimit': d.dailyNewCardLimit,
    'createdAt': _date(d.createdAt),
    'updatedAt': _date(d.updatedAt),
  };

  static Map<String, Object?> _entry(VocabularyEntryRow e) => {
    'id': e.id,
    'deckId': e.deckId,
    'original': e.original,
    'normalized': e.normalized,
    'lemma': e.lemma,
    'sourceLanguage': e.sourceLanguage,
    'definitionLanguage': e.definitionLanguage,
    'partOfSpeech': e.partOfSpeech,
    'exampleSentence': e.exampleSentence,
    'exampleTranslation': e.exampleTranslation,
    'grammarInfo': e.grammarInfo,
    'notes': e.notes,
    'sourceContext': e.sourceContext,
    'sourceType': e.sourceType.name,
    'enrichmentStatus': e.enrichmentStatus.name,
    'enrichmentMetadata': e.enrichmentMetadata,
    'userEditedAt': _optDate(e.userEditedAt),
    'markedDifficultAt': _optDate(e.markedDifficultAt),
    'createdAt': _date(e.createdAt),
    'updatedAt': _date(e.updatedAt),
  };

  static Map<String, Object?> _meaning(VocabularyMeaningRow m) => {
    'id': m.id,
    'entryId': m.entryId,
    'position': m.position,
    'meaning': m.meaning,
    'explanation': m.explanation,
  };

  static Map<String, Object?> _card(FlashcardRow c) => {
    'id': c.id,
    'entryId': c.entryId,
    'direction': c.direction.name,
    'state': c.state.name,
    'step': c.step,
    'stability': c.stability,
    'difficulty': c.difficulty,
    'due': _date(c.due),
    'lastReviewedAt': _optDate(c.lastReviewedAt),
    'reviewCount': c.reviewCount,
    'lapseCount': c.lapseCount,
    'schedulerVersion': c.schedulerVersion,
    'createdAt': _date(c.createdAt),
    'updatedAt': _date(c.updatedAt),
  };

  static Map<String, Object?> _tag(TagRow t) => {
    'id': t.id,
    'name': t.name,
    'createdAt': _date(t.createdAt),
    'updatedAt': _date(t.updatedAt),
  };

  static Map<String, Object?> _entryTag(EntryTagRow t) => {
    'entryId': t.entryId,
    'tagId': t.tagId,
    'createdAt': _date(t.createdAt),
  };

  static Map<String, Object?> _review(ReviewEventRow r) => {
    'id': r.id,
    'entryId': r.entryId,
    'sessionId': r.sessionId,
    'direction': r.direction.name,
    'outcome': r.outcome.name,
    'reviewedAt': _date(r.reviewedAt),
    'localDay': r.localDay,
  };

  static Map<String, Object?> _appearance(CardAppearanceRow a) => {
    'entryId': a.entryId,
    'background': a.background,
    'ink': a.ink,
    'wordScale': a.wordScale,
    'meaningScale': a.meaningScale,
    'highlightColor': a.highlightColor,
    'highlights': a.highlights,
    'sticker': a.sticker,
    'updatedAt': _date(a.updatedAt),
  };

  static Map<String, Object?> _practice(SentencePracticeEventRow s) => {
    'id': s.id,
    'entryId': s.entryId,
    'direction': s.direction.name,
    'level': s.level.name,
    'outcome': s.outcome.name,
    'practicedAt': _date(s.practicedAt),
  };
}

/// Reads typed values from one JSON object; every failure names its
/// location (`entries[3].deckId`).
class _Reader {
  _Reader(this.json, this.path);

  final Map<String, Object?> json;
  final String path;

  String _at(String key) => path.isEmpty ? key : '$path.$key';

  Never _missing(String key) =>
      throw BackupException(BackupError.missingField, location: _at(key));

  Never _invalid(String key) =>
      throw BackupException(BackupError.invalidValue, location: _at(key));

  Object _required(String key) => json[key] ?? _missing(key);

  _Reader map(String key) => switch (_required(key)) {
    final Map<Object?, Object?> m => _Reader(m.cast(), _at(key)),
    _ => _invalid(key),
  };

  List<_Reader> list(String key) {
    // Optional lists: a table absent from the file is empty.
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) _invalid(key);
    return [
      for (final (i, item) in value.indexed)
        if (item is Map)
          _Reader(item.cast(), '${_at(key)}[$i]')
        else
          throw BackupException(
            BackupError.invalidValue,
            location: '${_at(key)}[$i]',
          ),
    ];
  }

  String string(String key, {int min = 1, int? max}) {
    final value = _required(key);
    if (value is! String) _invalid(key);
    final length = value.characters;
    if (length < min || (max != null && length > max)) _invalid(key);
    return value;
  }

  String? optString(String key, {int? max}) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) _invalid(key);
    if (max != null && value.characters > max) _invalid(key);
    return value;
  }

  int integer(String key, {int? min, int? max}) {
    final value = _required(key);
    if (value is! int) _invalid(key);
    if ((min != null && value < min) || (max != null && value > max)) {
      _invalid(key);
    }
    return value;
  }

  int? optInteger(String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! int) _invalid(key);
    return value;
  }

  double? optDouble(String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num || !value.isFinite) _invalid(key);
    return value.toDouble();
  }

  DateTime date(String key) {
    final value = _required(key);
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null || !parsed.isUtc) _invalid(key);
    return parsed;
  }

  DateTime? optDate(String key) => json[key] == null ? null : date(key);

  T enumValue<T extends Enum>(String key, List<T> values) {
    final name = string(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    _invalid(key);
  }
}

extension on String {
  /// Length in Unicode code points, like SQLite's `length()` used by the
  /// table's CHECK constraints.
  int get characters => runes.length;
}

/// Checks a backup's data section completely before anything is written.
class _Validator {
  _Validator(this.data);

  final _Reader data;

  void _unique(Set<Object> seen, Object key, String location) {
    if (!seen.add(key)) {
      throw BackupException(BackupError.duplicateId, location: location);
    }
  }

  void _exists(Set<String> ids, String? id, String location) {
    if (id != null && !ids.contains(id)) {
      throw BackupException(BackupError.brokenReference, location: location);
    }
  }

  /// A JSON list of `{"f": "word"|"meaning", "t": text}`.
  static bool _validHighlights(String json) {
    try {
      final list = jsonDecode(json);
      return list is List &&
          list.every(
            (h) =>
                h is Map &&
                HighlightField.values.any((f) => f.name == h['f']) &&
                h['t'] is String &&
                (h['t'] as String).trim().isNotEmpty,
          );
    } on FormatException {
      return false;
    }
  }

  /// `YYYY-MM-DD` naming a real calendar day.
  static bool _isCalendarDay(String value) {
    try {
      final day = LocalDay.parse(value);
      final utc = DateTime.utc(day.year, day.month, day.day);
      return utc.year == day.year &&
          utc.month == day.month &&
          utc.day == day.day;
    } on FormatException {
      return false;
    }
  }

  BackupSnapshot run() {
    final decks = <DeckRow>[];
    final deckIds = <String>{};
    final deckNames = <String>{};
    for (final r in data.list('decks')) {
      final row = DeckRow(
        id: r.string('id'),
        name: r.string('name', max: AppConfig.maxDeckNameLength),
        sourceLanguage: r.string('sourceLanguage', min: 2, max: 16),
        definitionLanguage: r.string('definitionLanguage', min: 2, max: 16),
        dailyNewCardLimit: r.integer(
          'dailyNewCardLimit',
          min: AppConfig.minDailyNewCardLimit,
          max: AppConfig.maxDailyNewCardLimit,
        ),
        createdAt: r.date('createdAt'),
        updatedAt: r.date('updatedAt'),
      );
      _unique(deckIds, row.id, '${r.path}.id');
      _unique(deckNames, TextNormalizer.nameKey(row.name), '${r.path}.name');
      decks.add(row);
    }

    final entries = <VocabularyEntryRow>[];
    final entryIds = <String>{};
    for (final r in data.list('entries')) {
      final metadata = r.optString('enrichmentMetadata');
      if (metadata != null) {
        try {
          EnrichmentMetadata.fromJson(
            (jsonDecode(metadata) as Map).cast<String, Object?>(),
          );
        } on Object {
          throw BackupException(
            BackupError.invalidValue,
            location: '${r.path}.enrichmentMetadata',
          );
        }
      }
      final row = VocabularyEntryRow(
        id: r.string('id'),
        deckId: r.string('deckId'),
        original: r.string('original'),
        normalized: r.string('normalized', min: 0),
        lemma: r.optString('lemma'),
        sourceLanguage: r.string('sourceLanguage', min: 2, max: 16),
        definitionLanguage: r.string('definitionLanguage', min: 2, max: 16),
        partOfSpeech: r.optString('partOfSpeech'),
        exampleSentence: r.optString('exampleSentence'),
        exampleTranslation: r.optString('exampleTranslation'),
        grammarInfo: r.optString('grammarInfo'),
        notes: r.optString('notes'),
        sourceContext: r.optString('sourceContext'),
        sourceType: r.enumValue('sourceType', VocabularySourceType.values),
        enrichmentStatus: r.enumValue(
          'enrichmentStatus',
          EnrichmentStatus.values,
        ),
        enrichmentMetadata: metadata,
        userEditedAt: r.optDate('userEditedAt'),
        createdAt: r.date('createdAt'),
        updatedAt: r.date('updatedAt'),
        markedDifficultAt: r.optDate('markedDifficultAt'),
        // Derived; recomputed when restored.
        searchKey: '',
      );
      _unique(entryIds, row.id, '${r.path}.id');
      _exists(deckIds, row.deckId, '${r.path}.deckId');
      entries.add(row);
    }

    final meanings = <VocabularyMeaningRow>[];
    final meaningIds = <String>{};
    final meaningPositions = <Object>{};
    for (final r in data.list('meanings')) {
      final row = VocabularyMeaningRow(
        id: r.string('id'),
        entryId: r.string('entryId'),
        position: r.integer('position', min: 0),
        meaning: r.string('meaning'),
        explanation: r.optString('explanation'),
      );
      _unique(meaningIds, row.id, '${r.path}.id');
      _exists(entryIds, row.entryId, '${r.path}.entryId');
      _unique(meaningPositions, (
        row.entryId,
        row.position,
      ), '${r.path}.position');
      meanings.add(row);
    }

    final cards = <FlashcardRow>[];
    final cardIds = <String>{};
    final cardDirections = <Object>{};
    for (final r in data.list('flashcards')) {
      final row = FlashcardRow(
        id: r.string('id'),
        entryId: r.string('entryId'),
        direction: r.enumValue('direction', CardDirection.values),
        state: r.enumValue('state', CardState.values),
        step: r.optInteger('step'),
        stability: r.optDouble('stability'),
        difficulty: r.optDouble('difficulty'),
        due: r.date('due'),
        lastReviewedAt: r.optDate('lastReviewedAt'),
        reviewCount: r.integer('reviewCount', min: 0),
        lapseCount: r.integer('lapseCount', min: 0),
        schedulerVersion: r.optString('schedulerVersion'),
        createdAt: r.date('createdAt'),
        updatedAt: r.date('updatedAt'),
      );
      _unique(cardIds, row.id, '${r.path}.id');
      _exists(entryIds, row.entryId, '${r.path}.entryId');
      _unique(cardDirections, (
        row.entryId,
        row.direction,
      ), '${r.path}.direction');
      cards.add(row);
    }

    final tags = <TagRow>[];
    final tagIds = <String>{};
    final tagKeys = <String>{};
    for (final r in data.list('tags')) {
      final name = r.string('name', max: AppConfig.maxTagNameLength);
      final row = TagRow(
        id: r.string('id'),
        name: name,
        nameKey: TextNormalizer.nameKey(name),
        createdAt: r.date('createdAt'),
        updatedAt: r.date('updatedAt'),
      );
      _unique(tagIds, row.id, '${r.path}.id');
      _unique(tagKeys, row.nameKey, '${r.path}.name');
      tags.add(row);
    }

    final entryTags = <EntryTagRow>[];
    final pairs = <Object>{};
    for (final r in data.list('entryTags')) {
      final row = EntryTagRow(
        entryId: r.string('entryId'),
        tagId: r.string('tagId'),
        createdAt: r.date('createdAt'),
      );
      _exists(entryIds, row.entryId, '${r.path}.entryId');
      _exists(tagIds, row.tagId, '${r.path}.tagId');
      _unique(pairs, (row.entryId, row.tagId), r.path);
      entryTags.add(row);
    }

    final reviews = <ReviewEventRow>[];
    final reviewIds = <String>{};
    for (final r in data.list('reviewEvents')) {
      final localDay = r.string('localDay', min: 10, max: 10);
      if (!_isCalendarDay(localDay)) {
        throw BackupException(
          BackupError.invalidValue,
          location: '${r.path}.localDay',
        );
      }
      final row = ReviewEventRow(
        id: r.string('id'),
        // Null when the word was deleted; the history is kept.
        entryId: r.optString('entryId'),
        sessionId: r.string('sessionId'),
        direction: r.enumValue('direction', CardDirection.values),
        outcome: r.enumValue('outcome', ReviewOutcome.values),
        reviewedAt: r.date('reviewedAt'),
        localDay: localDay,
      );
      _unique(reviewIds, row.id, '${r.path}.id');
      _exists(entryIds, row.entryId, '${r.path}.entryId');
      reviews.add(row);
    }

    final practice = <SentencePracticeEventRow>[];
    final practiceIds = <String>{};
    for (final r in data.list('sentencePractice')) {
      final row = SentencePracticeEventRow(
        id: r.string('id'),
        entryId: r.string('entryId'),
        direction: r.enumValue('direction', SentencePracticeDirection.values),
        level: r.enumValue('level', SentenceLevel.values),
        outcome: r.enumValue('outcome', SentencePracticeOutcome.values),
        practicedAt: r.date('practicedAt'),
      );
      _unique(practiceIds, row.id, '${r.path}.id');
      _exists(entryIds, row.entryId, '${r.path}.entryId');
      practice.add(row);
    }

    final appearances = <CardAppearanceRow>[];
    final styled = <String>{};
    for (final r in data.list('cardAppearances')) {
      String? choice<T extends Enum>(String key, List<T> values) {
        final name = r.optString(key);
        if (name != null && !values.any((v) => v.name == name)) {
          throw BackupException(
            BackupError.invalidValue,
            location: '${r.path}.$key',
          );
        }
        return name;
      }

      double scale(String key) {
        final value = r.optDouble(key) ?? 1;
        if (value < CardAppearance.minScale ||
            value > CardAppearance.maxScale) {
          throw BackupException(
            BackupError.invalidValue,
            location: '${r.path}.$key',
          );
        }
        return value;
      }

      final highlights = r.optString('highlights') ?? '[]';
      if (!_validHighlights(highlights)) {
        throw BackupException(
          BackupError.invalidValue,
          location: '${r.path}.highlights',
        );
      }
      final row = CardAppearanceRow(
        entryId: r.string('entryId'),
        background: choice('background', CardColor.values),
        ink: choice('ink', CardInk.values),
        wordScale: scale('wordScale'),
        meaningScale: scale('meaningScale'),
        highlightColor: choice('highlightColor', HighlightColor.values),
        highlights: highlights,
        sticker: choice('sticker', CardSticker.values),
        updatedAt: r.date('updatedAt'),
      );
      _exists(entryIds, row.entryId, '${r.path}.entryId');
      _unique(styled, row.entryId, '${r.path}.entryId');
      appearances.add(row);
    }

    return BackupSnapshot(
      cardAppearances: appearances,
      decks: decks,
      entries: entries,
      meanings: meanings,
      flashcards: cards,
      tags: tags,
      entryTags: entryTags,
      reviewEvents: reviews,
      sentencePractice: practice,
    );
  }
}
