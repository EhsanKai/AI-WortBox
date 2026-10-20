import 'dart:ui' show Offset, Rect;

import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/scan/data/scan_image_source.dart';
import 'package:ai_wortbox/features/scan/presentation/scan_controller.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/scan_fakes.dart';
import '../../../helpers/test_database.dart';

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
  late ProviderContainer container;

  ScanController controller() =>
      container.read(scanControllerProvider(deck.id).notifier);
  ScanState state() => container.read(scanControllerProvider(deck.id));

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
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(FixedClock(DateTime.utc(2026, 10, 16))),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        scanImageSourceProvider.overrideWithValue(images),
        textRecognitionEngineProvider.overrideWithValue(engine),
        imageCropperProvider.overrideWithValue(cropper),
      ],
      retry: (_, _) => null,
    );
    container.listen(scanControllerProvider(deck.id), (_, _) {});
    container.listen(scanDecisionsProvider(deck.id), (_, _) {});
    await controller().pickImage(ImageOrigin.camera);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// A stroke along [word]'s line, from inside its start to inside its end.
  int highlight(String word, {int occurrence = 0, double width = 40}) {
    final box = fakeBoxOf(page, word, occurrence: occurrence);
    return controller().addStroke([
      box.centerLeft + const Offset(6, 2),
      box.center,
      box.centerRight - const Offset(6, -1),
    ], width);
  }

  List<String> originals() => [
    for (final (_, item) in state().items) item.original,
  ];

  test('opening a photo reads nothing; strokes are kept in photo pixels, '
      'undone, removed and cleared', () {
    expect(state().step, ScanStep.highlight);
    expect(engine.calls, 0);
    final a = highlight('ging');
    final b = highlight('Stadt.');
    highlight('Freund.');
    expect(state().strokes.map((s) => s.id), [a, b, a + 2]);
    expect(
      state().strokes.first.points.first,
      fakeBoxOf(page, 'ging').centerLeft + const Offset(6, 2),
    );
    controller().undoPhotoSelection();
    expect(state().strokes.map((s) => s.id), [a, b]);
    controller().removePhotoSelection(a);
    expect(state().strokes.map((s) => s.id), [b]);
    controller().clearPhotoSelections();
    expect(state().strokes, isEmpty);
    expect(engine.calls, 0);
  });

  test(
    'only the highlighted regions are read, never the whole page; '
    'results come in drawing order and contain only highlighted words',
    () async {
      highlight('Wörterbuch.');
      highlight('ging');
      highlight('Straße.');
      await controller().readHighlights();

      expect(engine.readWholePage, isFalse);
      expect(engine.readRegions, hasLength(3));
      // Each crop is a small area around its highlight.
      for (final (i, word) in ['Wörterbuch.', 'ging', 'Straße.'].indexed) {
        final r = engine.readRegions.elementAt(i);
        expect(r.contains(fakeBoxOf(page, word).center), isTrue);
        expect(r.height, lessThan(fakePageSize.height / 4));
      }
      expect(state().step, ScanStep.review);
      expect(originals(), ['Wörterbuch', 'ging', 'Straße']);
      // Context is the highlighted line as far as it was read; other lines
      // and the rest of the page are never included.
      final context = state().items.first.$2.context;
      expect(context, contains('Wörterbuch'));
      expect(context, isNot(contains('Übermorgen')));
      expect(context, isNot(contains('Morgen ging')));
      // Every temporary crop was deleted; the photo is kept while scanning.
      expect(images.discarded, hasLength(3));
      expect(images.discarded, isNot(contains(fakePhoto)));
    },
  );

  test('a phrase can be highlighted in one stroke', () async {
    final from = fakeBoxOf(page, 'Dort').center;
    final to = fakeBoxOf(page, 'traf').center;
    controller().addStroke([from, to], 40);
    await controller().readHighlights();
    expect(originals(), ['Dort traf']);
  });

  test('a highlight without text is retried with a larger margin, then '
      'reported; the whole page is not read instead', () async {
    // Empty area below the text.
    controller().addStroke(const [Offset(300, 1200), Offset(500, 1200)], 40);
    await controller().readHighlights();
    expect(engine.readRegions, hasLength(2));
    expect(
      engine.readRegions.last.width,
      greaterThan(engine.readRegions.first.width),
    );
    expect(engine.readWholePage, isFalse);
    expect(state().step, ScanStep.highlight);
    expect(state().notice, SelectionNotice.highlightsEmpty);
    expect(state().failedStrokes, {state().strokes.single.id});

    // With a successful highlight as well, the review opens and names the
    // failed one.
    highlight('ging');
    await controller().readHighlights();
    expect(state().step, ScanStep.review);
    expect(originals(), ['ging']);
    expect(state().failedStrokes, hasLength(1));
    expect(engine.readWholePage, isFalse);
  });

  test(
    'an OCR error is reported and the highlight is read again next time',
    () async {
      highlight('ging');
      engine.regionError = const ScanException(ScanError.ocrFailed);
      await controller().readHighlights();
      expect(state().step, ScanStep.highlight);
      expect(state().notice, SelectionNotice.highlightsFailed);
      expect(state().readStrokes, isEmpty);

      engine.regionError = null;
      await controller().readHighlights();
      expect(originals(), ['ging']);
    },
  );

  test('going back keeps edits; only new highlights are read; removing a '
      'highlight removes its item', () async {
    final ging = highlight('ging');
    await controller().readHighlights();
    controller().updateItem(
      state().items.single.$2.copyWith(original: 'gingen'),
    );
    controller().backToSelect();
    expect(state().step, ScanStep.highlight);
    highlight('Stadt.');
    await controller().readHighlights();
    expect(engine.readRegions, hasLength(2));
    expect(originals(), ['gingen', 'Stadt']);

    controller().backToSelect();
    controller().removePhotoSelection(ging);
    await controller().readHighlights();
    expect(originals(), ['Stadt']);
  });

  group('review', () {
    setUp(() async {
      highlight('großer');
      highlight('Mühe', occurrence: 1);
      // "die Straße" as one phrase.
      controller().addStroke([
        fakeBoxOf(page, 'die', occurrence: 1).center,
        fakeBoxOf(page, 'Straße.').center,
      ], 40);
      await controller().readHighlights();
      expect(originals(), ['großer', 'Mühe', 'die Straße']);
    });

    test('edit, remove, add, split and combine', () {
      final items = [for (final (_, i) in state().items) i];
      controller().updateItem(items[0].copyWith(original: 'groß'));
      controller().removeItem(items[1].id);
      expect(originals(), ['groß', 'die Straße']);

      controller().splitItem(state().items.last.$2.id);
      expect(originals(), ['groß', 'die', 'Straße']);

      controller().combineWithNext(state().items[1].$2.id);
      expect(originals(), ['groß', 'die Straße']);

      controller().addItem();
      expect(originals(), ['groß', 'die Straße', '']);
      controller().updateItem(
        state().items.last.$2.copyWith(original: 'Mädchen'),
      );
      expect(originals(), ['groß', 'die Straße', 'Mädchen']);
    });

    test('only confirmed, valid items are saved to the chosen deck; an '
        'empty added item is not saved', () async {
      controller().removeItem(state().items[1].$2.id);
      controller().addItem();
      controller().selectDeck(other.id);
      await controller().save();
      expect(state().step, ScanStep.done);
      final rows = await db.select(db.vocabularyEntries).get();
      expect(
        rows.map((r) => r.original),
        unorderedEquals(['großer', 'die Straße']),
      );
      expect(rows.every((r) => r.deckId == other.id), isTrue);
      expect(
        rows.every((r) => r.sourceType == VocabularySourceType.image),
        isTrue,
      );
      expect(
        images.discarded,
        contains(fakePhoto),
        reason: 'photo deleted after saving',
      );
    });

    test('a word already in the deck is marked and skipped', () async {
      await DriftVocabularyRepository(
        db,
        clock: FixedClock(DateTime.utc(2026, 10, 15)),
        ids: SequentialIdGenerator('v'),
      ).createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: 'großer',
          meanings: const [VocabularyMeaning('بزرگ‌تر')],
        ),
      );
      await pumpEventQueue();
      final decisions = container.read(scanDecisionsProvider(deck.id)).value!;
      expect(decisions[1], isA<SkipDecision>());
      expect(decisions[2], isA<CreateDecision>());
      await controller().save();
      expect(state().result!.createdCount, 2);
      expect(state().result!.skippedCount, 1);
    });
  });

  test('the area read for a highlight is clipped to the photo', () async {
    controller().addStroke(const [Offset(2, 2), Offset(30, 4)], 40);
    await controller().readHighlights();
    for (final (_, region) in cropper.crops) {
      expect((Offset.zero & fakePageSize).contains(region.topLeft), isTrue);
      expect(region.left, 0);
      expect(region.top, 0);
    }
    expect(cropper.crops.first.$2, isA<Rect>());
  });

  group('rectangles', () {
    /// A rectangle around [from] … [to] (photo pixels of the fake page).
    int frame(String from, String to, {double pad = 3}) =>
        controller().addRegion(
          fakeBoxOf(page, from).topLeft - Offset(pad, pad),
          fakeBoxOf(page, to).bottomRight + Offset(pad, pad),
        );

    test('everything inside is read, one item per line, from a crop of '
        'exactly the rectangle; the whole page is never read', () async {
      final id = controller().addRegion(
        const Offset(1190, 200),
        const Offset(20, 60),
      );
      expect(
        state().regions.single.rect,
        const Rect.fromLTRB(20, 60, 1190, 200),
      );
      await controller().readHighlights();
      expect(cropper.crops.single.$2, const Rect.fromLTRB(20, 60, 1190, 200));
      expect(engine.readWholePage, isFalse);
      expect(state().step, ScanStep.review);
      expect(originals(), [
        'Am Morgen ging sie mit großer Mühe in die Stadt',
        'Dort traf sie ihren alten Freund',
      ]);
      expect(state().items.every((e) => e.$2.stroke == id), isTrue);
      expect(images.discarded, hasLength(1), reason: 'crop deleted');
      expect(images.discarded, isNot(contains(fakePhoto)));
    });

    test(
      'only the framed words are read, not the rest of their line',
      () async {
        frame('ging', 'sie');
        await controller().readHighlights();
        expect(originals(), ['ging sie']);
      },
    );

    test('rectangles are clipped to the photo', () {
      controller().addRegion(const Offset(-40, -40), const Offset(5000, 300));
      expect(
        state().regions.single.rect,
        Rect.fromLTRB(0, 0, fakePageSize.width, 300),
      );
      expect(
        controller().addRegion(const Offset(1300, 10), const Offset(1500, 90)),
        -1,
        reason: 'outside the photo',
      );
      expect(state().regions, hasLength(1));
    });

    test(
      'an empty rectangle is reported and marked; nothing else is read',
      () async {
        controller().addRegion(
          const Offset(300, 1200),
          const Offset(600, 1300),
        );
        await controller().readHighlights();
        expect(engine.readRegions, hasLength(1));
        expect(engine.readWholePage, isFalse);
        expect(state().step, ScanStep.highlight);
        expect(state().notice, SelectionNotice.regionsEmpty);
        expect(state().failedStrokes, {state().regions.single.id});
      },
    );

    test('highlights and rectangles share one numbering; undo, remove and '
        'clear work for both', () async {
      final a = highlight('ging');
      final r = frame('Wörterbuch.', 'Wörterbuch.');
      final b = highlight('Straße.');
      expect(state().photoSelectionIds, [a, r, b]);
      expect(state().selectionNumber(r), 2);
      await controller().readHighlights();
      expect(originals(), ['ging', 'Wörterbuch', 'Straße']);

      controller().backToSelect();
      controller().removePhotoSelection(r);
      expect(originals(), ['ging', 'Straße']);
      controller().undoPhotoSelection();
      expect(state().photoSelectionIds, [a]);
      frame('Dort', 'traf');
      controller().clearPhotoSelections();
      expect(state().hasPhotoSelections, isFalse);
      expect(state().items, isEmpty);
    });

    test('items can be corrected, split and removed; only confirmed items '
        'are saved to the chosen deck', () async {
      frame('Übermorgen', 'Straße.');
      frame('Dort', 'traf');
      await controller().readHighlights();
      expect(originals(), [
        'Übermorgen fährt sie über die Straße',
        'Dort traf',
      ]);
      controller().splitItem(state().items.first.$2.id);
      expect(originals(), [
        'Übermorgen',
        'fährt',
        'sie',
        'über',
        'die',
        'Straße',
        'Dort traf',
      ]);
      for (final w in ['fährt', 'sie', 'über', 'die', 'Dort traf']) {
        controller().removeItem(
          state().items.firstWhere((e) => e.$2.original == w).$2.id,
        );
      }
      controller().updateItem(
        state().items.last.$2.copyWith(original: 'die Straße'),
      );
      controller().selectDeck(other.id);
      await controller().save();
      final rows = await db.select(db.vocabularyEntries).get();
      expect(
        rows.map((r) => r.original),
        unorderedEquals(['Übermorgen', 'die Straße']),
      );
      expect(rows.every((r) => r.deckId == other.id), isTrue);
      // Nothing is translated or enriched automatically.
      expect(await db.select(db.vocabularyMeanings).get(), isEmpty);
    });
  });
}
