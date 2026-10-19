import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/phase5_fakes.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  late DriftVocabularyRepository vocab;
  late List<VocabularyEntry> words;
  final clock = FixedClock(DateTime.utc(2026, 10, 19, 8));

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Kafka'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('seed'),
    );
    words = [
      for (final (word, meaning) in [
        ('das Haus', 'خانه'),
        ('der Baum', 'درخت'),
        ('die Straße', 'خیابان'),
      ])
        await vocab.createEntry(
          VocabularyDraft(
            deckId: deck.id,
            original: word,
            meanings: [VocabularyMeaning(meaning)],
          ),
        ),
    ];
  });
  tearDown(() => db.close());

  Future<void> openDeck(WidgetTester tester, {FakeSpeechService? speech}) =>
      pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}',
        clock: clock,
        speech: speech,
      );

  group('deck: answers hidden until review', () {
    testWidgets('opening a deck lists German words only; meanings appear '
        'only when asked for', (tester) async {
      await openDeck(tester);
      expect(find.text('das Haus'), findsOneWidget);
      for (final meaning in ['خانه', 'درخت', 'خیابان']) {
        expect(find.text(meaning), findsNothing);
        expect(find.bySemanticsLabel(meaning), findsNothing);
      }
      await tester.tap(find.byKey(const Key('deck.toggleMeanings')));
      await tester.pumpAndSettle();
      expect(find.text('خانه'), findsOneWidget);
      await tester.tap(find.byKey(const Key('deck.toggleMeanings')));
      await tester.pumpAndSettle();
      expect(find.text('خانه'), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('start review: one card at a time, German first, the meaning '
        'is not built before the reveal; the answer is recorded with FSRS', (
      tester,
    ) async {
      final speech = FakeSpeechService();
      await openDeck(tester, speech: speech);
      expect(find.textContaining('۳ کارت'), findsOneWidget);
      await tester.tap(find.byKey(const Key('deck.startReview')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('practice.word')), findsOneWidget);
      expect(find.byKey(const Key('practice.meaning')), findsNothing);
      expect(find.byKey(const Key('practice.answer')), findsNothing);
      for (final meaning in ['خانه', 'درخت', 'خیابان']) {
        expect(find.text(meaning), findsNothing);
        expect(find.bySemanticsLabel(RegExp(meaning)), findsNothing);
      }
      // Oldest word first.
      expect(find.text('das Haus'), findsOneWidget);
      expect(find.text('der Baum'), findsNothing);

      // Pronouncing the German prompt does not reveal anything.
      await tester.tap(find.byTooltip('تلفظ لغت'));
      await tester.pumpAndSettle();
      expect(speech.spoken, [('das Haus', Language.german)]);

      await tester.tap(find.byKey(const Key('practice.reveal')));
      await tester.pumpAndSettle();
      expect(find.text('خانه'), findsOneWidget);
      await scrollAndTap(tester, find.byKey(const Key('practice.remembered')));

      // Next card, answer hidden again.
      expect(find.text('der Baum'), findsOneWidget);
      expect(find.text('درخت'), findsNothing);

      final card = (await db.select(db.flashcards).get()).single;
      expect(card.entryId, words[0].id);
      expect(card.direction, CardDirection.forward);
      expect(card.state, CardState.learning);
      final events = await db.select(db.reviewEvents).get();
      expect(events.single.entryId, words[0].id);
      await unmountApp(tester);
    });

    testWidgets('editing, search and difficult filter still work in the '
        'deck', (tester) async {
      await openDeck(tester);
      await tester.enterText(find.byKey(const Key('deck.search')), 'Baum');
      await tester.pumpAndSettle();
      expect(find.text('der Baum'), findsOneWidget);
      expect(find.text('das Haus'), findsNothing);
      await tester.tap(find.text('der Baum'));
      await tester.pumpAndSettle();
      // The word page shows everything, including the meaning.
      expect(find.text('درخت'), findsWidgets);
      await unmountApp(tester);
    });
  });

  group('review direction', () {
    testWidgets('Persian → German chosen in settings persists after a '
        'restart and asks the meaning first', (tester) async {
      await pumpApp(tester, db, initialLocation: '/settings', clock: clock);
      expect(find.text('آلمانی ← فارسی'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.reviewDirection')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('reviewDirection.persianToGerman')),
      );
      await tester.pumpAndSettle();
      await unmountApp(tester);

      // "Restart": a new app on the same database.
      await pumpApp(tester, db, initialLocation: '/today', clock: clock);
      expect(find.text('فارسی ← آلمانی'), findsOneWidget);
      await tester.tap(find.byKey(const Key('today.startReview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('practice.meaning')), findsOneWidget);
      expect(find.byKey(const Key('practice.word')), findsNothing);
      expect(find.text('das Haus'), findsNothing);
      await tester.tap(find.byKey(const Key('practice.reveal')));
      await tester.pumpAndSettle();
      expect(find.text('das Haus'), findsOneWidget);
      await scrollAndTap(tester, find.byKey(const Key('practice.forgotten')));
      final card = (await db.select(db.flashcards).get()).single;
      expect(card.direction, CardDirection.reverse);
      await unmountApp(tester);
    });

    testWidgets('Today shows the due count; with nothing due, free practice '
        'is offered', (tester) async {
      await pumpApp(tester, db, initialLocation: '/today', clock: clock);
      expect(find.text('۳ کارت برای مرور'), findsOneWidget);
      await unmountApp(tester);

      await vocab.deleteEntries(words.map((w) => w.id));
      await vocab.createEntry(
        VocabularyDraft(deckId: deck.id, original: 'ohne Bedeutung'),
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/today/practice/session?deckId=${deck.id}',
        clock: clock,
      );
      expect(find.byKey(const Key('practice.nothingDue')), findsOneWidget);
      expect(find.byKey(const Key('practice.freeInstead')), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('selecting and deleting several words', () {
    Finder tile(VocabularyEntry e) => find.byKey(Key('browser.entry.${e.id}'));
    Finder count(String text) => find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.key == const Key('browser.selectedCount') &&
          w.data == text,
    );

    testWidgets('long press selects, taps toggle, select all and clear '
        'work, cancelling deletes nothing, confirming deletes the selection', (
      tester,
    ) async {
      await openDeck(tester);
      expect(find.byKey(const Key('browser.selectionBar')), findsNothing);

      await tester.longPress(tile(words[0]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browser.selectionBar')), findsOneWidget);
      expect(count('۱ انتخاب‌شده'), findsOneWidget);

      // While selecting, a tap toggles instead of opening the word.
      await tester.tap(tile(words[1]));
      await tester.pumpAndSettle();
      expect(count('۲ انتخاب‌شده'), findsOneWidget);
      await tester.tap(tile(words[1]));
      await tester.pumpAndSettle();
      expect(count('۱ انتخاب‌شده'), findsOneWidget);

      await tester.tap(find.byKey(const Key('browser.selectAll')));
      await tester.pumpAndSettle();
      expect(count('۳ انتخاب‌شده'), findsOneWidget);
      await tester.tap(find.byKey(const Key('browser.clearSelection')));
      await tester.pumpAndSettle();
      expect(count('۰ انتخاب‌شده'), findsOneWidget);

      await tester.tap(tile(words[0]));
      await tester.tap(tile(words[2]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('browser.deleteSelected')));
      await tester.pumpAndSettle();
      expect(find.text('۲ لغت حذف شود؟'), findsOneWidget);
      await tester.tap(find.byKey(const Key('browser.deleteCancel')));
      await tester.pumpAndSettle();
      expect(await db.select(db.vocabularyEntries).get(), hasLength(3));
      expect(count('۲ انتخاب‌شده'), findsOneWidget);

      await tester.tap(find.byKey(const Key('browser.deleteSelected')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('browser.deleteConfirm')));
      await tester.pumpAndSettle();
      final left = await db.select(db.vocabularyEntries).get();
      expect(left.map((e) => e.original), ['der Baum']);
      expect(find.text('۲ لغت حذف شد'), findsOneWidget);
      expect(find.byKey(const Key('browser.selectionBar')), findsNothing);
      expect(find.text('das Haus'), findsNothing);
      expect(find.text('der Baum'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('leaving selection mode keeps every word; a normal tap '
        'opens the word again', (tester) async {
      await openDeck(tester);
      await tester.longPress(tile(words[0]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('browser.exitSelection')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browser.selectionBar')), findsNothing);
      expect(await db.select(db.vocabularyEntries).get(), hasLength(3));

      // System back also only leaves selection mode.
      await tester.longPress(tile(words[0]));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browser.selectionBar')), findsNothing);
      expect(find.text('das Haus'), findsOneWidget);

      await tester.tap(tile(words[0]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('browser.selectionBar')), findsNothing);
      expect(find.text('خانه'), findsWidgets);
      await unmountApp(tester);
    });
  });
}
