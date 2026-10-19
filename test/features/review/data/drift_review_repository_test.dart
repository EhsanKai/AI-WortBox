import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_review_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/statistics/domain/study_statistics.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late DriftReviewRepository reviews;
  late String entryId;

  setUp(() async {
    db = openTestDatabase();
    // Tehran: UTC+3:30 (no daylight saving since 2022).
    clock = FixedClock(
      DateTime.utc(2026, 10, 18, 19),
      utcOffset: const Duration(hours: 3, minutes: 30),
    );
    final deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('d'),
    ).createDeck(const DeckDraft(name: 'A1'));
    entryId =
        (await DriftVocabularyRepository(
              db,
              clock: clock,
              ids: SequentialIdGenerator('v'),
            ).createEntry(
              VocabularyDraft(
                deckId: deck.id,
                original: 'Haus',
                meanings: const [VocabularyMeaning('خانه')],
              ),
            ))
            .id;
    reviews = DriftReviewRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('r'),
    );
  });
  tearDown(() => db.close());

  Future<ReviewEvent> record(String session, ReviewOutcome outcome) =>
      reviews.record(
        entryId: entryId,
        sessionId: session,
        direction: CardDirection.reverse,
        outcome: outcome,
      );

  test('events store UTC time and the local day at recording time; '
      'the local midnight decides the day', () async {
    // 19:00 UTC = 22:30 in Tehran → 18 October.
    final evening = await record('s1', ReviewOutcome.remembered);
    expect(evening.reviewedAt, DateTime.utc(2026, 10, 18, 19));
    expect(evening.localDay, const LocalDay(2026, 10, 18));

    // 21:00 UTC = 00:30 in Tehran → already 19 October locally.
    clock.advance(const Duration(hours: 2));
    final night = await record('s1', ReviewOutcome.forgotten);
    expect(night.localDay, const LocalDay(2026, 10, 19));

    final rows = await db.select(db.reviewEvents).get();
    expect(rows.map((r) => r.localDay), ['2026-10-18', '2026-10-19']);
    expect(rows.every((r) => r.direction == CardDirection.reverse), isTrue);
  });

  test('daily activity and distinct session counts', () async {
    await record('s1', ReviewOutcome.remembered);
    await record('s1', ReviewOutcome.forgotten);
    await record('s2', ReviewOutcome.remembered);
    clock.advance(const Duration(days: 1));
    await record('s3', ReviewOutcome.remembered);

    final activity = await reviews.watchDailyActivity().first;
    expect(activity.toSet(), {
      const DayActivity(day: LocalDay(2026, 10, 18), reviews: 3, remembered: 2),
      const DayActivity(day: LocalDay(2026, 10, 19), reviews: 1, remembered: 1),
    });
    expect(await reviews.watchSessionCount().first, 3);
  });

  test('recording never writes flashcards or vocabulary', () async {
    final before = await db.select(db.vocabularyEntries).get();
    await record('s1', ReviewOutcome.forgotten);
    expect(await db.select(db.flashcards).get(), isEmpty);
    expect(await db.select(db.vocabularyEntries).get(), before);
  });

  test('empty history', () async {
    expect(await reviews.watchDailyActivity().first, isEmpty);
    expect(await reviews.watchSessionCount().first, 0);
  });
}
