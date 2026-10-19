import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/scan/domain/image_fit.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scan_fakes.dart';
import '../helpers/test_database.dart';

const page =
    'Am Morgen ging sie mit großer Mühe in die Stadt.\n'
    'Dort traf sie ihren alten Freund.\n\n'
    'Er gab sich Mühe und lernte das Wörterbuch.\n\n'
    'Übermorgen fährt sie über die Straße.';

void main() {
  late AppDatabase db;
  late Deck deck;
  late FakeScanImageSource images;
  late FakeTextRecognitionEngine engine;
  late FakeImageCropper cropper;

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: FixedClock(DateTime.utc(2026, 10, 15)),
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Buch'));
    images = FakeScanImageSource();
    engine = FakeTextRecognitionEngine(page, layout: true);
    cropper = FakeImageCropper();
  });
  tearDown(() => db.close());

  Future<void> openPhoto(WidgetTester tester) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/add/scan?deckId=${deck.id}',
      imageSource: images,
      recognitionEngine: engine,
      imageCropper: cropper,
    );
    await tester.tap(find.byKey(const Key('scan.camera')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.page')), findsOneWidget);
  }

  /// Where [word]'s box centre is on screen, including the viewer's current
  /// zoom and pan.
  Offset screenPointOf(WidgetTester tester, String word, [int occurrence = 0]) {
    final viewer = tester.getRect(find.byKey(const Key('scan.page')));
    final fit = ImageFit.contain(fakePageSize, viewer.size);
    final matrix = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value;
    final inViewer = MatrixUtils.transformPoint(
      matrix,
      fit.toView(fakeBoxOf(page, word, occurrence: occurrence).center),
    );
    return viewer.topLeft + inViewer;
  }

  Future<void> tapWord(WidgetTester tester, String word, [int i = 0]) async {
    await tester.tapAt(screenPointOf(tester, word, i));
    await tester.pumpAndSettle();
  }

  /// Selected items, as shown in the compact chip list.
  int selected(WidgetTester tester) => find.byType(InputChip).evaluate().length;

  Finder field(String text) => find.byWidgetPredicate(
    (w) => w is EditableText && w.controller.text == text,
  );

  testWidgets('tap three words in different paragraphs; only those reach '
      'the confirmation screen and the deck', (tester) async {
    await openPhoto(tester);
    await tapWord(tester, 'ging');
    await tapWord(tester, 'Wörterbuch.');
    await tapWord(tester, 'Straße.');
    expect(selected(tester), 3);
    // Compact list of the selection, in reading order.
    for (final w in ['ging', 'Wörterbuch', 'Straße']) {
      expect(
        find.descendant(
          of: find.byKey(const Key('scan.selectedList')),
          matching: find.text(w),
        ),
        findsOneWidget,
      );
    }
    // Deselect and reselect one.
    await tapWord(tester, 'ging');
    expect(selected(tester), 2);
    await tapWord(tester, 'ging');

    await tester.tap(find.byKey(const Key('scan.review')));
    await tester.pumpAndSettle();
    for (final w in ['ging', 'Wörterbuch', 'Straße']) {
      await scrollTo(tester, field(w));
      expect(field(w), findsOneWidget);
    }
    // Unselected words never appear as items.
    expect(field('Morgen'), findsNothing);
    expect(field('traf'), findsNothing);

    await scrollAndTap(tester, find.byKey(const Key('scan.save')));
    final saved = await db.select(db.vocabularyEntries).get();
    expect(
      saved.map((e) => e.original),
      unorderedEquals(['ging', 'Wörterbuch', 'Straße']),
    );
    await unmountApp(tester);
  });

  testWidgets('after zooming, word boxes stay aligned: a tap at the '
      'zoomed position selects that word', (tester) async {
    await openPhoto(tester);
    final viewer = tester.getRect(find.byKey(const Key('scan.page')));
    // Pinch around the second paragraph.
    final center = screenPointOf(tester, 'lernte');
    final a = await tester.startGesture(center - const Offset(30, 0));
    final b = await tester.startGesture(center + const Offset(30, 0));
    await tester.pump();
    for (var i = 1; i <= 5; i++) {
      await a.moveTo(center - Offset(30.0 + 10 * i, 0));
      await b.moveTo(center + Offset(30.0 + 10 * i, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    final scale = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale, greaterThan(1.5));
    expect(selected(tester), 0, reason: 'zooming selects nothing');

    // Pick a word that is still on screen after zooming in.
    final words = [
      for (final block in fakePageLayout(page))
        for (final line in block)
          for (final e in line.elements) e.text,
    ];
    final visible = words.firstWhere(
      (w) => viewer.deflate(8).contains(screenPointOf(tester, w)),
    );
    final unzoomedFit = ImageFit.contain(fakePageSize, viewer.size);
    final unzoomed =
        viewer.topLeft + unzoomedFit.toView(fakeBoxOf(page, visible).center);
    expect(
      (unzoomed - screenPointOf(tester, visible)).distance,
      greaterThan(20),
      reason: 'the zoomed position differs from the unzoomed one',
    );
    await tester.tapAt(screenPointOf(tester, visible));
    await tester.pumpAndSettle();
    final display = visible.replaceAll(RegExp(r'[.,]$'), '');
    expect(
      find.descendant(
        of: find.byKey(const Key('scan.selectedList')),
        matching: find.text(display),
      ),
      findsOneWidget,
    );
    expect(selected(tester), 1);
    await unmountApp(tester);
  });

  testWidgets('touch, hold and drag selects an expression; a plain drag '
      'only moves the page', (tester) async {
    await openPhoto(tester);
    final drag = await tester.startGesture(screenPointOf(tester, 'Dort'));
    await tester.pump(const Duration(milliseconds: 50));
    await drag.moveTo(screenPointOf(tester, 'Dort') + const Offset(40, 0));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();
    expect(selected(tester), 0);

    final hold = await tester.startGesture(screenPointOf(tester, 'Dort'));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await hold.moveTo(screenPointOf(tester, 'traf'));
    await tester.pump();
    await hold.moveTo(screenPointOf(tester, 'ihren'));
    await tester.pump();
    await hold.up();
    await tester.pumpAndSettle();
    expect(selected(tester), 1);
    expect(find.text('Dort traf sie ihren'), findsOneWidget);

    // The expression can be split into single words.
    await tester.tap(find.text('Dort traf sie ihren'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan.splitWords')));
    await tester.pumpAndSettle();
    expect(selected(tester), 4);
    await unmountApp(tester);
  });

  testWidgets('drawn area: the matching photo region is read again and the '
      'corrected text is added', (tester) async {
    engine.regionText = 'Wörtcrbuch';
    await openPhoto(tester);
    await tester.tap(find.byKey(const Key('scan.regionMode')));
    await tester.pumpAndSettle();

    final box = fakeBoxOf(page, 'Wörterbuch.');
    final viewer = tester.getRect(find.byKey(const Key('scan.page')));
    final fit = ImageFit.contain(fakePageSize, viewer.size);
    final from =
        viewer.topLeft + fit.toView(box.topLeft - const Offset(10, 10));
    final to =
        viewer.topLeft + fit.toView(box.bottomRight + const Offset(10, 10));
    final gesture = await tester.startGesture(from);
    await tester.pump();
    for (var i = 1; i <= 4; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 4)!);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final (photo, region) = cropper.crops.single;
    expect(photo, fakePhoto);
    final expected = box.inflate(10);
    // Within a pixel of the drawn box, despite screen rounding.
    expect(region.left, closeTo(expected.left, 4));
    expect(region.top, closeTo(expected.top, 4));
    expect(region.right, closeTo(expected.right, 4));
    expect(region.bottom, closeTo(expected.bottom, 4));

    // Correct the OCR mistake, then add.
    expect(find.byKey(const Key('scan.regionText')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('scan.regionText')),
      'Wörterbuch',
    );
    await tester.tap(find.byKey(const Key('scan.regionAdd')));
    await tester.pumpAndSettle();
    expect(selected(tester), 1);
    expect(find.text('Wörterbuch'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('photo and text views can be switched; the selection is '
      'shared', (tester) async {
    await openPhoto(tester);
    await tapWord(tester, 'ging');
    await tester.tap(find.byKey(const Key('scan.toggleView')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.text')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('scan.selectedCount'))).data,
      contains('۱'),
    );
    await tester.tap(find.byKey(const Key('scan.toggleView')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.page')), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('photo view fits at 320 px with 2x text', (tester) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/add/scan?deckId=${deck.id}',
      imageSource: images,
      recognitionEngine: engine,
      imageCropper: cropper,
      size: const Size(320, 640),
      textScale: 2,
    );
    await scrollAndTap(tester, find.byKey(const Key('scan.camera')));
    await tapWord(tester, 'ging');
    await tapWord(tester, 'Stadt.');
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });
}
