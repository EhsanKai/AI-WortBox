import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/scan/data/scan_image_source.dart';
import 'package:ai_wortbox/features/scan/presentation/scan_controller.dart';
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
    'Er gab sich Mühe.';

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
    engine = FakeTextRecognitionEngine(page);
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
    // Keep the auto-dispose providers alive for the test.
    container.listen(scanControllerProvider(deck.id), (_, _) {});
    container.listen(scanDecisionsProvider(deck.id), (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  ScanController controller() =>
      container.read(scanControllerProvider(deck.id).notifier);
  ScanState state() => container.read(scanControllerProvider(deck.id));

  void tap(String display, [int occurrence = 0]) => controller().tapWord(
    state().document!.words
        .where((w) => w.display == display)
        .elementAt(occurrence),
  );

  Future<List<VocabularyEntry>> entries() async {
    final rows = await db.select(db.vocabularyEntries).get();
    return [
      for (final r in rows)
        VocabularyEntry(
          id: r.id,
          deckId: r.deckId,
          original: r.original,
          normalized: r.normalized,
          lemma: r.lemma,
          sourceLanguage: deck.sourceLanguage,
          definitionLanguage: deck.definitionLanguage,
          sourceType: r.sourceType,
          enrichmentStatus: r.enrichmentStatus,
          sourceContext: r.sourceContext,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
    ];
  }

  test(
    'a picked photo opens unchanged for highlighting; nothing is '
    'recognized until asked; the photo is deleted when the scan ends',
    () async {
      await controller().pickImage(ImageOrigin.camera);
      expect(images.requested, [ImageOrigin.camera]);
      expect(state().step, ScanStep.highlight);
      expect(state().image, fakePhoto);
      expect(state().imageSize, fakePageSize);
      expect(engine.calls, 0);
      expect(images.discarded, isEmpty);

      // Reading the whole page only on explicit request.
      await controller().readWholePage();
      expect(engine.calls, 1);
      expect(state().step, ScanStep.select);
      expect(state().document!.text, page);
      controller().backFromText();
      expect(state().step, ScanStep.highlight);

      controller().backToCapture();
      expect(images.discarded, [fakePhoto]);
    },
  );

  test('a photo that cannot be shown is read as text, with a notice', () async {
    cropper.sizeError = const ScanException(ScanError.unreadableImage);
    await controller().pickImage(ImageOrigin.gallery);
    expect(state().step, ScanStep.select);
    expect(state().notice, SelectionNotice.photoUnavailable);
    expect(state().document!.text, page);
  });

  test('cancelling the picker stays on the capture step', () async {
    images.image = null;
    await controller().pickImage(ImageOrigin.gallery);
    expect(state().step, ScanStep.capture);
    expect(state().error, isNull);
    expect(state().isBusy, isFalse);
    expect(engine.calls, 0);
  });

  test('permission denial is reported and nothing is recognized', () async {
    images.error = const ScanException(ScanError.cameraPermissionDenied);
    await controller().pickImage(ImageOrigin.camera);
    expect(state().step, ScanStep.capture);
    expect(
      (state().error! as ScanException).error,
      ScanError.cameraPermissionDenied,
    );
    expect(engine.calls, 0);
  });

  test('unsupported images are rejected and still discarded', () async {
    images.image = const PickedImage(
      path: '/tmp/x.pdf',
      name: 'x.pdf',
      sizeBytes: 9,
    );
    await controller().pickImage(ImageOrigin.gallery);
    expect(
      (state().error! as ScanException).error,
      ScanError.unsupportedFormat,
    );
    expect(images.discarded, hasLength(1));
    expect(engine.calls, 0);
  });

  test('OCR failure and unavailability keep the photo with a notice', () async {
    engine.error = const ScanException(ScanError.ocrFailed);
    await controller().pickImage(ImageOrigin.gallery);
    await controller().readWholePage();
    expect(state().step, ScanStep.highlight);
    expect(state().notice, SelectionNotice.highlightsFailed);
    expect(state().isBusy, isFalse);

    engine
      ..error = null
      ..isAvailable = false;
    await controller().readWholePage();
    expect(state().notice, SelectionNotice.highlightsFailed);
  });

  test('an empty OCR result opens an empty selection step', () async {
    engine.text = '   ';
    await controller().pickImage(ImageOrigin.gallery);
    await controller().readWholePage();
    expect(state().step, ScanStep.select);
    expect(state().document!.hasWords, isFalse);
  });

  test('recovers a photo lost while Android killed the activity', () async {
    images.lost = fakePhoto;
    await controller().recoverLostImage();
    expect(state().step, ScanStep.highlight);
    await controller().recoverLostImage(); // Only once per session.
    expect(state().image, fakePhoto);
    expect(engine.calls, 0);
  });

  test('typed fallback goes straight to selection', () {
    controller().startTyping();
    expect(state().step, ScanStep.typing);
    controller().useTypedText('   ');
    expect(state().step, ScanStep.typing);
    controller().useTypedText('Ich lese ein Buch.');
    expect(state().step, ScanStep.select);
    expect(state().document!.words.map((w) => w.display), [
      'Ich',
      'lese',
      'ein',
      'Buch',
    ]);
  });

  group('selection and review', () {
    setUp(() async {
      await controller().pickImage(ImageOrigin.gallery);
      await controller().readWholePage();
    });

    test('words and expressions become review items with context', () async {
      await pumpEventQueue();
      tap('ging');
      controller().setMode(SelectionMode.expression);
      expect(state().notice, isNull);
      tap('sich'); // anchor
      expect(state().notice, SelectionNotice.pickExpressionEnd);
      tap('Mühe', 1); // end
      expect(state().selection.length, 2);

      controller().goToReview();
      expect(state().step, ScanStep.review);
      final items = state().items.map((e) => e.$2).toList();
      expect(items.map((i) => i.original), ['ging', 'sich Mühe']);
      expect(
        items.first.context,
        'Am Morgen ging sie mit großer Mühe in die Stadt.',
      );
      expect(items.last.context, 'Er gab sich Mühe.');
      expect(items.first.hint?.baseForm, 'gehen');
      expect(items.last.hint, isNull);
    });

    test('tapping a selected word deselects it; reset clears all', () async {
      await pumpEventQueue();
      tap('Stadt');
      tap('Freund');
      tap('Stadt');
      expect(state().selection.length, 1);
      controller().clearSelection();
      expect(state().selection.isEmpty, isTrue);
    });

    test('too long or cross-paragraph expressions are refused', () async {
      await pumpEventQueue();
      controller().setMode(SelectionMode.expression);
      tap('Freund');
      tap('Er');
      expect(state().notice, SelectionNotice.expressionTooLong);
      expect(state().selection.isEmpty, isTrue);
    });

    test('correcting the text keeps unaffected selections', () async {
      await pumpEventQueue();
      tap('Stadt');
      tap('Freund');
      controller().editText(page.replaceFirst('Stadt', 'Stadt,'));
      expect(state().selection.length, 2);
      controller().editText(page.replaceFirst('Freund', 'Freunde'));
      expect(state().notice, SelectionNotice.selectionsDropped);
      expect(state().droppedCount, 1);
      expect(state().document!.scanText.lines, isEmpty);
    });

    test('saves only reviewed items, with corrections and context', () async {
      await pumpEventQueue();
      tap('ging');
      tap('traf');
      tap('Stadt');
      controller().goToReview();
      // Items are listed in text order: ging, Stadt, traf.
      expect(state().items.map((e) => e.$2.original), [
        'ging',
        'Stadt',
        'traf',
      ]);
      final traf = state().items.last.$2;
      // Correct an OCR mistake (simulated) and drop one item before saving.
      controller().updateItem(
        traf.copyWith(
          original: 'traf',
          lemma: 'treffen',
          meaning: 'ملاقات کرد',
        ),
      );
      controller().removeItem(state().items[1].$2.id);
      await controller().save();

      expect(state().step, ScanStep.done);
      expect(state().result!.createdCount, 2);
      final saved = await entries();
      expect(saved.map((e) => e.original), unorderedEquals(['ging', 'traf']));
      final trafEntry = saved.firstWhere((e) => e.original == 'traf');
      expect(trafEntry.lemma, 'treffen');
      expect(trafEntry.sourceType, VocabularySourceType.image);
      expect(trafEntry.sourceContext, 'Dort traf sie ihren alten Freund.');
      expect(trafEntry.enrichmentStatus, EnrichmentStatus.ready);
      expect(
        saved.firstWhere((e) => e.original == 'ging').enrichmentStatus,
        EnrichmentStatus.missing,
      );
    });

    test('existing words are not saved again; merge needs a choice', () async {
      await container
          .read(vocabularyRepositoryProvider)
          .createEntry(
            VocabularyDraft(
              deckId: deck.id,
              original: 'Stadt',
              meanings: const [VocabularyMeaning('شهر')],
            ),
          );
      await pumpEventQueue();
      tap('Stadt');
      tap('Freund');
      controller().goToReview();
      await pumpEventQueue();

      var decisions = container.read(scanDecisionsProvider(deck.id)).value!;
      expect(decisions[1], isA<SkipDecision>());
      expect(decisions[2], isA<CreateDecision>());

      // A new meaning for an existing word is skipped by default...
      final (_, stadt) = state().items.first;
      controller().updateItem(stadt.copyWith(meaning: 'مرکز شهر'));
      await pumpEventQueue();
      decisions = container.read(scanDecisionsProvider(deck.id)).value!;
      expect((decisions[1]! as SkipDecision).reason, SkipReason.wordExists);
      // ...and merged only when the user chooses to.
      controller().setStrategy(DuplicateStrategy.mergeMeanings);
      await pumpEventQueue();
      decisions = container.read(scanDecisionsProvider(deck.id)).value!;
      expect(decisions[1], isA<MergeIntoEntryDecision>());

      await controller().save();
      final repo = container.read(vocabularyRepositoryProvider);
      final stadtEntry = (await repo.findByNormalized(deck.id, 'stadt')).single;
      expect(stadtEntry.meanings.map((m) => m.text), ['شهر', 'مرکز شهر']);
      expect(stadtEntry.sourceType, VocabularySourceType.manual);
    });

    test('deck selection decides where items are saved', () async {
      final other = await DriftDeckRepository(
        db,
        clock: FixedClock(DateTime.utc(2026, 10, 15)),
        ids: SequentialIdGenerator('other'),
      ).createDeck(const DeckDraft(name: 'Andere'));
      await pumpEventQueue();
      tap('Freund');
      controller()
        ..goToReview()
        ..selectDeck(other.id);
      await controller().save();
      expect((await entries()).single.deckId, other.id);
    });

    test('a failed save changes nothing and keeps the review', () async {
      await pumpEventQueue();
      tap('Freund');
      controller().goToReview();
      await (db.delete(db.decks)..where((d) => d.id.equals(deck.id))).go();
      await controller().save();
      expect(state().step, ScanStep.review);
      expect(state().saveError, isA<VocabularyValidationException>());
      expect(state().items, hasLength(1));
      expect(await db.select(db.vocabularyEntries).get(), isEmpty);
    });
  });
}
