import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/config/app_config.dart';
import '../../features/review/domain/flashcard.dart';
import '../../features/vocabulary/domain/vocabulary_entry.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Decks, VocabularyEntries, VocabularyMeanings, Flashcards],
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // No upgrades exist yet (schema v1). Future versions use
      // `stepByStep(...)` from the generated `app_database.steps.dart`.
      throw StateError('Unsupported schema upgrade from $from to $to');
    },
    beforeOpen: (details) async {
      // SQLite disables foreign keys per connection by default.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
