import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/sentence_practice/data/drift_sentence_practice_repository.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_practice.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/learning_data.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late DriftSentencePracticeRepository repo;
  late SeededIds ids;

  setUp(() async {
    db = openTestDatabase();
    ids = await seedLearningData(db);
    clock = FixedClock(DateTime.utc(2026, 10, 20, 9));
    repo = DriftSentencePracticeRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('sp'),
    );
  });
  tearDown(() => db.close());

  Future<void> record(String entryId) => repo.record(
    entryId: entryId,
    direction: SentencePracticeDirection.understand,
    level: SentenceLevel.a2,
    outcome: SentencePracticeOutcome.correct,
  );

  test(
    'records only how an exercise ended and the latest time per word',
    () async {
      await record(ids.gehen);
      clock.advance(const Duration(hours: 2));
      await record(ids.gehen);
      final last = await repo.lastPracticedByEntry();
      expect(last[ids.gehen], DateTime.utc(2026, 10, 20, 11));
      // Seeded history of Haus (from seedLearningData).
      expect(last.keys, unorderedEquals([ids.haus, ids.gehen]));
      final row = (await db.select(db.sentencePracticeEvents).get()).last;
      expect(
        row.toJson().keys,
        unorderedEquals([
          'id',
          'entryId',
          'direction',
          'level',
          'outcome',
          'practicedAt',
        ]),
      );
    },
  );

  test('recording and clearing never touch words, FSRS cards or review '
      'history', () async {
    final before = await dumpLearningData(db);
    await record(ids.gehen);
    final cleared = await repo.clearHistory();
    expect(cleared, 2);
    final after = await dumpLearningData(db);
    for (final table in before.keys) {
      if (table == 'sentence_practice_events') continue;
      expect(after[table], before[table], reason: table);
    }
    expect(after['sentence_practice_events'], isEmpty);
    expect(await repo.watchCount().first, 0);
  });

  test('deleting a word deletes its sentence-practice history', () async {
    await record(ids.gehen);
    await DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('x'),
    ).deleteEntry(ids.gehen);
    expect((await repo.lastPracticedByEntry()).keys, [ids.haus]);
  });
}
