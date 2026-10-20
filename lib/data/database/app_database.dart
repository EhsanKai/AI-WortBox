import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/config/app_config.dart';
import '../../features/review/domain/flashcard.dart';
import '../../features/review/domain/review_event.dart';
import '../../features/sentence_practice/domain/sentence_practice.dart';
import '../../features/vocabulary/domain/vocabulary_entry.dart';
import '../../features/vocabulary/domain/vocabulary_search.dart';
import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Decks,
    VocabularyEntries,
    VocabularyMeanings,
    Flashcards,
    Tags,
    EntryTags,
    ReviewEvents,
    AppSettings,
    SentencePracticeEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database file in the app documents directory.
  factory AppDatabase.open() =>
      AppDatabase(driftDatabase(name: AppConfig.databaseName));

  // Bump this and add a step in [migration] for every schema change, then run
  // `dart run drift_dev make-migrations` to export the schema and generate
  // migration tests. See docs/architecture.md.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // v2: tags, review events, settings, the difficult mark and the
        // search key. Purely additive; no existing value is changed.
        await m.addColumn(
          schema.vocabularyEntries,
          schema.vocabularyEntries.markedDifficultAt,
        );
        await m.addColumn(
          schema.vocabularyEntries,
          schema.vocabularyEntries.searchKey,
        );
        await m.createTable(schema.tags);
        await m.createTable(schema.entryTags);
        await m.createTable(schema.reviewEvents);
        await m.createTable(schema.appSettings);
        await m.createIndex(schema.idxEntryTagsTag);
        await m.createIndex(schema.idxReviewEventsDay);
        await _backfillSearchKeys();
      },
      from2To3: (m, schema) async {
        // v3: sentence-practice history. Purely additive: a new table and
        // its index; no existing row or column is touched.
        await m.createTable(schema.sentencePracticeEvents);
        await m.createIndex(schema.idxSentencePracticeEntry);
      },
    ),
    beforeOpen: (details) async {
      // SQLite disables foreign keys per connection by default.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Computes `search_key` for entries created before v2 from their stored
  /// word, base form and meanings (read-only for those columns).
  Future<void> _backfillSearchKeys() async {
    final entries = await customSelect(
      'SELECT id, original, lemma FROM vocabulary_entries',
    ).get();
    final meanings = <String, List<String>>{};
    final meaningRows = await customSelect(
      'SELECT entry_id, meaning FROM vocabulary_meanings '
      'ORDER BY entry_id, position',
    ).get();
    for (final row in meaningRows) {
      meanings
          .putIfAbsent(row.read<String>('entry_id'), () => [])
          .add(row.read<String>('meaning'));
    }
    for (final row in entries) {
      final id = row.read<String>('id');
      await customUpdate(
        'UPDATE vocabulary_entries SET search_key = ? WHERE id = ?',
        variables: [
          Variable.withString(
            VocabularySearch.keyFor(
              original: row.read<String>('original'),
              lemma: row.readNullable<String>('lemma'),
              meanings: meanings[id] ?? const [],
            ),
          ),
          Variable.withString(id),
        ],
        updates: {vocabularyEntries},
      );
    }
  }
}
