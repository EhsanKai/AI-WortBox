import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_direction.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  late Map<String, VocabularyEntry> words;
  // History is recorded over the previous days; the app runs "now".
  final history = FixedClock(DateTime.utc(2026, 10, 10, 8));
  final now = DateTime.utc(2026, 10, 19, 8);

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: history,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Kafka'));
    final vocab = DriftVocabularyRepository(
      db,
      clock: history,
      ids: SequentialIdGenerator('seed'),
    );
    words = {
      for (final (word, meaning, example) in [
        ('vergessen', 'فراموش کردن', 'Ich vergesse es immer.'),
        ('der Baum', 'درخت', null),
        ('die Straße', 'خیابان', null),
        ('neu', 'جدید', null),
      ])
        word: await vocab.createEntry(
          VocabularyDraft(
            deckId: deck.id,
            original: word,
            meanings: [VocabularyMeaning(meaning)],
            exampleSentence: example,
          ),
        ),
    };
  });
  tearDown(() => db.close());

  /// Records [outcomes] for [word] in scheduled review, one session per
  /// answer, a day apart.
  Future<void> review(String word, List<ReviewOutcome> outcomes) async {
    final study = DriftStudyRepository(
      db,
      clock: history,
      ids: SequentialIdGenerator('study-$word'),
    );
    for (final (i, outcome) in outcomes.indexed) {
      history.advance(const Duration(hours: 6));
      await study.recordAnswer(
        entryId: words[word]!.id,
        direction: CardDirection.forward,
        sessionId: '$word-session-$i',
        outcome: outcome,
      );
    }
  }

  Future<(List<FlashcardRow>, List<ReviewEventRow>)> snapshot() async => (
    await (db.select(
      db.flashcards,
    )..orderBy([(c) => OrderingTerm.asc(c.id)])).get(),
    await db.select(db.reviewEvents).get(),
  );

  Future<void> openCoach(WidgetTester tester) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/today',
      clock: FixedClock(now),
    );
    await scrollAndTap(tester, find.byKey(const Key('today.coach')));
  }

  testWidgets('without enough history the coach shows the empty state and '
      'writes nothing', (tester) async {
    // One failure only, and a word answered correctly: not enough.
    await review('vergessen', [ReviewOutcome.forgotten]);
    await review('der Baum', [ReviewOutcome.remembered]);
    final before = await snapshot();

    await openCoach(tester);
    expect(find.byKey(const Key('coach.empty')), findsOneWidget);
    expect(find.byKey(const Key('coach.goToReview')), findsOneWidget);
    expect(find.byKey(const Key('coach.start')), findsNothing);
    final after = await snapshot();
    expect(after.$1, before.$1);
    expect(after.$2, hasLength(before.$2.length));
    await unmountApp(tester);
  });

  testWidgets('a word failed in several sessions is listed with the '
      'evidence; recovered and new words are not; opening it changes no '
      'schedule', (tester) async {
    await review('vergessen', [
      ReviewOutcome.forgotten,
      ReviewOutcome.remembered,
      ReviewOutcome.forgotten,
    ]);
    // Failed twice, then recalled three times in a row: recovered.
    await review('der Baum', [
      ReviewOutcome.forgotten,
      ReviewOutcome.forgotten,
      ReviewOutcome.remembered,
      ReviewOutcome.remembered,
      ReviewOutcome.remembered,
    ]);
    await review('die Straße', [ReviewOutcome.forgotten]);
    final before = await snapshot();

    await openCoach(tester);
    final id = words['vergessen']!.id;
    expect(find.byKey(Key('coach.word.$id')), findsOneWidget);
    for (final w in ['der Baum', 'die Straße', 'neu']) {
      expect(find.byKey(Key('coach.word.${words[w]!.id}')), findsNothing);
    }
    expect(find.text('فراموش کردن'), findsOneWidget);
    expect(find.text('Ich vergesse es immer.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(Key('coach.failures.$id')),
        matching: find.textContaining('۲ بار'),
      ),
      findsOneWidget,
    );

    // Inspecting the word records nothing either.
    await scrollAndTap(tester, find.byKey(Key('coach.word.$id')));
    expect(find.byKey(const Key('entryDetail.word')), findsOneWidget);
    final after = await snapshot();
    expect(after.$1, before.$1);
    expect(after.$2, hasLength(before.$2.length));
    await unmountApp(tester);
  });

  testWidgets('focused practice asks only the coach\'s words in the chosen '
      'direction and never changes FSRS due dates', (tester) async {
    await review('vergessen', [
      ReviewOutcome.forgotten,
      ReviewOutcome.forgotten,
    ]);
    await review('der Baum', [ReviewOutcome.remembered]);
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: ReviewDirection.settingsKey,
            value: ReviewDirection.persianToGerman.name,
          ),
        );
    final (cardsBefore, eventsBefore) = await snapshot();

    await openCoach(tester);
    await scrollAndTap(tester, find.byKey(const Key('coach.start')));
    // Persian → German: the meaning is asked first.
    expect(find.text('۱ از ۱'), findsOneWidget);
    expect(find.text('فراموش کردن'), findsOneWidget);
    expect(find.text('vergessen'), findsNothing);
    expect(find.text('درخت'), findsNothing);
    await scrollAndTap(tester, find.byKey(const Key('practice.reveal')));
    expect(find.text('vergessen'), findsOneWidget);
    await scrollAndTap(tester, find.byKey(const Key('practice.remembered')));
    expect(find.byKey(const Key('practice.summary')), findsOneWidget);

    // Scheduling state is untouched; the answer is kept as history only.
    final (cardsAfter, eventsAfter) = await snapshot();
    expect(cardsAfter, cardsBefore);
    expect(eventsAfter, hasLength(eventsBefore.length + 1));
    final added = eventsAfter.firstWhere(
      (e) => !eventsBefore.any((b) => b.id == e.id),
    );
    expect(added.entryId, words['vergessen']!.id);
    expect(added.direction, CardDirection.reverse);
    expect(added.outcome, ReviewOutcome.remembered);
    await unmountApp(tester);
  });
}
