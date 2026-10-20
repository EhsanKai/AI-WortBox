import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/text/text_normalizer.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../../about/domain/release_notes.dart';
import '../../vocabulary/domain/vocabulary_search.dart';
import 'backup_codec.dart';
import 'safety_backup_store.dart';

/// How a backup is restored.
enum RestoreMode {
  /// Adds what the device does not have yet. Nothing on the device is
  /// changed or deleted.
  merge,

  /// Deletes all learning data on the device and puts the backup's data in
  /// its place.
  replace,
}

/// What a restore did.
@immutable
class RestoreResult {
  const RestoreResult({
    required this.mode,
    this.decksAdded = 0,
    this.decksMatched = 0,
    this.entriesAdded = 0,
    this.entriesAlreadyPresent = 0,
    this.flashcardsAdded = 0,
    this.flashcardsKept = 0,
    this.tagsAdded = 0,
    this.reviewEventsAdded = 0,
    this.sentencePracticeAdded = 0,
  });

  final RestoreMode mode;
  final int decksAdded;

  /// Backup decks that already exist on the device (same id or name); their
  /// words were added to the existing deck.
  final int decksMatched;
  final int entriesAdded;

  /// Backup words already on the device (same id, or the same word with no
  /// new meaning in the same deck). The device's version is kept.
  final int entriesAlreadyPresent;
  final int flashcardsAdded;

  /// Backup scheduling states not used because the device already has the
  /// word: its own FSRS state is kept.
  final int flashcardsKept;
  final int tagsAdded;
  final int reviewEventsAdded;
  final int sentencePracticeAdded;
}

