import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/csv_import/data/csv_file_source.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  late DriftVocabularyRepository vocab;
  final clock = FixedClock(DateTime.utc(2026, 10, 15, 7));

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'A1'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('seed'),
    );
  });
  tearDown(() => db.close());

  FakeCsvFileSource source(String fixture) => FakeCsvFileSource(
    PickedCsvFile(name: fixture, bytes: csvFixture(fixture)),
  );

  testWidgets('previews, requires confirmation and imports', (tester) async {
    await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'Haus',
        meanings: const [VocabularyMeaning('خانه')],
      ),
    );
    await pumpApp(
      tester,
      db,
      initialLocation: '/add',
      fileSource: source('duplicates.csv'),
    );

    await tester.tap(find.byKey(const Key('add.csv')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('csv.pickFile')));
    await tester.pumpAndSettle();

    expect(find.text('duplicates.csv'), findsOneWidget);
    // Skip strategy (default): Bank + Schloss new, 4 duplicates.
    await tester.scrollUntilVisible(
      find.byKey(const Key('csv.count.new')),
      200,
      scrollable: visibleScrollable(),
    );
    expect(find.text('۲ جدید'), findsOneWidget);
    expect(find.text('۴ تکراری'), findsOneWidget);

    // Nothing can be imported before the languages are confirmed.
    await tester.scrollUntilVisible(
      find.byKey(const Key('csv.import')),
      200,
      scrollable: visibleScrollable(),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('csv.import')))
          .onPressed,
      isNull,
    );

    // Choose "add new meanings" and confirm languages.
    await scrollAndTap(
      tester,
      find.byKey(const Key('csv.strategy.mergeMeanings')),
    );
    await scrollAndTap(tester, find.byKey(const Key('csv.confirmLanguages')));
    await scrollAndTap(tester, find.byKey(const Key('csv.import')));

    expect(find.byKey(const Key('csv.result')), findsOneWidget);
    final entries = {
      for (final e in await vocab.getEntries(deck.id)) e.original: e,
    };
    expect(entries.keys, unorderedEquals(['Haus', 'Bank', 'Schloss']));
    expect(entries['Bank']!.meanings.map((m) => m.text), ['بانک', 'نیمکت']);
    expect(entries['Schloss']!.meanings.map((m) => m.text), ['قلعه', 'قفل']);
    expect(entries['Bank']!.sourceType, VocabularySourceType.csv);

    await tester.tap(find.byKey(const Key('csv.viewDeck')));
    await tester.pumpAndSettle();
    expect(find.text('Schloss'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('shows row errors and imports only valid rows', (tester) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/decks/${deck.id}/import',
      fileSource: source('malformed_rows.csv'),
    );
    await tester.tap(find.byKey(const Key('csv.pickFile')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('csv.error.3')),
      200,
      scrollable: visibleScrollable(),
    );
    expect(find.textContaining('لغت آلمانی خالی است'), findsOneWidget);

    await scrollAndTap(tester, find.byKey(const Key('csv.confirmLanguages')));
    await scrollAndTap(tester, find.byKey(const Key('csv.import')));
    expect(find.text('۲ ردیف به دلیل خطا وارد نشد'), findsOneWidget);
    expect(
      (await vocab.getEntries(deck.id)).map((e) => e.original),
      unorderedEquals(['gut', 'kurz', 'lang', 'schnell']),
    );

    await unmountApp(tester);
  });

  testWidgets('a broken file shows an error and imports nothing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/add/csv',
      fileSource: source('unterminated_quote.csv'),
    );
    await tester.tap(find.byKey(const Key('csv.pickFile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('csv.fileError')), findsOneWidget);
    expect(find.text('علامت نقل‌قول در خط ۳ بسته نشده است.'), findsOneWidget);
    expect(find.byKey(const Key('csv.import')), findsNothing);
    expect(await db.select(db.vocabularyEntries).get(), isEmpty);

    await unmountApp(tester);
  });
}
