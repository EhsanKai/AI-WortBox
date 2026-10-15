import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/language/language.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/duplicate_detection.dart';
import '../domain/vocabulary_draft.dart';
import '../domain/vocabulary_entry.dart';
import '../domain/vocabulary_repository.dart';

class DriftVocabularyRepository implements VocabularyRepository {
  DriftVocabularyRepository(
    this._db, {
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  $VocabularyEntriesTable get _entries => _db.vocabularyEntries;
  $VocabularyMeaningsTable get _meanings => _db.vocabularyMeanings;

  // ---------------------------------------------------------------------------
  // Queries

  JoinedSelectStatement<HasResultSet, dynamic> _entriesWithMeanings(
    Expression<bool> where,
  ) =>
      _db.select(_entries).join([
          leftOuterJoin(_meanings, _meanings.entryId.equalsExp(_entries.id)),
        ])
        ..where(where)
        ..orderBy([
          OrderingTerm.desc(_entries.createdAt),
          OrderingTerm.asc(_entries.normalized),
          OrderingTerm.asc(_entries.id),
          OrderingTerm.asc(_meanings.position),
        ]);

  List<VocabularyEntry> _group(List<TypedResult> rows) {
    final entries = <String, VocabularyEntryRow>{};
    final meanings = <String, List<VocabularyMeaning>>{};
    for (final row in rows) {
      final entry = row.readTable(_entries);
      entries.putIfAbsent(entry.id, () => entry);
      final list = meanings.putIfAbsent(entry.id, () => []);
      final meaning = row.readTableOrNull(_meanings);
      if (meaning != null) {
        list.add(
          VocabularyMeaning(meaning.meaning, explanation: meaning.explanation),
        );
      }
    }
    return [
      for (final entry in entries.values) _toDomain(entry, meanings[entry.id]!),
    ];
  }

  @override
  Stream<List<VocabularyEntry>> watchEntries(String deckId) =>
      _entriesWithMeanings(_entries.deckId.equals(deckId)).watch().map(_group);

  @override
  Stream<VocabularyEntry?> watchEntry(String id) =>
      _entriesWithMeanings(_entries.id.equals(id))
          .watch()
          .map((rows) => _group(rows).firstOrNull);

  @override
  Future<List<VocabularyEntry>> getEntries(String deckId) => _guard(
    'getEntries',
    () async => _group(
      await _entriesWithMeanings(_entries.deckId.equals(deckId)).get(),
    ),
  );

  @override
  Future<VocabularyEntry?> getEntry(String id) => _guard(
    'getEntry',
    () async =>
        _group(await _entriesWithMeanings(_entries.id.equals(id)).get())
            .firstOrNull,
  );

  @override
  Future<List<VocabularyEntry>> findByNormalized(
    String deckId,
    String normalized,
  ) => _guard(
    'findByNormalized',
    () async => _group(
      await _entriesWithMeanings(
        _entries.deckId.equals(deckId) & _entries.normalized.equals(normalized),
      ).get(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Writes

  @override
  Future<VocabularyEntry> createEntry(VocabularyDraft draft) async {
    final cleaned = _validated(draft);
    return _guard('createEntry', () {
      return _db.transaction(() async {
        final deck = await _requireDeck(cleaned.deckId);
        final now = _clock.nowUtc();
        final id = await _insert(deck, cleaned, now, userEdited: true);
        return (await getEntry(id))!;
      });
    });
  }

  @override
  Future<VocabularyEntry> updateEntry(String id, VocabularyDraft draft) async {
    final cleaned = _validated(draft);
    return _guard('updateEntry', () {
      return _db.transaction(() async {
        final existing = await _requireEntry(id);
        final deck = await _requireDeck(cleaned.deckId);
        await _writeContent(
          existing,
          deck,
          cleaned,
          _clock.nowUtc(),
          userEdited: true,
        );
        return (await getEntry(id))!;
      });
    });
  }

  @override
  Future<VocabularyEntry> mergeIntoEntry(
    String id,
    VocabularyDraft draft,
  ) async {
    final cleaned = _validated(draft);
    return _guard('mergeIntoEntry', () {
      return _db.transaction(() async {
        final existing = await _requireEntry(id);
        final deck = await _requireDeck(existing.deckId);
        final merged = mergeDrafts(
          VocabularyDraft.fromEntry(existing),
          cleaned,
        );
        _throwIfInvalid(merged);
        await _writeContent(
          existing,
          deck,
          merged,
          _clock.nowUtc(),
          userEdited: true,
        );
        return (await getEntry(id))!;
      });
    });
  }

  @override
  Future<void> deleteEntry(String id) => _guard('deleteEntry', () async {
    final deleted = await (_db.delete(
      _entries,
    )..where((e) => e.id.equals(id))).go();
    if (deleted == 0) throw NotFoundException('VocabularyEntry', id);
  });

  @override
  Future<ImportSummary> importEntries(
    String deckId,
    List<ImportCandidate> candidates,
    DuplicateStrategy strategy,
  ) async {
    final cleaned = [
      for (final c in candidates)
        ImportCandidate(
          rowNumber: c.rowNumber,
          draft: _validated(c.draft.copyWith(deckId: deckId)),
        ),
    ];
    return _guard('importEntries', () {
      return _db.transaction(() async {
        final deck = await _requireDeck(deckId);
        final existing = await getEntries(deckId);
        final decisions = planImport(cleaned, existing, strategy);

        final draftsByRow = {for (final c in cleaned) c.rowNumber: c.draft};
        // Rows to create, in row order, with later in-file merges folded in.
        final creates = <int, VocabularyDraft>{};
        // Existing entries receiving meanings, keyed by entry id.
        final entryMerges = <String, VocabularyDraft>{};
        final existingById = {for (final e in existing) e.id: e};

        for (final decision in decisions) {
          final draft = draftsByRow[decision.rowNumber]!;
          switch (decision) {
            case CreateDecision():
              creates[decision.rowNumber] = draft;
            case MergeIntoRowDecision(:final targetRowNumber):
              creates[targetRowNumber] = mergeDrafts(
                creates[targetRowNumber]!,
                draft,
              );
            case MergeIntoEntryDecision(:final entryId):
              entryMerges[entryId] = mergeDrafts(
                entryMerges[entryId] ??
                    VocabularyDraft.fromEntry(existingById[entryId]!),
                draft,
              );
            case SkipDecision():
              break;
          }
        }

        final now = _clock.nowUtc();
        for (final draft in creates.values) {
          _throwIfInvalid(draft);
          await _insert(deck, draft, now, userEdited: false);
        }
        for (final MapEntry(key: entryId, value: draft)
            in entryMerges.entries) {
          _throwIfInvalid(draft);
          await _writeContent(
            existingById[entryId]!,
            deck,
            draft,
            now,
            userEdited: false,
          );
        }
        return ImportSummary(decisions: decisions);
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers

  VocabularyDraft _validated(VocabularyDraft draft) {
    final cleaned = draft.cleaned();
    _throwIfInvalid(cleaned);
    return cleaned;
  }

  void _throwIfInvalid(VocabularyDraft draft) {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw VocabularyValidationException(errors);
  }

  Future<DeckRow> _requireDeck(String deckId) async {
    final deck = await (_db.select(
      _db.decks,
    )..where((d) => d.id.equals(deckId))).getSingleOrNull();
    if (deck == null) {
      throw const VocabularyValidationException({
        VocabularyValidationError.deckNotFound,
      });
    }
    return deck;
  }

  Future<VocabularyEntry> _requireEntry(String id) async {
    final entry = await getEntry(id);
    if (entry == null) throw NotFoundException('VocabularyEntry', id);
    return entry;
  }

  Future<String> _insert(
    DeckRow deck,
    VocabularyDraft draft,
    DateTime now, {
    required bool userEdited,
  }) async {
    final id = _ids.newId();
    await _db
        .into(_entries)
        .insert(
          VocabularyEntriesCompanion.insert(
            id: id,
            deckId: deck.id,
            original: draft.original,
            normalized: draft.normalized,
            lemma: Value(draft.lemma),
            sourceLanguage: deck.sourceLanguage,
            definitionLanguage: deck.definitionLanguage,
            partOfSpeech: Value(draft.partOfSpeech),
            exampleSentence: Value(draft.exampleSentence),
            exampleTranslation: Value(draft.exampleTranslation),
            grammarInfo: Value(draft.grammarInfo),
            notes: Value(draft.notes),
            sourceContext: Value(draft.sourceContext),
            sourceType: draft.sourceType,
            enrichmentStatus: draft.meanings.isEmpty
                ? EnrichmentStatus.missing
                : EnrichmentStatus.ready,
            userEditedAt: Value(userEdited ? now : null),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _insertMeanings(id, draft.meanings);
    return id;
  }

  /// Rewrites content columns and meanings. Never touches `flashcards`,
  /// enrichment metadata, source type or creation time.
  Future<void> _writeContent(
    VocabularyEntry existing,
    DeckRow deck,
    VocabularyDraft draft,
    DateTime now, {
    required bool userEdited,
  }) async {
    final status = draft.meanings.isNotEmpty
        ? EnrichmentStatus.ready
        : (existing.enrichmentStatus == EnrichmentStatus.ready
              ? EnrichmentStatus.missing
              : existing.enrichmentStatus);
    await (_db.update(_entries)..where((e) => e.id.equals(existing.id))).write(
      VocabularyEntriesCompanion(
        deckId: Value(deck.id),
        original: Value(draft.original),
        normalized: Value(draft.normalized),
        lemma: Value(draft.lemma),
        sourceLanguage: Value(deck.sourceLanguage),
        definitionLanguage: Value(deck.definitionLanguage),
        partOfSpeech: Value(draft.partOfSpeech),
        exampleSentence: Value(draft.exampleSentence),
        exampleTranslation: Value(draft.exampleTranslation),
        grammarInfo: Value(draft.grammarInfo),
        notes: Value(draft.notes),
        sourceContext: Value(draft.sourceContext),
        enrichmentStatus: Value(status),
        userEditedAt: userEdited ? Value(now) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
    await (_db.delete(
      _meanings,
    )..where((m) => m.entryId.equals(existing.id))).go();
    await _insertMeanings(existing.id, draft.meanings);
  }

  Future<void> _insertMeanings(
    String entryId,
    List<VocabularyMeaning> meanings,
  ) async {
    if (meanings.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_meanings, [
        for (final (index, meaning) in meanings.indexed)
          VocabularyMeaningsCompanion.insert(
            id: _ids.newId(),
            entryId: entryId,
            position: index,
            meaning: meaning.text,
            explanation: Value(meaning.explanation),
          ),
      ]);
    });
  }

  VocabularyEntry _toDomain(
    VocabularyEntryRow row,
    List<VocabularyMeaning> meanings,
  ) => VocabularyEntry(
    id: row.id,
    deckId: row.deckId,
    original: row.original,
    normalized: row.normalized,
    lemma: row.lemma,
    sourceLanguage: Language.fromCode(row.sourceLanguage),
    definitionLanguage: Language.fromCode(row.definitionLanguage),
    meanings: List.unmodifiable(meanings),
    partOfSpeech: row.partOfSpeech,
    exampleSentence: row.exampleSentence,
    exampleTranslation: row.exampleTranslation,
    grammarInfo: row.grammarInfo,
    notes: row.notes,
    sourceContext: row.sourceContext,
    sourceType: row.sourceType,
    enrichmentStatus: row.enrichmentStatus,
    enrichmentMetadata: _decodeMetadata(row.enrichmentMetadata),
    userEditedAt: row.userEditedAt?.toUtc(),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );

  /// Malformed metadata is ignored rather than making the entry unreadable.
  EnrichmentMetadata? _decodeMetadata(String? json) {
    if (json == null) return null;
    try {
      return EnrichmentMetadata.fromJson(
        (jsonDecode(json) as Map).cast<String, Object?>(),
      );
    } on Object {
      return null;
    }
  }

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
