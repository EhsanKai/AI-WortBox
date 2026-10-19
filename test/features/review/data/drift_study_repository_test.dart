import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/review/domain/review_scheduler.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FixedClock clock;
  late DriftStudyRepository study;
  late DriftVocabularyRepository vocab;
  late DriftDeckRepository decks;
  late Deck deck;
  const forward = {CardDirection.forward};

  setUp(() async {
    db = openTestDatabase();
    // Device time zone UTC+3:30 (Tehran): local midnight is 20:30 UTC.
    clock = FixedClock(
      DateTime.utc(2026, 10, 19, 6),
      utcOffset: const Duration(hours: 3, minutes: 30),
    );
    decks = DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('d'),
    );
    deck = await decks.createDeck(const DeckDraft(name: 'A1'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('v'),
    );
    study = DriftStudyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('s'),
      scheduler: FsrsReviewScheduler(fsrs.Scheduler(enableFuzzing: false)),
    );
  });
  tearDown(() => db.close());

  Future<VocabularyEntry> add(String word, [List<String> meanings = const []]) {
    clock.advance(const Duration(seconds: 1));
    return vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: word,
        meanings: [for (final m in meanings) VocabularyMeaning(m)],
      ),
    );
  }

  Future<List<String>> due({
    Set<CardDirection> directions = forward,
    String? deckId,
  }) async => [
    for (final c in await study.dueQueue(
      deckId: deckId,
      directions: directions,
    ))
      '${(await vocab.getEntry(c.entryId))!.original}/${c.direction.name}',
  ];

  test('existing words without scheduling state are new cards; words '
      'without a meaning are never reviewed', () async {
    await add('Haus', ['خانه']);
    await add('Übermüdung');
    expect(await due(), ['Haus/forward']);
    expect(await db.select(db.flashcards).get(), isEmpty);
  });

  test('an answer advances and persists the FSRS state and records one '
      'event, in one transaction', () async {
    final haus = await add('Haus', ['خانه']);
    final (state, event) = await study.recordAnswer(
      entryId: haus.id,
      direction: CardDirection.forward,
      sessionId: 'session-1',
      outcome: ReviewOutcome.remembered,
    );
    final rows = await db.select(db.flashcards).get();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.entryId, haus.id);
    expect(row.direction, CardDirection.forward);
    expect(row.state, CardState.learning);
    expect(row.due, clock.nowUtc().add(const Duration(minutes: 10)));
    expect(row.stability, state.stability);
    expect(row.reviewCount, 1);
    expect(row.schedulerVersion, FsrsReviewScheduler.version);
    expect(row.createdAt, clock.nowUtc());
    expect(await study.cardState(haus.id, CardDirection.forward), state);

    final events = await db.select(db.reviewEvents).get();
    expect(events.single.id, event.id);
    expect(events.single.direction, CardDirection.forward);
    expect(events.single.outcome, ReviewOutcome.remembered);
    // Local day in UTC+3:30.
    expect(events.single.localDay, '2026-10-19');
  });

  test('repeated reviews update the same row; intervals grow; the word '
      'returns only when due', () async {
    final haus = await add('Haus', ['خانه']);
    Future<ReviewState> answer(ReviewOutcome outcome) async =>
        (await study.recordAnswer(
          entryId: haus.id,
          direction: CardDirection.forward,
          sessionId: 's',
          outcome: outcome,
        )).$1;

    await answer(ReviewOutcome.remembered); // step 1, due in 10 min
    expect(await due(), ['Haus/forward'], reason: 'within the learn-ahead');
    clock.advance(const Duration(minutes: 10));
    final graduated = await answer(ReviewOutcome.remembered);
    expect(graduated.state, CardState.review);
    expect(await due(), isEmpty);

    clock.set(graduated.due);
    expect(await due(), ['Haus/forward']);
    final second = await answer(ReviewOutcome.remembered);
    expect(
      second.due.difference(graduated.due),
      greaterThan(graduated.due.difference(graduated.lastReviewedAt!)),
    );

    clock.set(second.due);
    final lapsed = await answer(ReviewOutcome.forgotten);
    expect(lapsed.state, CardState.relearning);
    expect(lapsed.lapseCount, 1);
    expect(lapsed.reviewCount, 4);
    expect(await db.select(db.flashcards).get(), hasLength(1));
    expect(await db.select(db.reviewEvents).get(), hasLength(4));
  });

  test('a review card due later today (local day) is shown today', () async {
    final haus = await add('Haus', ['خانه']);
    await db
        .into(db.flashcards)
        .insert(
          FlashcardsCompanion.insert(
            id: 'c1',
            entryId: haus.id,
            direction: CardDirection.forward,
            state: CardState.review,
            stability: const Value(3),
            difficulty: const Value(5),
            // 20:00 UTC = 23:30 local, still today.
            due: DateTime.utc(2026, 10, 19, 20),
            createdAt: DateTime.utc(2026, 10, 1),
            updatedAt: DateTime.utc(2026, 10, 1),
          ),
        );
    expect(await due(), ['Haus/forward']);
    await (db.update(db.flashcards)..where((c) => c.id.equals('c1'))).write(
      // 21:00 UTC = 00:30 local tomorrow.
      FlashcardsCompanion(due: Value(DateTime.utc(2026, 10, 19, 21))),
    );
    expect(await due(), isEmpty);
  });

  test(
    'new cards respect the deck\'s daily limit, counted per local day',
    () async {
      deck = await decks.createDeck(
        const DeckDraft(name: 'Limit', dailyNewCardLimit: 2),
      );
      final words = [
        for (final w in ['eins', 'zwei', 'drei', 'vier']) await add(w, ['x']),
      ];
      expect(await due(), ['eins/forward', 'zwei/forward']);
      await study.recordAnswer(
        entryId: words[0].id,
        direction: CardDirection.forward,
        sessionId: 's',
        outcome: ReviewOutcome.remembered,
      );
      // "eins" is learning; one new card is left for today.
      expect(await due(), ['eins/forward', 'zwei/forward']);
      await study.recordAnswer(
        entryId: words[1].id,
        direction: CardDirection.forward,
        sessionId: 's',
        outcome: ReviewOutcome.forgotten,
      );
      expect(await due(), ['zwei/forward', 'eins/forward']);

      // After local midnight two new cards are introduced again.
      clock.set(DateTime.utc(2026, 10, 19, 21));
      expect(
        (await due()).where(
          (d) => d.startsWith('drei') || d.startsWith('vier'),
        ),
        ['drei/forward', 'vier/forward'],
      );
    },
  );

  test('directions are scheduled independently; switching direction keeps '
      'the other direction\'s history', () async {
    final haus = await add('Haus', ['خانه']);
    await study.recordAnswer(
      entryId: haus.id,
      direction: CardDirection.forward,
      sessionId: 's',
      outcome: ReviewOutcome.remembered,
    );
    expect(await due(directions: {CardDirection.reverse}), ['Haus/reverse']);
    await study.recordAnswer(
      entryId: haus.id,
      direction: CardDirection.reverse,
      sessionId: 's',
      outcome: ReviewOutcome.forgotten,
    );
    final rows = await db.select(db.flashcards).get();
    expect(rows.map((r) => r.direction).toSet(), {
      CardDirection.forward,
      CardDirection.reverse,
    });
    expect((await study.cardState(haus.id, CardDirection.forward))!.step, 1);
    expect((await study.cardState(haus.id, CardDirection.reverse))!.step, 0);
  });

  test('deck filter and deleted words', () async {
    final other = await decks.createDeck(const DeckDraft(name: 'B1'));
    final haus = await add('Haus', ['خانه']);
    await vocab.createEntry(
      VocabularyDraft(
        deckId: other.id,
        original: 'Baum',
        meanings: const [VocabularyMeaning('درخت')],
      ),
    );
    expect(await due(deckId: deck.id), ['Haus/forward']);
    expect(await due(), hasLength(2));

    await study.recordAnswer(
      entryId: haus.id,
      direction: CardDirection.forward,
      sessionId: 's',
      outcome: ReviewOutcome.remembered,
    );
    await vocab.deleteEntry(haus.id);
    // Scheduling state goes with the word; the answer stays in history.
    expect(await db.select(db.flashcards).get(), isEmpty);
    expect((await db.select(db.reviewEvents).get()).single.entryId, isNull);
    expect(await due(), ['Baum/forward']);
  });

  test('the due count follows answers and new words', () async {
    final haus = await add('Haus', ['خانه']);
    final counts = <int>[];
    final sub = study.watchDueCount(directions: forward).listen(counts.add);
    await pumpEventQueue();
    expect(counts.last, 1);

    await add('Baum', ['درخت']);
    await pumpEventQueue();
    expect(counts.last, 2);

    clock.advance(const Duration(minutes: 1));
    await study.recordAnswer(
      entryId: haus.id,
      direction: CardDirection.forward,
      sessionId: 's',
      outcome: ReviewOutcome.remembered,
    );
    clock.advance(const Duration(minutes: 10));
    await study.recordAnswer(
      entryId: haus.id,
      direction: CardDirection.forward,
      sessionId: 's',
      outcome: ReviewOutcome.remembered,
    );
    await pumpEventQueue();
    expect(counts.last, 1, reason: '"Haus" graduated to a later day');
    await sub.cancel();
  });
}
