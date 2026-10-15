import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/id/id_generator.dart';
import '../core/time/clock.dart';
import '../data/database/app_database.dart';
import '../features/decks/data/drift_deck_repository.dart';
import '../features/decks/domain/deck_repository.dart';

/// The single app-wide database connection. Tests override this with an
/// in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidIdGenerator(),
);

final deckRepositoryProvider = Provider<DeckRepository>(
  (ref) => DriftDeckRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
