import 'package:ai_wortbox/core/id/id_generator.dart';
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
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  final clock = FixedClock(DateTime.utc(2026, 10, 15, 7));

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'A1'));
  });
  tearDown(() => db.close());

  DriftVocabularyRepository vocab() => DriftVocabularyRepository(
    db,
    clock: clock,
    ids: SequentialIdGenerator('seed'),
  );

  testWidgets('add, view, edit and delete a word', (tester) async {
    await pumpApp(tester, db, initialLocation: '/words/decks/${deck.id}');
    expect(find.text('این دسته هنوز لغتی ندارد'), findsOneWidget);

    // Add.
    await tester.tap(find.byKey(const Key('deck.addWord')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entryForm.save')));
    await tester.pumpAndSettle();
    expect(find.text('لغت آلمانی را وارد کنید.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('entryForm.word')), 'Bank');
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.0')),
      'بانک',
    );
    await tester.tap(find.byKey(const Key('entryForm.addMeaning')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.1')),
      'نیمکت',
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.details')));
    await tester.enterText(
      find.byKey(const Key('entryForm.example')),
      'Er sitzt auf der Bank.',
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.save')));

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('بانک، نیمکت'), findsOneWidget);

    // German input fields are left-to-right inside the RTL UI.
    final entries = await db.select(db.vocabularyEntries).get();
    expect(entries.single.original, 'Bank');
    final entryId = entries.single.id;

    // Review state that must survive the edit.
    await db
        .into(db.flashcards)
        .insert(
          FlashcardsCompanion.insert(
            id: 'card',
            entryId: entryId,
            direction: CardDirection.forward,
            state: CardState.review,
            due: DateTime.utc(2026, 10, 20),
            createdAt: DateTime.utc(2026, 10, 15),
            updatedAt: DateTime.utc(2026, 10, 15),
          ),
        );
    final cardBefore = await db.select(db.flashcards).getSingle();

    // View.
    await tester.tap(find.text('Bank'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('entryDetail.word')), findsOneWidget);
    expect(find.text('Er sitzt auf der Bank.'), findsOneWidget);
    expect(find.text('نیمکت'), findsOneWidget);
    final wordText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('entryDetail.word')),
        matching: find.byType(Text),
      ),
    );
    expect(wordText.textDirection, TextDirection.ltr);

    // Edit.
    await tester.tap(find.byKey(const Key('entryDetail.edit')));
    await tester.pumpAndSettle();
    final wordField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('entryForm.word')),
        matching: find.byType(EditableText),
      ),
    );
    expect(wordField.textDirection, TextDirection.ltr);
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.1')),
      'نیمکت پارک',
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.save')));
    expect(find.text('نیمکت پارک'), findsOneWidget);
    expect(await db.select(db.flashcards).getSingle(), cardBefore);

    // Delete.
    await tester.tap(find.byKey(const Key('entryDetail.delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entryDetail.confirmDelete')));
    await tester.pumpAndSettle();
    expect(find.text('این دسته هنوز لغتی ندارد'), findsOneWidget);
    expect(await db.select(db.vocabularyEntries).get(), isEmpty);
    expect(await db.select(db.flashcards).get(), isEmpty);

    await unmountApp(tester);
  });

  testWidgets('duplicate words ask before saving and never merge silently', (
    tester,
  ) async {
    await vocab().createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'Haus',
        meanings: const [VocabularyMeaning('خانه')],
      ),
    );
    await pumpApp(tester, db, initialLocation: '/add/manual');

    // Same word, same meaning: offers to open the existing word.
    await tester.enterText(find.byKey(const Key('entryForm.word')), 'haus');
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.0')),
      'خانه',
    );
    await tester.tap(find.byKey(const Key('entryForm.save')));
    await tester.pumpAndSettle();
    expect(find.text('این لغت قبلاً ذخیره شده'), findsOneWidget);
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(await db.select(db.vocabularyEntries).get(), hasLength(1));

    // Same word, new meaning: explicit choice to add the meaning.
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.0')),
      'منزل',
    );
    await tester.tap(find.byKey(const Key('entryForm.save')));
    await tester.pumpAndSettle();
    expect(find.text('این لغت با معنی دیگری وجود دارد'), findsOneWidget);
    await tester.tap(find.text('افزودن معنی‌ها به لغت موجود'));
    await tester.pumpAndSettle();

    final entries = await vocab().getEntries(deck.id);
    expect(entries, hasLength(1));
    expect(entries.single.original, 'Haus');
    expect(entries.single.meanings.map((m) => m.text), ['خانه', 'منزل']);

    await unmountApp(tester);
  });

  testWidgets('"save and add next" keeps the form open', (tester) async {
    await pumpApp(tester, db, initialLocation: '/add/manual');
    for (final (word, meaning) in [('Apfel', 'سیب'), ('Birne', 'گلابی')]) {
      await tester.enterText(find.byKey(const Key('entryForm.word')), word);
      await tester.enterText(
        find.byKey(const Key('entryForm.meaning.0')),
        meaning,
      );
      await tester.tap(find.byKey(const Key('entryForm.saveAndNext')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('entryForm.word')), findsOneWidget);
    final entries = await vocab().getEntries(deck.id);
    expect(entries.map((e) => e.original), unorderedEquals(['Apfel', 'Birne']));
    expect(
      entries.every((e) => e.sourceType == VocabularySourceType.manual),
      isTrue,
    );

    await unmountApp(tester);
  });

  testWidgets('search filters by German word and Persian meaning', (
    tester,
  ) async {
    final repository = vocab();
    for (final (word, meaning) in [('Haus', 'خانه'), ('Baum', 'درخت')]) {
      await repository.createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: word,
          meanings: [VocabularyMeaning(meaning)],
        ),
      );
    }
    await pumpApp(tester, db, initialLocation: '/words/decks/${deck.id}');

    await tester.enterText(find.byKey(const Key('deck.search')), 'درخت');
    await tester.pumpAndSettle();
    expect(find.text('Baum'), findsOneWidget);
    expect(find.text('Haus'), findsNothing);

    await tester.enterText(find.byKey(const Key('deck.search')), 'HAU');
    await tester.pumpAndSettle();
    expect(find.text('Haus'), findsOneWidget);
    expect(find.text('Baum'), findsNothing);

    await unmountApp(tester);
  });
}
