import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/domain/review_direction.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  final clock = FixedClock(DateTime.utc(2026, 10, 19, 8));
  const nachbar = 'Der Nachbar\nDie Nachbarin';

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Kafka'));
  });
  tearDown(() => db.close());

  Future<void> addWord(String word, String meaning) async =>
      DriftVocabularyRepository(
        db,
        clock: clock,
        ids: SequentialIdGenerator('seed-$word'),
      ).createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: word,
          meanings: [VocabularyMeaning(meaning)],
        ),
      );

  Future<void> useDirection(ReviewDirection direction) => db
      .into(db.appSettings)
      .insert(
        AppSettingsCompanion.insert(
          key: ReviewDirection.settingsKey,
          value: direction.name,
        ),
      );

  Finder wordText() => find.descendant(
    of: find.byKey(const Key('practice.word')),
    matching: find.byType(Text),
  );

  // Wide enough that no line wraps in the test font (every glyph is as wide
  // as the font size), so heights show the entered line breaks only.
  const wide = Size(1000, 844);

  Future<void> openPractice(
    WidgetTester tester, {
    Size size = wide,
    double textScale = 1,
  }) => pumpApp(
    tester,
    db,
    initialLocation: '/today/practice/session?free=1',
    clock: clock,
    size: size,
    textScale: textScale,
  );

  testWidgets('a word entered on two lines is saved with its line break and '
      'shown on two lines on the question side', (tester) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/decks/${deck.id}/entries/new',
      clock: clock,
    );
    await tester.enterText(find.byKey(const Key('entryForm.word')), nachbar);
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.0')),
      'همسایه',
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.save')));
    final row = (await db.select(db.vocabularyEntries).get()).single;
    expect(row.original, nachbar);
    await unmountApp(tester);

    await openPractice(tester);
    final text = tester.widget<Text>(wordText());
    expect(text.data, nachbar);
    expect(text.textDirection, TextDirection.ltr);
    // Exactly two lines of the multi-line headword (24 px × 1.35).
    final height = tester.getSize(wordText()).height;
    expect(height, closeTo(2 * 24 * 1.35, 4));

    // Editing from the card shows and keeps the line break.
    await scrollAndTap(tester, find.byKey(const Key('practice.reveal')));
    await scrollAndTap(tester, find.byKey(const Key('practice.edit')));
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('entryForm.word')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      nachbar,
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.save')));
    expect(
      (await db.select(db.vocabularyEntries).get()).single.original,
      nachbar,
    );
    await scrollTo(tester, wordText());
    expect(tester.widget<Text>(wordText()).data, nachbar);
    await unmountApp(tester);
  });

  testWidgets('the line break is kept on the answer side (Persian → German)', (
    tester,
  ) async {
    await addWord(nachbar, 'همسایه');
    await useDirection(ReviewDirection.persianToGerman);
    await openPractice(tester);
    expect(wordText(), findsNothing);
    await scrollAndTap(tester, find.byKey(const Key('practice.reveal')));
    expect(tester.widget<Text>(wordText()).data, nachbar);
    expect(tester.getSize(wordText()).height, closeTo(2 * 24 * 1.35, 4));
    await unmountApp(tester);
  });

  testWidgets('a single-line word stays on one line, unchanged', (
    tester,
  ) async {
    await addWord('das Haus', 'خانه');
    await openPractice(tester);
    expect(tester.widget<Text>(wordText()).data, 'das Haus');
    expect(tester.getSize(wordText()).height, closeTo(30 * 1.25, 4));
    await unmountApp(tester);
  });

  testWidgets('multi-line and long words fit at 320 px with 2x text', (
    tester,
  ) async {
    await addWord(
      'Der Nachbar\nDie Nachbarin\nDonaudampfschifffahrtsgesellschaftskapitän',
      'همسایه',
    );
    await openPractice(tester, size: const Size(320, 640), textScale: 2);
    expect(tester.takeException(), isNull);
    await scrollAndTap(tester, find.byKey(const Key('practice.reveal')));
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });
}
