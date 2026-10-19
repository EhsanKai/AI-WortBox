import 'dart:ui' show Rect;

import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/scan/data/scan_image_source.dart';
import 'package:ai_wortbox/features/scan/domain/text_tokenizer.dart';
import 'package:ai_wortbox/features/scan/presentation/scan_controller.dart';
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
  late FakeScanImageSource images;
  late FakeTextRecognitionEngine engine;
  late FakeImageCropper cropper;
  late ProviderContainer container;

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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  ScanController controller() =>
      container.read(scanControllerProvider(deck.id).notifier);
  ScanState state() => container.read(scanControllerProvider(deck.id));

  /// The token under the centre of [word]'s box on the photo.
  TextToken at(String word, [int occurrence = 0]) => state().document!.tokenAt(
    fakeBoxOf(page, word, occurrence: occurrence).center,
  )!;

  Future<void> scan() => controller().pickImage(ImageOrigin.camera);

  test('a page with word positions opens on the photo, which is kept only '
      'while the scan is open', () async {
    await scan();
    expect(state().step, ScanStep.select);
    expect(state().view, ScanView.image);
    expect(state().image, fakePhoto);
    expect(state().document!.scanText.hasLayout, isTrue);
    expect(images.discarded, isEmpty);

    controller().backToCapture();
    expect(images.discarded, [fakePhoto]);

    await scan();
    controller().startTyping();
    expect(images.discarded, hasLength(2));

    await scan();
    container.dispose();
    expect(images.discarded, hasLength(3), reason: 'closing the scan');
    container = ProviderContainer(
      overrides: [scanImageSourceProvider.overrideWithValue(images)],
    );
  });

  test('three words tapped on the photo, in any order and in different '
      'paragraphs, are the only items reviewed and saved', () async {
    await scan();
    controller()
      ..toggleWord(at('Straße.'))
      ..toggleWord(at('ging'))
      ..toggleWord(at('Wörterbuch.'));
    expect(state().selectedCount, 3);
    controller().goToReview();
    expect(state().items.map((e) => e.$2.original), [
      'ging',
      'Wörterbuch',
      'Straße',
    ]);
    expect(
      state().items[1].$2.context,
      'Er gab sich Mühe und lernte das Wörterbuch.',
    );
    await controller().save();
    expect(state().step, ScanStep.done);
    final saved = await db.select(db.vocabularyEntries).get();
    expect(
      saved.map((e) => e.original),
      unorderedEquals(['ging', 'Wörterbuch', 'Straße']),
    );
    expect(images.discarded, [fakePhoto], reason: 'deleted after saving');
  });

  test('tapping again deselects; removing and splitting selections', () async {
    await scan();
    controller().toggleWord(at('ging'));
    controller().toggleWord(at('ging'));
    expect(state().selectedCount, 0);

    // Touch-and-drag from "großer" to "Stadt." selects one expression.
    expect(controller().selectBetween(at('großer'), at('Stadt.')), isTrue);
    final range = state().selection.ranges.single;
    expect(state().document!.selectedText(range), 'großer Mühe in die Stadt');
    controller().splitRange(range);
    expect(
      [
        for (final r in state().selection.ranges)
          state().document!.selectedText(r),
      ],
      ['großer', 'Mühe', 'in', 'die', 'Stadt'],
    );
    controller().removeRange(state().selection.ranges.first);
    expect(state().selectedCount, 4);
  });

  test('disjoint selections are kept; expressions across paragraphs are '
      'refused with a notice', () async {
    await scan();
    controller().selectBetween(at('Dort'), at('traf'));
    controller().toggleWord(at('Übermorgen'));
    expect(state().selection.ranges, hasLength(2));
    expect(controller().selectBetween(at('Freund.'), at('Er')), isFalse);
    expect(state().notice, SelectionNotice.expressionTooLong);
    expect(state().selection.ranges, hasLength(2));
  });

  test('switching to the text view keeps the selection', () async {
    await scan();
    controller().toggleWord(at('Mühe', 1));
    controller().setView(ScanView.text);
    expect(state().view, ScanView.text);
    expect(state().selectedCount, 1);
    controller().setView(ScanView.image);
    expect(state().view, ScanView.image);
  });

  group('drawn area (fallback)', () {
    test('the area is cropped from the photo, read again, corrected by the '
        'user and added as one item', () async {
      engine.regionText = 'Wörter-\nbuch';
      await scan();
      const area = Rect.fromLTWH(700, 300, 260, 60);
      await controller().recognizeRegion(area);
      expect(cropper.crops.single, (fakePhoto, area));
      expect(state().regionText, 'Wörterbuch');
      expect(images.discarded, [fakeRegion], reason: 'the crop is temporary');

      controller().addRegionText('das Wörterbuch', context: 'Wörterbuch');
      expect(state().regionText, isNull);
      expect(state().manualItems.single.original, 'das Wörterbuch');
      controller().toggleWord(at('ging'));
      controller().goToReview();
      expect(state().items.map((e) => (e.$1 == null, e.$2.original)), [
        (false, 'ging'),
        (true, 'das Wörterbuch'),
      ]);

      // Removing the area item on the review screen removes it everywhere.
      controller().removeItem(state().items.last.$2.id);
      expect(state().manualItems, isEmpty);
      expect(state().items, hasLength(1));
    });

    test('nothing found, a failed crop, and dismissing add nothing', () async {
      engine.regionText = '';
      await scan();
      await controller().recognizeRegion(const Rect.fromLTWH(0, 0, 50, 50));
      expect(state().notice, SelectionNotice.regionEmpty);
      expect(state().regionText, isNull);

      cropper.error = const ScanException(ScanError.unreadableImage);
      await controller().recognizeRegion(const Rect.fromLTWH(0, 0, 50, 50));
      expect(state().notice, SelectionNotice.regionFailed);
      expect(state().regionBusy, isFalse);

      cropper.error = null;
      engine.regionText = 'Haus';
      await controller().recognizeRegion(const Rect.fromLTWH(0, 0, 50, 50));
      controller().dismissRegionText();
      expect(state().regionText, isNull);
      expect(state().selectedCount, 0);
    });
  });

  test('without word positions (engine or typed text) the text view is '
      'used and the photo is not kept', () async {
    engine.layout = false;
    await scan();
    expect(state().view, ScanView.text);
    expect(state().canShowImage, isFalse);
    expect(images.discarded, [fakePhoto]);
    controller().setView(ScanView.image);
    expect(state().view, ScanView.text);
  });
}
