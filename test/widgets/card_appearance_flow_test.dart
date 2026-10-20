import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/card_appearance/data/drift_card_appearance_repository.dart';
import 'package:ai_wortbox/features/card_appearance/domain/card_appearance.dart';
import 'package:ai_wortbox/features/card_appearance/presentation/card_style.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/learning_data.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SeededIds ids;

  setUp(() async {
    db = openTestDatabase();
    ids = await seedLearningData(db);
  });
  tearDown(() => db.close());

  DriftCardAppearanceRepository repo() =>
      DriftCardAppearanceRepository(db, clock: FixedClock(DateTime.utc(2026)));

  String detail(String entryId) => '/words/decks/${ids.deck}/entries/$entryId';

  Future<void> openEditor(WidgetTester tester, String entryId) async {
    await pumpApp(tester, db, initialLocation: detail(entryId));
    await tester.tap(find.byKey(const Key('entryDetail.appearance')));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) =>
      scrollAndTap(tester, find.byKey(Key(key)));

  Card previewCardNow(WidgetTester tester) => tester.widget<Card>(
    find
        .descendant(
          of: find.byKey(const Key('appearance.preview')),
          matching: find.byType(Card),
        )
        .first,
  );

  Future<Card> previewCard(WidgetTester tester) async {
    await scrollTo(tester, find.byKey(const Key('appearance.preview')));
    return previewCardNow(tester);
  }

  testWidgets('style a card with a live preview, save, and see it on the '
      'word page; words, FSRS and history are unchanged', (tester) async {
    final before = await dumpLearningData(db);
    await openEditor(tester, ids.gehen);

    expect((await previewCard(tester)).color, isNull, reason: 'standard look');
    await tapKey(tester, 'appearance.bg.sky');
    expect((await previewCard(tester)).color, const Color(0xFFDCEBFB));
    await tapKey(tester, 'appearance.ink.green');
    await tapKey(tester, 'appearance.token.0');
    await tapKey(tester, 'appearance.meaning.0');
    await tapKey(tester, 'appearance.sticker.bulb');
    await scrollTo(tester, find.byKey(const Key('appearance.preview')));
    expect(
      find.descendant(
        of: find.byKey(const Key('appearance.preview')),
        matching: find.text('💡'),
      ),
      findsOneWidget,
    );
    // Nothing is stored before "Save".
    expect(await repo().get(ids.gehen), CardAppearance.standard);

    await tester.tap(find.byKey(const Key('appearance.save')));
    await tester.pumpAndSettle();

    final saved = await repo().get(ids.gehen);
    expect(saved.background, CardColor.sky);
    expect(saved.ink, CardInk.green);
    expect(saved.sticker, CardSticker.bulb);
    expect(saved.isHighlighted(HighlightField.word, 'gehen'), isTrue);
    expect(saved.isHighlighted(HighlightField.meaning, 'رفتن'), isTrue);

    // Back on the word page, in the new look.
    expect(find.byKey(const Key('entryDetail.word')), findsOneWidget);
    final card = tester.widget<Card>(
      find
          .descendant(
            of: find.byKey(const Key('entryDetail.card')),
            matching: find.byType(Card),
          )
          .first,
    );
    expect(card.color, const Color(0xFFDCEBFB));
    expect(find.byKey(const Key('card.sticker')), findsOneWidget);

    final after = await dumpLearningData(db);
    for (final table in before.keys) {
      if (table == 'card_appearances') continue;
      expect(after[table], before[table], reason: table);
    }
  });

  testWidgets('text size changes the word and the meanings independently', (
    tester,
  ) async {
    await openEditor(tester, ids.gehen);
    Future<double> sizeOf(Key key) async {
      await scrollTo(tester, find.byKey(const Key('appearance.preview')));
      final text = tester.widget<Text>(
        find
            .descendant(
              of: find.byKey(const Key('appearance.preview')),
              matching: find.byWidgetPredicate(
                (w) => w is Text && w.textSpan != null,
              ),
            )
            .at(key == const Key('word') ? 0 : 1),
      );
      return text.style!.fontSize!;
    }

    final word = await sizeOf(const Key('word'));
    final meaning = await sizeOf(const Key('meaning'));
    final slider = find.byKey(const Key('appearance.wordSize'));
    await scrollTo(tester, slider);
    await tester.drag(slider, const Offset(400, 0));
    await tester.pumpAndSettle();
    // RTL: dragging right lowers the value.
    final changed = await sizeOf(const Key('word'));
    expect(changed, isNot(word));
    expect(await sizeOf(const Key('meaning')), meaning);
  });

  testWidgets('cancel with changes asks first and saves nothing', (
    tester,
  ) async {
    await openEditor(tester, ids.gehen);
    await tapKey(tester, 'appearance.bg.rose');
    await tester.tap(find.byKey(const Key('appearance.cancel')));
    await tester.pumpAndSettle();
    expect(find.text('تغییرات کنار گذاشته شود؟'), findsOneWidget);
    await tester.tap(find.byKey(const Key('appearance.discard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entryDetail.word')), findsOneWidget);
    expect(await repo().get(ids.gehen), CardAppearance.standard);
  });

  testWidgets('reset returns to the standard look without touching the '
      'word', (tester) async {
    final word = await db.select(db.vocabularyEntries).get();
    await openEditor(tester, ids.haus);
    expect((await previewCard(tester)).color, const Color(0xFFDDF3EA));
    await tester.tap(find.byKey(const Key('appearance.reset')));
    await tester.pumpAndSettle();
    expect((await previewCard(tester)).color, isNull);
    await tester.tap(find.byKey(const Key('appearance.save')));
    await tester.pumpAndSettle();
    expect(await db.select(db.cardAppearances).get(), isEmpty);
    expect(await db.select(db.vocabularyEntries).get(), word);
  });

  testWidgets('the review card shows the appearance and offers the editor; '
      'opening it records nothing and changes no schedule', (tester) async {
    final one = openTestDatabase();
    addTearDown(one.close);
    final clock = FixedClock(DateTime.utc(2026, 10, 15, 8));
    final ids = SequentialIdGenerator('one');
    final deck = await DriftDeckRepository(
      one,
      clock: clock,
      ids: ids,
    ).createDeck(const DeckDraft(name: 'Eins'));
    final word = await DriftVocabularyRepository(one, clock: clock, ids: ids)
        .createEntry(
          VocabularyDraft(
            deckId: deck.id,
            original: 'Haus',
            meanings: const [VocabularyMeaning('خانه')],
          ).cleaned(),
        );
    await DriftCardAppearanceRepository(one, clock: clock).save(
      word.id,
      const CardAppearance(
        background: CardColor.sun,
        sticker: CardSticker.fire,
      ),
    );
    await pumpApp(tester, one, initialLocation: '/today/practice/session');

    final prompt = tester.widget<Card>(
      find
          .descendant(
            of: find.byKey(const Key('practice.prompt')),
            matching: find.byType(Card),
          )
          .first,
    );
    expect(prompt.color, const Color(0xFFFFF3C4));
    expect(find.text('🔥'), findsOneWidget);

    await scrollAndTap(tester, find.byKey(const Key('practice.reveal')));
    await scrollAndTap(tester, find.byKey(const Key('practice.appearance')));
    expect(find.byKey(const Key('appearance.preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appearance.cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practice.answer')), findsOneWidget);
    expect(await one.select(one.flashcards).get(), isEmpty);
    expect(await one.select(one.reviewEvents).get(), isEmpty);
  });

  testWidgets('large sizes and long mixed text wrap without overflow, RTL '
      'and LTR kept', (tester) async {
    final clock = FixedClock(DateTime.utc(2026, 10, 15, 8));
    final deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('long'),
    ).createDeck(const DeckDraft(name: 'Lang'));
    final long =
        await DriftVocabularyRepository(
          db,
          clock: clock,
          ids: SequentialIdGenerator('long'),
        ).createEntry(
          VocabularyDraft(
            deckId: deck.id,
            original:
                'Donaudampfschifffahrtsgesellschaftskapitänsmütze\n'
                'sich über etwas Gedanken machen',
            meanings: const [
              VocabularyMeaning(
                'کلاهِ ناخدای شرکت کشتیرانی بخار رود دانوب که بسیار طولانی است',
              ),
            ],
          ).cleaned(),
        );
    await repo().save(
      long.id,
      CardAppearance(
        wordScale: 1.6,
        meaningScale: 1.6,
        highlights: {const CardHighlight(HighlightField.word, 'Gedanken')},
        sticker: CardSticker.books,
      ),
    );
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/decks/${deck.id}/entries/${long.id}',
      size: const Size(320, 640),
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    final word = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('entryDetail.word')),
        matching: find.byType(Text),
      ),
    );
    expect(word.textDirection, TextDirection.ltr);
    expect(word.textSpan!.toPlainText(), contains('\n'));
    final highlighted = (word.textSpan! as TextSpan).children!
        .whereType<TextSpan>()
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text);
    expect(highlighted, ['Gedanken']);

    await tester.tap(find.byKey(const Key('entryDetail.appearance')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English layout is left-to-right', (tester) async {
    await pumpApp(
      tester,
      db,
      initialLocation: detail(ids.gehen),
      locale: const Locale('en'),
    );
    await tester.tap(find.byKey(const Key('entryDetail.appearance')));
    await tester.pumpAndSettle();
    expect(find.text('Card appearance'), findsWidgets);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('appearance.preview'))),
      ),
      TextDirection.ltr,
    );
    expect(find.byType(AppearanceCardFrame), findsNWidgets(2));
  });
}
