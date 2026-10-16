import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scan_fakes.dart';
import '../helpers/test_database.dart';

const page =
    'Am Morgen ging sie mit großer Mühe in die Stadt.\n'
    'Dort traf sie ihren alten Freund.';

void main() {
  late AppDatabase db;
  late Deck deck;

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: FixedClock(DateTime.utc(2026, 10, 15)),
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Buch'));
  });
  tearDown(() => db.close());

  Finder wordAt(String word, [int occurrence = 0]) {
    var index = -1;
    for (var i = 0; i <= occurrence; i++) {
      index = page.indexOf(word, index + 1);
    }
    return find.byKey(Key('scan.word.$index'));
  }

  testWidgets('scan, select words and an expression, correct, save', (
    tester,
  ) async {
    final images = FakeScanImageSource();
    await pumpApp(
      tester,
      db,
      initialLocation: '/add',
      imageSource: images,
      recognitionEngine: FakeTextRecognitionEngine(page),
    );

    await tester.tap(find.byKey(const Key('add.scan')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'تشخیص متن ممکن است اشتباه کند؛ پیش از ذخیره، لغت‌ها را بررسی و اصلاح کنید.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('scan.gallery')));
    await tester.pumpAndSettle();
    expect(images.discarded, hasLength(1));

    // German text is laid out left to right inside the RTL app.
    final textList = find.byKey(const Key('scan.text'));
    expect(Directionality.of(tester.element(textList)), TextDirection.ltr);
    expect(find.text('großer'), findsOneWidget);

    await tester.tap(wordAt('ging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عبارت'));
    await tester.pumpAndSettle();
    await tester.tap(wordAt('großer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.notice')), findsOneWidget);
    await tester.tap(wordAt('Mühe'));
    await tester.pumpAndSettle();
    expect(find.text('۲ مورد انتخاب شده'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan.review')));
    await tester.pumpAndSettle();

    // The first item has an offline base-form hint; using it fills the
    // base-form field only.
    expect(find.byKey(const Key('scan.item.1')), findsOneWidget);
    expect(find.text('پیشنهاد شکل پایه: gehen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('scan.item.1.useHint')));
    await tester.pumpAndSettle();

    // Correct the second item (the expression).
    await scrollTo(tester, find.byKey(const Key('scan.item.2.meaning')));
    await tester.enterText(
      find.byKey(const Key('scan.item.2.word')),
      'große Mühe',
    );
    await tester.enterText(
      find.byKey(const Key('scan.item.2.meaning')),
      'زحمت زیاد',
    );
    await tester.pumpAndSettle();

    // Exactly the two selected items will be saved.
    await scrollTo(tester, find.byKey(const Key('scan.save')));
    expect(find.text('ذخیرهٔ ۲ مورد'), findsOneWidget);
    await scrollAndTap(tester, find.byKey(const Key('scan.save')));
    expect(find.byKey(const Key('scan.done')), findsOneWidget);

    final rows = await db.select(db.vocabularyEntries).get();
    expect(
      rows.map((r) => r.original),
      unorderedEquals(['ging', 'große Mühe']),
    );
    final ging = rows.firstWhere((r) => r.original == 'ging');
    expect(ging.lemma, 'gehen');
    expect(ging.sourceType, VocabularySourceType.image);
    expect(
      ging.sourceContext,
      'Am Morgen ging sie mit großer Mühe in die Stadt.',
    );
    expect(ging.deckId, deck.id);

    await tester.tap(find.byKey(const Key('scan.viewDeck')));
    await tester.pumpAndSettle();
    expect(find.text('große Mühe'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('permission denial shows a clear message and nothing is saved', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/add/scan',
      imageSource: FakeScanImageSource(
        error: const ScanException(ScanError.cameraPermissionDenied),
      ),
      recognitionEngine: FakeTextRecognitionEngine(page),
    );
    await tester.tap(find.byKey(const Key('scan.camera')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.error')), findsOneWidget);
    expect(
      find.textContaining('دسترسی به دوربین داده نشده است'),
      findsOneWidget,
    );
    // Alternatives remain available.
    expect(find.byKey(const Key('scan.gallery')), findsOneWidget);
    expect(find.byKey(const Key('scan.typeText')), findsOneWidget);
    expect(await db.select(db.vocabularyEntries).get(), isEmpty);

    await unmountApp(tester);
  });

  testWidgets('no recognized text offers retry and typed fallback', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/decks/${deck.id}/scan',
      imageSource: FakeScanImageSource(),
      recognitionEngine: FakeTextRecognitionEngine('  '),
    );
    await tester.tap(find.byKey(const Key('scan.gallery')));
    await tester.pumpAndSettle();
    expect(find.text('متنی پیدا نشد'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan.typeInstead')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('scan.typedText')),
      'Das Mädchen liest ein Buch.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan.useText')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scan.word.4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan.review')));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.byKey(const Key('scan.save')));

    final row = await db.select(db.vocabularyEntries).getSingle();
    expect(row.original, 'Mädchen');
    expect(row.sourceContext, 'Das Mädchen liest ein Buch.');

    await unmountApp(tester);
  });

  testWidgets('a word already in the deck is marked and not saved again', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/decks/${deck.id}/scan',
      imageSource: FakeScanImageSource(),
      recognitionEngine: FakeTextRecognitionEngine(page),
    );
    // First scan saves "Stadt".
    await tester.tap(find.byKey(const Key('scan.gallery')));
    await tester.pumpAndSettle();
    await tester.tap(wordAt('Stadt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan.review')));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.byKey(const Key('scan.save')));
    await tester.tap(find.byKey(const Key('scan.another')));
    await tester.pumpAndSettle();

    // Second scan of the same word.
    await tester.tap(find.byKey(const Key('scan.gallery')));
    await tester.pumpAndSettle();
    await tester.tap(wordAt('Stadt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan.review')));
    await tester.pumpAndSettle();
    expect(find.text('در این دسته وجود دارد — ذخیره نمی‌شود'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('scan.save')));
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('scan.save'))).onPressed,
      isNull,
    );
    expect(await db.select(db.vocabularyEntries).get(), hasLength(1));

    await unmountApp(tester);
  });
}
