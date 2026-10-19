import 'dart:convert';
import 'dart:math' show min;

import 'package:drift/drift.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/language/language.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../../tags/data/drift_tag_repository.dart';
import '../domain/duplicate_detection.dart';
import '../domain/enrichment_update.dart';
import '../domain/vocabulary_draft.dart';
import '../domain/vocabulary_entry.dart';
import '../domain/vocabulary_repository.dart';
import '../domain/vocabulary_search.dart';

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
  Stream<List<VocabularyEntry>> watchSearch(
    VocabularyQuery query, {
    int limit = AppConfig.maxSearchResults,
  }) => _searchStatement(query, limit).watch().map(_group);

  @override
  Future<List<VocabularyEntry>> search(
    VocabularyQuery query, {
    int limit = AppConfig.maxSearchResults,
  }) => _guard(
    'search',
    () async => _group(await _searchStatement(query, limit).get()),
  );

  JoinedSelectStatement<HasResultSet, dynamic> _searchStatement(
    VocabularyQuery query,
    int limit,
  ) {
    var where = const Constant(true) as Expression<bool>;
    if (query.deckId case final deckId?) {
      where &= _entries.deckId.equals(deckId);
    }
    if (query.difficultOnly) where &= _entries.markedDifficultAt.isNotNull();
    if (query.tagId case final tagId?) {
      final tagged = _db.selectOnly(_db.entryTags)
        ..addColumns([_db.entryTags.entryId])
        ..where(_db.entryTags.tagId.equals(tagId));
      where &= _entries.id.isInQuery(tagged);
    }
    final keys = VocabularySearch.queryKeys(query.text);
    if (keys.isNotEmpty) {
      // instr(): exact substring match; no LIKE wildcards to escape.
      where &= keys
          .map(
            (key) => FunctionCallExpression<int>('instr', [
              _entries.searchKey,
              Variable.withString(key),
            ]).isBiggerThanValue(0),
          )
          .reduce((a, b) => a | b);
    }
    // Limit entries first, then load their meanings.
    final ids = _db.selectOnly(_entries)
      ..addColumns([_entries.id])
      ..where(where)
      ..orderBy([
        OrderingTerm.desc(_entries.createdAt),
        OrderingTerm.asc(_entries.normalized),
        OrderingTerm.asc(_entries.id),
      ])
      ..limit(limit);
    return _entriesWithMeanings(_entries.id.isInQuery(ids));
  }

  @override
  Stream<({int total, int difficult})> watchCounts() {
    final total = _entries.id.count();
    final difficult = _entries.id.count(
      filter: _entries.markedDifficultAt.isNotNull(),
    );
    final query = _db.selectOnly(_entries)..addColumns([total, difficult]);
    return query.watchSingle().map(
      (row) =>
          (total: row.read(total) ?? 0, difficult: row.read(difficult) ?? 0),
    );
  }

  @override
  Future<void> setDifficult(String id, {required bool difficult}) =>
      _guard('setDifficult', () async {
        final updated =
            await (_db.update(_entries)..where((e) => e.id.equals(id))).write(
              VocabularyEntriesCompanion(
                markedDifficultAt: Value(difficult ? _clock.nowUtc() : null),
              ),
            );
        if (updated == 0) throw NotFoundException('VocabularyEntry', id);
      });

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
  Future<List<VocabularyEntry>> applyEnrichments(
    List<EnrichmentUpdate> updates,
  ) {
    if (updates.isEmpty) return Future.value(const []);
    return _guard('applyEnrichments', () {
      return _db.transaction(() async {
        // Check every entry before writing anything.
        final current = <String, VocabularyEntry>{};
        final conflicts = <String>{};
        for (final update in updates) {
          final entry = await _requireEntry(update.entryId);
          if (!entry.updatedAt.isAtSameMomentAs(update.expectedUpdatedAt)) {
            conflicts.add(entry.id);
          }
          current[entry.id] = entry;
        }
        if (conflicts.isNotEmpty) throw EnrichmentConflictException(conflicts);

        final now = _clock.nowUtc();
        for (final update in updates) {
          final existing = current[update.entryId]!;
          final deck = await _requireDeck(existing.deckId);
          final base = VocabularyDraft.fromEntry(existing);
          // Original, notes, source context and source type are kept as is.
          final merged = VocabularyDraft(
            deckId: base.deckId,
            original: base.original,
            meanings: [...base.meanings, ...update.addMeanings],
            lemma: update.lemma ?? base.lemma,
            partOfSpeech: update.partOfSpeech ?? base.partOfSpeech,
            exampleSentence: update.exampleSentence ?? base.exampleSentence,
            exampleTranslation:
                update.exampleTranslation ?? base.exampleTranslation,
            grammarInfo: update.grammarInfo ?? base.grammarInfo,
            notes: base.notes,
            sourceContext: base.sourceContext,
            sourceType: base.sourceType,
          ).cleaned();
          _throwIfInvalid(merged);
          await _writeContent(existing, deck, merged, now, userEdited: false);
          await (_db.update(
            _entries,
          )..where((e) => e.id.equals(existing.id))).write(
            VocabularyEntriesCompanion(
              enrichmentMetadata: Value(jsonEncode(update.metadata.toJson())),
            ),
          );
        }
        return [for (final u in updates) (await getEntry(u.entryId))!];
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
  Future<int> deleteEntries(Iterable<String> ids) {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return Future.value(0);
    return _guard(
      'deleteEntries',
      () => _db.transaction(() async {
        var deleted = 0;
        // Bounded batches stay below SQLite's bound-parameter limit.
        for (var i = 0; i < unique.length; i += 500) {
          final batch = unique.sublist(i, min(i + 500, unique.length));
          deleted += await (_db.delete(
            _entries,
          )..where((e) => e.id.isIn(batch))).go();
        }
        return deleted;
      }),
    );
  }

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
          tags: c.tags,
        ),
    ];
    return _guard('importEntries', () {
      return _db.transaction(() async {
        final deck = await _requireDeck(deckId);
        final existing = await getEntries(deckId);
        final decisions = planImport(cleaned, existing, strategy);

        final draftsByRow = {for (final c in cleaned) c.rowNumber: c.draft};
        final tagsByRow = {for (final c in cleaned) c.rowNumber: c.tags};
        // Rows to create, in row order, with later in-file merges folded in.
        final creates = <int, VocabularyDraft>{};
        final createTags = <int, List<String>>{};
        // Existing entries receiving meanings, keyed by entry id.
        final entryMerges = <String, VocabularyDraft>{};
        final mergeTags = <String, List<String>>{};
        final existingById = {for (final e in existing) e.id: e};

        for (final decision in decisions) {
          final draft = draftsByRow[decision.rowNumber]!;
          final tags = tagsByRow[decision.rowNumber]!;
          switch (decision) {
            case CreateDecision():
              creates[decision.rowNumber] = draft;
              createTags[decision.rowNumber] = [...tags];
            case MergeIntoRowDecision(:final targetRowNumber):
              creates[targetRowNumber] = mergeDrafts(
                creates[targetRowNumber]!,
                draft,
              );
              createTags[targetRowNumber]!.addAll(tags);
            case MergeIntoEntryDecision(:final entryId):
              entryMerges[entryId] = mergeDrafts(
                entryMerges[entryId] ??
                    VocabularyDraft.fromEntry(existingById[entryId]!),
                draft,
              );
              (mergeTags[entryId] ??= []).addAll(tags);
            case SkipDecision():
              break;
          }
        }

        final now = _clock.nowUtc();
        for (final MapEntry(key: row, value: draft) in creates.entries) {
          _throwIfInvalid(draft);
          final id = await _insert(deck, draft, now, userEdited: false);
          await addTagsByName(_db, id, createTags[row]!, now: now, ids: _ids);
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
          await addTagsByName(
            _db,
            entryId,
            mergeTags[entryId]!,
            now: now,
            ids: _ids,
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
            searchKey: Value(_searchKey(draft)),
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
        searchKey: Value(_searchKey(draft)),
      ),
    );
    await (_db.delete(
      _meanings,
    )..where((m) => m.entryId.equals(existing.id))).go();
    await _insertMeanings(existing.id, draft.meanings);
  }

  static String _searchKey(VocabularyDraft draft) => VocabularySearch.keyFor(
    original: draft.original,
    lemma: draft.lemma,
    meanings: draft.meanings.map((m) => m.text),
  );

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
    markedDifficultAt: row.markedDifficultAt?.toUtc(),
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
