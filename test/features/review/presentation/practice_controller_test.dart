import 'dart:math';

import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_direction.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/review/domain/review_scheduler.dart';
import 'package:ai_wortbox/features/review/presentation/practice_controller.dart';
import 'package:ai_wortbox/features/review/presentation/review_providers.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late DriftVocabularyRepository vocab;
  late Deck deck;
  late FixedClock clock;

  ProviderContainer newContainer() => ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
      idGeneratorProvider.overrideWithValue(SequentialIdGenerator('x')),
      randomProvider.overrideWithValue(Random(7)),
      studyRepositoryProvider.overrideWithValue(
        DriftStudyRepository(
          db,
          clock: clock,
          ids: SequentialIdGenerator('card'),
          scheduler: FsrsReviewScheduler(fsrs.Scheduler(enableFuzzing: false)),
        ),
      ),
    ],
    retry: (_, _) => null,
  );

  setUp(() async {
    db = openTestDatabase();
    clock = FixedClock(DateTime.utc(2026, 10, 19, 9));
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('d'),
    ).createDeck(const DeckDraft(name: 'A1'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('v'),
    );
    container = newContainer();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<VocabularyEntry> add(String word, List<String> meanings) {
    clock.advance(const Duration(seconds: 1));
    return vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: word,
        meanings: [for (final m in meanings) VocabularyMeaning(m)],
      ),
    );
  }

  Future<void> setDirection(ReviewDirection direction) =>
      container.read(reviewDirectionProvider.notifier).set(direction);

  Future<PracticeState> start(PracticeConfig config) async {
    // Keep the auto-dispose provider alive during the test.
    container.listen(practiceControllerProvider(config), (_, _) {});
    await pumpEventQueue();
    return container.read(practiceControllerProvider(config));
  }

  PracticeController controllerOf(PracticeConfig config) =>
      container.read(practiceControllerProvider(config).notifier);

  PracticeState stateOf(PracticeConfig config) =>
      container.read(practiceControllerProvider(config));

  Future<void> answer(PracticeConfig config, ReviewOutcome outcome) async {
    controllerOf(config).reveal();
    await controllerOf(config).answer(outcome);
  }

  test('German → Persian is the default direction', () async {
    expect(
      await container.read(reviewDirectionProvider.future),
      ReviewDirection.germanToPersian,
    );
  });

  test('no words with meanings → empty, scheduled or free', () async {
    await add('Haus', []);
    expect((await start(const PracticeConfig())).phase, PracticePhase.empty);
    expect(
      (await start(const PracticeConfig(scheduled: false))).phase,
      PracticePhase.empty,
    );
  });

  test('scheduled review: German first, reveal required, one event and '
      'FSRS state per answer, double taps record once', () async {
    final haus = await add('Haus', ['خانه']);
    const config = PracticeConfig();
    final state = await start(config);
    expect(state.phase, PracticePhase.question);
    expect(state.cards.single.entry.id, haus.id);
    expect(state.cards.single.asksMeaning, isTrue);

    // Answering before the reveal is ignored.
    await controllerOf(config).answer(ReviewOutcome.remembered);
    expect(await db.select(db.reviewEvents).get(), isEmpty);

    controllerOf(config).reveal();
    await Future.wait([
      controllerOf(config).answer(ReviewOutcome.remembered),
      controllerOf(config).answer(ReviewOutcome.remembered),
    ]);
    final events = await db.select(db.reviewEvents).get();
    expect(events, hasLength(1));
    expect(events.single.direction, CardDirection.forward);
    final card = (await db.select(db.flashcards).get()).single;
    expect(card.direction, CardDirection.forward);
    expect(card.state, CardState.learning);
    expect(card.reviewCount, 1);

    // The learning step (10 minutes) brings the word back in this session.
    final after = stateOf(config);
    expect(after.phase, PracticePhase.question);
    expect(after.cards, hasLength(2));
    clock.advance(const Duration(minutes: 10));
    await answer(config, ReviewOutcome.remembered);
    final done = stateOf(config);
    expect(done.phase, PracticePhase.done);
    expect(done.remembered, 2);
    expect(
      (await db.select(db.flashcards).get()).single.state,
      CardState.review,
    );

    // Graduated: nothing is due in a new session until its due date.
    container.dispose();
    container = newContainer();
    expect((await start(const PracticeConfig())).phase, PracticePhase.empty);
  });

  test('Persian → German shows the meaning first and schedules the reverse '
      'card', () async {
    await add('Haus', ['خانه']);
    await setDirection(ReviewDirection.persianToGerman);
    const config = PracticeConfig();
    final state = await start(config);
    expect(state.cards.single.direction, CardDirection.reverse);
    expect(state.cards.single.asksMeaning, isFalse);
    await answer(config, ReviewOutcome.forgotten);
    expect(
      (await db.select(db.flashcards).get()).single.direction,
      CardDirection.reverse,
    );
    expect(
      (await db.select(db.reviewEvents).get()).single.direction,
      CardDirection.reverse,
    );
  });

  test('both directions: a word is asked in one direction per day; the '
      'other direction follows on another day', () async {
    await add('Haus', ['خانه']);
    await add('Baum', ['درخت']);
    await setDirection(ReviewDirection.both);
    const config = PracticeConfig();
    var state = await start(config);
    expect(state.cards.map((c) => c.direction), [
      CardDirection.forward,
      CardDirection.forward,
    ]);
    // Answer until the session ends (learning steps repeat cards).
    while (stateOf(config).phase == PracticePhase.question) {
      clock.advance(const Duration(minutes: 10));
      await answer(config, ReviewOutcome.remembered);
    }
    expect(stateOf(config).phase, PracticePhase.done);
    final events = await db.select(db.reviewEvents).get();
    expect(events.every((e) => e.direction == CardDirection.forward), isTrue);

    container.dispose();
    container = newContainer();
    expect((await start(config)).phase, PracticePhase.empty);

    clock.advance(const Duration(days: 1));
    container.dispose();
    container = newContainer();
    state = await start(config);
    expect(state.cards.map((c) => c.direction).toSet(), {
      CardDirection.reverse,
    });
  });

  test('free practice records events but never scheduling state; with both '
      'directions it alternates', () async {
    await add('Haus', ['خانه']);
    await add('Baum', ['درخت']);
    await setDirection(ReviewDirection.both);
    const config = PracticeConfig(scheduled: false);
    final state = await start(config);
    expect(state.cards.map((c) => c.direction), [
      CardDirection.forward,
      CardDirection.reverse,
    ]);
    await answer(config, ReviewOutcome.remembered);
    await answer(config, ReviewOutcome.forgotten);
    expect(stateOf(config).phase, PracticePhase.done);
    expect(await db.select(db.flashcards).get(), isEmpty);
    final events = await db.select(db.reviewEvents).get();
    expect(events.map((e) => e.direction).toSet(), {
      CardDirection.forward,
      CardDirection.reverse,
    });
  });

  test('difficult-only practice is free practice and leaves words '
      'unchanged', () async {
    final haus = await add('Haus', ['خانه']);
    await add('Baum', ['درخت']);
    const difficult = PracticeConfig(difficultOnly: true);
    expect(difficult.isScheduled, isFalse);
    expect((await start(difficult)).phase, PracticePhase.empty);
    await vocab.setDifficult(haus.id, difficult: true);
    final marked = (await vocab.getEntry(haus.id))!;
    final config = PracticeConfig(deckId: deck.id, difficultOnly: true);
    final state = await start(config);
    expect(state.cards.map((c) => c.entry.original), ['Haus']);
    await answer(config, ReviewOutcome.remembered);
    expect(await db.select(db.flashcards).get(), isEmpty);
    expect(await vocab.getEntry(haus.id), marked);
  });

  test('the direction choice is stored and survives a restart', () async {
    await setDirection(ReviewDirection.both);
    container.dispose();
    container = newContainer();
    expect(
      await container.read(reviewDirectionProvider.future),
      ReviewDirection.both,
    );
    final stored = await db.select(db.appSettings).get();
    expect(stored.single.key, ReviewDirection.settingsKey);
    expect(stored.single.value, 'both');
  });

  test('free sessions are capped at 20 words; scheduled sessions introduce '
      'at most the deck\'s daily new-card limit', () async {
    for (var i = 0; i < 25; i++) {
      await add('Wort $i', ['لغت $i']);
    }
    expect(
      (await start(const PracticeConfig(scheduled: false))).cards,
      hasLength(20),
    );
    expect((await start(const PracticeConfig())).cards, hasLength(20));
  });
}