/// Creates and restores full backups of the learning data. Every restore
/// first saves the current data as a safety copy and then runs in one
/// transaction: it either completes or changes nothing.
class BackupService {
  BackupService(
    this._db, {
    required this._clock,
    required this._ids,
    required this._safety,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;
  final SafetyBackupStore _safety;

  /// Files above this size are validated on a background isolate.
  static const _isolateThreshold = 256 * 1024;

  /// The whole learning database as a backup file.
  Future<Uint8List> createBackup({InstalledVersion? app}) async {
    final snapshot = await _guard(
      'backup.read',
      () => _db.transaction(_snapshot),
    );
    return _encode(snapshot, app);
  }

  Uint8List _encode(BackupSnapshot snapshot, InstalledVersion? app) =>
      BackupCodec.encode(
        snapshot,
        exportedAt: _clock.nowUtc(),
        schemaVersion: _db.schemaVersion,
        appVersion: app?.version,
        appBuild: app?.buildNumber,
      );

  /// Validates [bytes] completely. Nothing is written.
  Future<ValidatedBackup> read(Uint8List bytes) async {
    final schema = _db.schemaVersion;
    if (bytes.length < _isolateThreshold) {
      return BackupCodec.decode(bytes, schemaVersion: schema);
    }
    return Isolate.run(() => BackupCodec.decode(bytes, schemaVersion: schema));
  }

  /// Numbers of the current data, for the restore preview.
  Future<BackupCounts> currentCounts() => _guard('backup.count', () async {
    Future<int> count(TableInfo<Table, Object?> table) async {
      final c = countAll();
      final row = await (_db.selectOnly(table)..addColumns([c])).getSingle();
      return row.read(c) ?? 0;
    }

    return BackupCounts(
      decks: await count(_db.decks),
      entries: await count(_db.vocabularyEntries),
      meanings: await count(_db.vocabularyMeanings),
      flashcards: await count(_db.flashcards),
      tags: await count(_db.tags),
      entryTags: await count(_db.entryTags),
      reviewEvents: await count(_db.reviewEvents),
      sentencePractice: await count(_db.sentencePracticeEvents),
    );
  });

  /// Restores [backup] with [mode]. Before anything changes, the current
  /// data is saved as a safety copy; if that fails, nothing is restored
  /// ([BackupError.safetyCopyFailed]). Any failure while writing rolls the
  /// whole restore back.
  Future<RestoreResult> restore(
    ValidatedBackup backup,
    RestoreMode mode, {
    InstalledVersion? app,
  }) async {
    try {
      return await _db.transaction(() async {
        final current = await _snapshot();
        try {
          await _safety.save(_encode(current, app), _clock.nowUtc());
        } on Object {
          throw const BackupException(BackupError.safetyCopyFailed);
        }
        return switch (mode) {
          RestoreMode.replace => _replace(backup.snapshot),
          RestoreMode.merge => _merge(backup.snapshot, current),
        };
      });
    } on AppException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw StorageException('backup.restore', error, stackTrace);
    }
  }

  Future<BackupSnapshot> _snapshot() async => BackupSnapshot(
    decks: await _db.select(_db.decks).get(),
    entries: await _db.select(_db.vocabularyEntries).get(),
    meanings: await _db.select(_db.vocabularyMeanings).get(),
    flashcards: await _db.select(_db.flashcards).get(),
    tags: await _db.select(_db.tags).get(),
    entryTags: await _db.select(_db.entryTags).get(),
    reviewEvents: await _db.select(_db.reviewEvents).get(),
    sentencePractice: await _db.select(_db.sentencePracticeEvents).get(),
  );

  Future<RestoreResult> _replace(BackupSnapshot s) async {
    // Children first; settings (app_settings) are not learning data and stay.
    await _db.delete(_db.entryTags).go();
    await _db.delete(_db.sentencePracticeEvents).go();
    await _db.delete(_db.reviewEvents).go();
    await _db.delete(_db.flashcards).go();
    await _db.delete(_db.vocabularyMeanings).go();
    await _db.delete(_db.vocabularyEntries).go();
    await _db.delete(_db.tags).go();
    await _db.delete(_db.decks).go();

    final meaningsByEntry = _meaningsByEntry(s.meanings);
    await _db.batch((b) {
      b
        ..insertAll(_db.decks, s.decks)
        ..insertAll(_db.vocabularyEntries, [
          for (final e in s.entries) _withSearchKey(e, meaningsByEntry[e.id]),
        ])
        ..insertAll(_db.vocabularyMeanings, s.meanings)
        ..insertAll(_db.flashcards, s.flashcards)
        ..insertAll(_db.tags, s.tags)
        ..insertAll(_db.entryTags, s.entryTags)
        ..insertAll(_db.reviewEvents, s.reviewEvents)
        ..insertAll(_db.sentencePracticeEvents, s.sentencePractice);
    });
    return RestoreResult(
      mode: RestoreMode.replace,
      decksAdded: s.decks.length,
      entriesAdded: s.entries.length,
      flashcardsAdded: s.flashcards.length,
      tagsAdded: s.tags.length,
      reviewEventsAdded: s.reviewEvents.length,
      sentencePracticeAdded: s.sentencePractice.length,
    );
  }

  /// Adds the backup's records that the device does not have. Records are
  /// matched by id; a deck also by name, a tag by name, and a word also by
  /// the existing duplicate rule (same word in the same deck with no new
  /// meaning). Existing records are never changed: a word already on the
  /// device keeps its content and its own FSRS state.
  Future<RestoreResult> _merge(BackupSnapshot s, BackupSnapshot local) async {
    final deckMap = <String, String>{};
    var decksAdded = 0;
    var decksMatched = 0;
    final localDeckIds = {for (final d in local.decks) d.id};
    final localDeckByName = {
      for (final d in local.decks) TextNormalizer.nameKey(d.name): d.id,
    };
    final newDecks = <DeckRow>[];
    for (final d in s.decks) {
      final match = localDeckIds.contains(d.id)
          ? d.id
          : localDeckByName[TextNormalizer.nameKey(d.name)];
      if (match != null) {
        deckMap[d.id] = match;
        decksMatched++;
      } else {
        deckMap[d.id] = d.id;
        newDecks.add(d);
        decksAdded++;
      }
    }

    final localMeanings = _meaningsByEntry(local.meanings);
    final backupMeanings = _meaningsByEntry(s.meanings);
    final localEntryIds = {for (final e in local.entries) e.id};
    final localByWord = <(String, String), List<String>>{};
    for (final e in local.entries) {
      localByWord.putIfAbsent((e.deckId, e.normalized), () => []).add(e.id);
    }
    Set<String> keys(Iterable<VocabularyMeaningRow>? rows) => {
      for (final m in rows ?? const <VocabularyMeaningRow>[])
        TextNormalizer.meaningKey(m.meaning),
    };

    final entryMap = <String, String>{};
    final added = <String>{};
    final newEntries = <VocabularyEntryRow>[];
    var alreadyPresent = 0;
    for (final e in s.entries) {
      final deckId = deckMap[e.deckId]!;
      if (localEntryIds.contains(e.id)) {
        entryMap[e.id] = e.id;
        alreadyPresent++;
        continue;
      }
      final wanted = keys(backupMeanings[e.id]);
      final redundant = localByWord[(deckId, e.normalized)]?.where(
        (id) => keys(localMeanings[id]).containsAll(wanted),
      );
      if (redundant != null && redundant.isNotEmpty) {
        entryMap[e.id] = redundant.first;
        alreadyPresent++;
        continue;
      }
      entryMap[e.id] = e.id;
      added.add(e.id);
      newEntries.add(
        _withSearchKey(e.copyWith(deckId: deckId), backupMeanings[e.id]),
      );
    }

    final localMeaningIds = {for (final m in local.meanings) m.id};
    final newMeanings = [
      for (final m in s.meanings)
        if (added.contains(m.entryId))
          localMeaningIds.contains(m.id) ? m.copyWith(id: _ids.newId()) : m,
    ];

    final localCardIds = {for (final c in local.flashcards) c.id};
    final newCards = <FlashcardRow>[];
    var cardsKept = 0;
    for (final c in s.flashcards) {
      if (!added.contains(c.entryId)) {
        cardsKept++;
        continue;
      }
      newCards.add(
        localCardIds.contains(c.id) ? c.copyWith(id: _ids.newId()) : c,
      );
    }

    final tagMap = <String, String>{};
    final localTagIds = {for (final t in local.tags) t.id};
    final localTagByKey = {for (final t in local.tags) t.nameKey: t.id};
    final newTags = <TagRow>[];
    for (final t in s.tags) {
      final match = localTagIds.contains(t.id)
          ? t.id
          : localTagByKey[t.nameKey];
      if (match != null) {
        tagMap[t.id] = match;
      } else {
        tagMap[t.id] = t.id;
        newTags.add(t);
      }
    }

    // Tag assignments are only added, also to existing words.
    final localPairs = {for (final p in local.entryTags) (p.entryId, p.tagId)};
    final newPairs = <EntryTagRow>[];
    for (final p in s.entryTags) {
      final pair = (entryMap[p.entryId]!, tagMap[p.tagId]!);
      if (localPairs.add(pair)) {
        newPairs.add(p.copyWith(entryId: pair.$1, tagId: pair.$2));
      }
    }

    final localReviewIds = {for (final r in local.reviewEvents) r.id};
    final newReviews = [
      for (final r in s.reviewEvents)
        if (!localReviewIds.contains(r.id))
          r.copyWith(
            entryId: Value(r.entryId == null ? null : entryMap[r.entryId]),
          ),
    ];

    final localPracticeIds = {for (final p in local.sentencePractice) p.id};
    final newPractice = [
      for (final p in s.sentencePractice)
        if (!localPracticeIds.contains(p.id))
          p.copyWith(entryId: entryMap[p.entryId]),
    ];

    await _db.batch((b) {
      b
        ..insertAll(_db.decks, newDecks)
        ..insertAll(_db.vocabularyEntries, newEntries)
        ..insertAll(_db.vocabularyMeanings, newMeanings)
        ..insertAll(_db.flashcards, newCards)
        ..insertAll(_db.tags, newTags)
        ..insertAll(_db.entryTags, newPairs)
        ..insertAll(_db.reviewEvents, newReviews)
        ..insertAll(_db.sentencePracticeEvents, newPractice);
    });
    return RestoreResult(
      mode: RestoreMode.merge,
      decksAdded: decksAdded,
      decksMatched: decksMatched,
      entriesAdded: newEntries.length,
      entriesAlreadyPresent: alreadyPresent,
      flashcardsAdded: newCards.length,
      flashcardsKept: cardsKept,
      tagsAdded: newTags.length,
      reviewEventsAdded: newReviews.length,
      sentencePracticeAdded: newPractice.length,
    );
  }

  static Map<String, List<VocabularyMeaningRow>> _meaningsByEntry(
    List<VocabularyMeaningRow> meanings,
  ) {
    final result = <String, List<VocabularyMeaningRow>>{};
    for (final m in meanings) {
      result.putIfAbsent(m.entryId, () => []).add(m);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.position.compareTo(b.position));
    }
    return result;
  }

  /// The search key is derived from the content (D34), so it is computed
  /// here rather than trusted from a file.
  static VocabularyEntryRow _withSearchKey(
    VocabularyEntryRow e,
    List<VocabularyMeaningRow>? meanings,
  ) => e.copyWith(
    searchKey: VocabularySearch.keyFor(
      original: e.original,
      lemma: e.lemma,
      meanings: [
        for (final m in meanings ?? const <VocabularyMeaningRow>[]) m.meaning,
      ],
    ),
  );

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}
