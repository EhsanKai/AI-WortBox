import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/scan/domain/image_fit.dart';
import 'package:ai_wortbox/features/scan/presentation/scan_controller.dart';
import 'package:ai_wortbox/features/scan/presentation/scan_review_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late Deck other;
  late FakeScanImageSource images;
  late FakeTextRecognitionEngine engine;
  late FakeImageCropper cropper;

  setUp(() async {
    db = openTestDatabase();
    final decks = DriftDeckRepository(
      db,
      clock: FixedClock(DateTime.utc(2026, 10, 15)),
      ids: SequentialIdGenerator('deck'),
    );
    deck = await decks.createDeck(const DeckDraft(name: 'Buch'));
    other = await decks.createDeck(const DeckDraft(name: 'Reise'));
    images = FakeScanImageSource();
    engine = FakeTextRecognitionEngine(page, layout: true);
    cropper = FakeImageCropper();
  });
  tearDown(() => db.close());

  Future<void> openPhoto(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/add/scan?deckId=${deck.id}',
      imageSource: images,
      recognitionEngine: engine,
      imageCropper: cropper,
      size: size,
      textScale: textScale,
    );
    await scrollAndTap(tester, find.byKey(const Key('scan.camera')));
    expect(find.byKey(const Key('scan.page')), findsOneWidget);
  }

  Rect viewer(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('scan.page')));

  /// Where photo pixel [p] is on screen, with the current zoom and pan.
  Offset onScreen(WidgetTester tester, Offset p) {
    final rect = viewer(tester);
    final fit = ImageFit.contain(fakePageSize, rect.size);
    final matrix = tester
        .widget<InteractiveViewer>(find.byKey(const Key('scan.page')))
        .transformationController!
        .value;
    return rect.topLeft + MatrixUtils.transformPoint(matrix, fit.toView(p));
  }

  /// Draws with one finger along [word]'s line, inside the word.
  Future<void> drawOver(
    WidgetTester tester,
    String word, {
    int occurrence = 0,
    String? to,
  }) async {
    final box = fakeBoxOf(page, word, occurrence: occurrence);
    final end = to == null ? box : fakeBoxOf(page, to);
    final from = onScreen(tester, box.centerLeft + const Offset(4, 0));
    final until = onScreen(tester, end.centerRight - const Offset(4, 0));
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= 6; i++) {
      await gesture.moveTo(Offset.lerp(from, until, i / 6)!);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  int regionChips(WidgetTester tester) => find
      .byWidgetPredicate(
        (w) => w is InputChip && '${w.key}'.contains('scan.region.'),
      )
      .evaluate()
      .length;

  int strokeChips(WidgetTester tester) => find
      .byWidgetPredicate(
        (w) => w is InputChip && '${w.key}'.contains('scan.stroke.'),
      )
      .evaluate()
      .length;

  /// The review screen's German word field showing [text].
  Finder field(String text) => find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        '${w.key}'.endsWith(".word'>]") &&
        w.controller!.text == text,
  );

  Future<void> pinch(WidgetTester tester, Offset center) async {
    final a = await tester.startGesture(center - const Offset(30, 0));
    final b = await tester.startGesture(center + const Offset(30, 0));
    await tester.pump();
    for (var i = 1; i <= 5; i++) {
      await a.moveTo(center - Offset(30.0 + 12 * i, 0));
      await b.moveTo(center + Offset(30.0 + 12 * i, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
  }

  double zoomOf(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byKey(const Key('scan.page')))
      .transformationController!
      .value
      .getMaxScaleOnAxis();

  testWidgets('the photo is shown as is and nothing is read; drawn and '
      'tapped highlights are listed, undone and cleared', (tester) async {
    await openPhoto(tester);
    expect(find.byKey(const Key('scan.pageImage')), findsOneWidget);
    // The photo keeps its aspect ratio inside the viewer.
    final shown = tester.getRect(find.byKey(const Key('scan.pageImage')));
    expect(
      shown.width / shown.height,
      closeTo(fakePageSize.width / fakePageSize.height, 0.01),
    );
    expect(engine.calls, 0);
    expect(find.byKey(const Key('scan.text')), findsNothing);

    await drawOver(tester, 'ging');
    expect(strokeChips(tester), 1);
    await tester.tapAt(onScreen(tester, fakeBoxOf(page, 'Stadt.').center));
    await tester.pumpAndSettle();
    expect(strokeChips(tester), 2);
    await drawOver(tester, 'Freund.');
    expect(strokeChips(tester), 3);

    await tester.tap(find.byKey(const Key('scan.undo')));
    await tester.pumpAndSettle();
    expect(strokeChips(tester), 2);
    await tester.tap(find.byTooltip('حذف از انتخاب').first);
    await tester.pumpAndSettle();
    expect(strokeChips(tester), 1);
    await tester.tap(find.byKey(const Key('scan.clearHighlights')));
    await tester.pumpAndSettle();
    expect(strokeChips(tester), 0);
    expect(engine.calls, 0);
    await unmountApp(tester);
  });

  testWidgets('highlight three words in different paragraphs; only those '
      'regions are read; correct, choose the deck, save; still there after '
      'a restart', (tester) async {
    await openPhoto(tester);
    await drawOver(tester, 'ging');
    await drawOver(tester, 'Wörterbuch.');
    await drawOver(tester, 'Übermorgen');
    await tester.tap(find.byKey(const Key('scan.readHighlights')));
    await tester.pumpAndSettle();

    expect(engine.readWholePage, isFalse);
    expect(engine.readRegions, hasLength(3));
    for (final w in ['ging', 'Wörterbuch', 'Übermorgen']) {
      await scrollTo(tester, field(w));
      expect(field(w), findsOneWidget);
    }
    expect(field('Morgen'), findsNothing);
    expect(field('traf'), findsNothing);

    // Correct an OCR mistake (simulated) and choose another deck.
    await scrollTo(tester, field('ging'));
    await tester.enterText(field('ging'), 'gingen');
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.byKey(const Key('scan.deck')));
    await tester.tap(find.text('Reise').last);
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('scan.summaryWords')));
    expect(
      tester.widget<Text>(find.byKey(const Key('scan.summaryWords'))).data,
      'gingen · Wörterbuch · Übermorgen',
    );
    await scrollAndTap(tester, find.byKey(const Key('scan.save')));
    expect(find.byKey(const Key('scan.done')), findsOneWidget);
    await unmountApp(tester);

    // "Restart": a new app on the same database.
    await pumpApp(tester, db, initialLocation: '/words/decks/${other.id}');
    for (final w in ['gingen', 'Wörterbuch', 'Übermorgen']) {
      expect(find.text(w), findsOneWidget);
    }
    final rows = await db.select(db.vocabularyEntries).get();
    expect(rows, hasLength(3));
    expect(rows.every((r) => r.deckId == other.id), isTrue);
    await unmountApp(tester);
  });

  testWidgets('two fingers zoom while highlighting without drawing; a small '
      'word highlighted while zoomed is read correctly', (tester) async {
    await openPhoto(tester);
    await pinch(tester, onScreen(tester, fakeBoxOf(page, 'lernte').center));
    expect(zoomOf(tester), greaterThan(1.5));
    expect(strokeChips(tester), 0, reason: 'zooming draws nothing');

    final target = onScreen(tester, fakeBoxOf(page, 'und').center);
    expect(viewer(tester).contains(target), isTrue);
    await drawOver(tester, 'und');
    expect(strokeChips(tester), 1);
    await tester.tap(find.byKey(const Key('scan.readHighlights')));
    await tester.pumpAndSettle();
    expect(field('und'), findsOneWidget);
    expect(field('lernte'), findsNothing);
    expect(field('Mühe'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('move mode pans and zooms but never draws', (tester) async {
    await openPhoto(tester);
    await tester.tap(find.byKey(const Key('scan.modeMove')));
    await tester.pumpAndSettle();
    await pinch(tester, onScreen(tester, fakeBoxOf(page, 'lernte').center));
    final before = onScreen(tester, fakeBoxOf(page, 'ging').center);
    await tester.dragFrom(viewer(tester).center, const Offset(30, 10));
    await tester.pumpAndSettle();
    expect(strokeChips(tester), 0);
    expect(onScreen(tester, fakeBoxOf(page, 'ging').center), isNot(before));

    await tester.tap(find.byKey(const Key('scan.modeHighlight')));
    await tester.pumpAndSettle();
    final visible =
        [
          for (final block in fakePageLayout(page))
            for (final line in block)
              for (final e in line.elements) e.text,
        ].firstWhere(
          (w) =>
              viewer(tester)
                  .deflate(30)
                  .contains(onScreen(tester, fakeBoxOf(page, w).center)),
        );
    await drawOver(tester, visible);
    expect(strokeChips(tester), 1);
    await unmountApp(tester);
  });

  testWidgets('a highlight without text is reported, the whole page is not '
      'read, and the user can go back and redraw', (tester) async {
    await openPhoto(tester);
    // An empty area below the text.
    final empty = onScreen(tester, const Offset(600, 1250));
    await tester.dragFrom(empty, const Offset(60, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scan.readHighlights')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.notice')), findsOneWidget);
    expect(engine.readWholePage, isFalse);

    await drawOver(tester, 'Stadt.');
    await tester.tap(find.byKey(const Key('scan.readHighlights')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.failedHighlights')), findsOneWidget);
    expect(field('Stadt'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan.redraw')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('scan.page')), findsOneWidget);
    expect(strokeChips(tester), 2);
    expect(engine.readWholePage, isFalse);
    await unmountApp(tester);
  });

  testWidgets('review: split a phrase, add a missing word, combine', (
    tester,
  ) async {
    await openPhoto(tester);
    await drawOver(tester, 'Dort', to: 'traf');
    await tester.tap(find.byKey(const Key('scan.readHighlights')));
    await tester.pumpAndSettle();
    List<String> words() => [
      for (final (_, item) in ProviderScope.containerOf(
        tester.element(find.byType(ScanReviewView)),
      ).read(scanControllerProvider(deck.id)).items)
        item.original,
    ];
    expect(words(), ['Dort traf']);

    await tester.tap(find.byTooltip('جدا کردن به لغت‌های تکی'));
    await tester.pumpAndSettle();
    expect(words(), ['Dort', 'traf']);

    await scrollAndTap(tester, find.byKey(const Key('scan.addItem')));
    expect(words(), ['Dort', 'traf', '']);
    final newWord = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          '${w.key}'.endsWith(".word'>]") &&
          w.controller!.text.isEmpty,
    );
    await scrollTo(tester, newWord);
    await tester.enterText(newWord, 'Bahnhof');
    await tester.pumpAndSettle();
    expect(words(), ['Dort', 'traf', 'Bahnhof']);

    final firstId = ProviderScope.containerOf(
      tester.element(find.byType(ScanReviewView)),
    ).read(scanControllerProvider(deck.id)).items.first.$2.id;
    await scrollAndTap(tester, find.byKey(Key('scan.item.$firstId.combine')));
    expect(words(), ['Dort traf', 'Bahnhof']);
    await unmountApp(tester);
  });

  testWidgets('fits at 320 px with 2x text', (tester) async {
    await openPhoto(tester, size: const Size(320, 640), textScale: 2);
    await drawOver(tester, 'ging');
    await drawOver(tester, 'Stadt.');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('scan.readHighlights')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  group('multi-touch never draws', () {
    /// Two fingers zoom out from [center]; [firstUp] lifts first and the
    /// other finger keeps moving before it lifts too.
    Future<void> pinchAndLift(
      WidgetTester tester,
      Offset center, {
      required bool firstUp,
    }) async {
      final a = await tester.startGesture(center - const Offset(30, 0));
      final b = await tester.startGesture(center + const Offset(30, 0));
      await tester.pump();
      for (var i = 1; i <= 5; i++) {
        await a.moveTo(center - Offset(30.0 + 10 * i, 0));
        await b.moveTo(center + Offset(30.0 + 10 * i, 4.0 * i));
        await tester.pump();
      }
      final (up, stays) = firstUp ? (a, b) : (b, a);
      await up.up();
      await tester.pump();
      // The remaining finger travels on its own before lifting.
      for (var i = 1; i <= 5; i++) {
        await stays.moveBy(const Offset(-18, 12));
        await tester.pump();
      }
      await stays.up();
      await tester.pumpAndSettle();
    }

    for (final firstUp in [true, false]) {
      testWidgets('a pinch draws nothing when the '
          '${firstUp ? 'first' : 'second'} finger lifts first and the other '
          'keeps moving', (tester) async {
        await openPhoto(tester);
        await pinchAndLift(
          tester,
          onScreen(tester, fakeBoxOf(page, 'Mühe', occurrence: 1).center),
          firstUp: firstUp,
        );
        expect(zoomOf(tester), greaterThan(1.2));
        expect(strokeChips(tester), 0);

        // The same in rectangle mode.
        await tester.tap(find.byKey(const Key('scan.modeRectangle')));
        await tester.pumpAndSettle();
        await pinchAndLift(tester, viewer(tester).center, firstUp: !firstUp);
        expect(regionChips(tester), 0);
        expect(strokeChips(tester), 0);
        await unmountApp(tester);
      });
    }

    testWidgets('a second finger during a stroke discards the stroke; the '
        'next one-finger stroke works normally', (tester) async {
      await openPhoto(tester);
      final box = fakeBoxOf(page, 'Wörterbuch.');
      final from = onScreen(tester, box.centerLeft + const Offset(4, 0));
      final a = await tester.startGesture(from);
      for (var i = 1; i <= 3; i++) {
        await a.moveBy(const Offset(8, 0));
        await tester.pump();
      }
      final b = await tester.startGesture(viewer(tester).center);
      await tester.pump();
      for (var i = 1; i <= 3; i++) {
        await a.moveBy(const Offset(6, 0));
        await b.moveBy(const Offset(0, 6));
        await tester.pump();
      }
      await a.up();
      await tester.pump();
      await b.moveBy(const Offset(20, 20));
      await b.up();
      await tester.pumpAndSettle();
      expect(strokeChips(tester), 0);

      await drawOver(tester, 'ging');
      expect(strokeChips(tester), 1);
      await tester.tap(find.byKey(const Key('scan.readHighlights')));
      await tester.pumpAndSettle();
      expect(field('ging'), findsOneWidget);
      expect(field('Wörterbuch'), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('a cancelled pointer leaves no stroke behind', (tester) async {
      await openPhoto(tester);
      final a = await tester.startGesture(
        onScreen(tester, fakeBoxOf(page, 'ging').centerLeft),
      );
      for (var i = 1; i <= 4; i++) {
        await a.moveBy(const Offset(10, 0));
        await tester.pump();
      }
      await a.cancel();
      await tester.pumpAndSettle();
      expect(strokeChips(tester), 0);
      // A later stroke starts fresh (never joined to the cancelled one).
      await drawOver(tester, 'Stadt.');
      expect(strokeChips(tester), 1);
      final state = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('scan.page'))),
      ).read(scanControllerProvider(deck.id));
      final points = state.strokes.single.points;
      expect(
        points.every(
          (p) => (p.dy - fakeBoxOf(page, 'Stadt.').center.dy).abs() < 30,
        ),
        isTrue,
      );
      await unmountApp(tester);
    });
  });

  group('rectangle selection', () {
    Future<void> frame(WidgetTester tester, Offset from, Offset to) async {
      final gesture = await tester.startGesture(from);
      for (var i = 1; i <= 6; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / 6)!);
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    Future<void> rectangleMode(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('scan.modeRectangle')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('scan.modeHint'))).data,
        startsWith('حالت کادر'),
      );
    }

    testWidgets('drag a rectangle around two lines: all their words are '
        'read, one item per line; a tap draws nothing; the photo is '
        'unchanged', (tester) async {
      await openPhoto(tester);
      await rectangleMode(tester);
      await tester.tapAt(onScreen(tester, fakeBoxOf(page, 'ging').center));
      await tester.pumpAndSettle();
      expect(regionChips(tester), 0, reason: 'a tap is not a rectangle');

      await frame(
        tester,
        onScreen(tester, const Offset(20, 60)),
        onScreen(tester, const Offset(1180, 200)),
      );
      expect(regionChips(tester), 1);
      expect(strokeChips(tester), 0);
      expect(find.byKey(const Key('scan.pageImage')), findsOneWidget);
      await tester.tap(find.byKey(const Key('scan.readHighlights')));
      await tester.pumpAndSettle();

      expect(engine.readWholePage, isFalse);
      expect(engine.readRegions, hasLength(1));
      expect(
        field('Am Morgen ging sie mit großer Mühe in die Stadt'),
        findsOneWidget,
      );
      await scrollTo(tester, field('Dort traf sie ihren alten Freund'));
      expect(field('Dort traf sie ihren alten Freund'), findsOneWidget);
      expect(field('Er gab sich Mühe und lernte das Wörterbuch'), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('a rectangle drawn while zoomed reads the framed words only', (
      tester,
    ) async {
      await openPhoto(tester);
      await pinch(tester, onScreen(tester, fakeBoxOf(page, 'lernte').center));
      expect(zoomOf(tester), greaterThan(1.5));
      await rectangleMode(tester);
      final und = fakeBoxOf(page, 'und');
      final lernte = fakeBoxOf(page, 'lernte');
      await frame(
        tester,
        onScreen(tester, und.topLeft - const Offset(4, 4)),
        onScreen(tester, lernte.bottomRight + const Offset(4, 4)),
      );
      expect(regionChips(tester), 1);
      await tester.tap(find.byKey(const Key('scan.readHighlights')));
      await tester.pumpAndSettle();
      final region = engine.readRegions.single;
      expect(region.left, closeTo(und.left - 4, 1));
      expect(region.bottom, closeTo(lernte.bottom + 4, 1));
      expect(field('und lernte'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('an empty rectangle is reported, the whole page is not read, '
        'and the rectangle can be removed and redrawn', (tester) async {
      await openPhoto(tester);
      await rectangleMode(tester);
      await frame(
        tester,
        onScreen(tester, const Offset(300, 1180)),
        onScreen(tester, const Offset(700, 1320)),
      );
      await tester.tap(find.byKey(const Key('scan.readHighlights')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scan.notice')), findsOneWidget);
      expect(find.textContaining('کادر'), findsWidgets);
      expect(engine.readWholePage, isFalse);

      await tester.tap(find.byTooltip('حذف از انتخاب'));
      await tester.pumpAndSettle();
      expect(regionChips(tester), 0);
      await frame(
        tester,
        onScreen(
          tester,
          fakeBoxOf(page, 'Übermorgen').topLeft - const Offset(3, 3),
        ),
        onScreen(
          tester,
          fakeBoxOf(page, 'fährt').bottomRight + const Offset(3, 3),
        ),
      );
      await tester.tap(find.byKey(const Key('scan.readHighlights')));
      await tester.pumpAndSettle();
      expect(field('Übermorgen fährt'), findsOneWidget);
      expect(engine.readWholePage, isFalse);
      await unmountApp(tester);
    });
  });
}
