import 'package:ai_wortbox/core/design/typography.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/text/bidi.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/scan_fakes.dart';
import '../helpers/test_database.dart';

/// Content that stresses mixed-direction layout.
const deckName = 'Wörter aus „Der Vorleser“ – Kap. 3';
const compound = 'Donaudampfschifffahrtsgesellschaftskapitän';
const example =
    'Der Kapitän sagte: „Wir fahren um 7.30 Uhr ab!“\n'
    'Das Schiff war 120 m lang.';
const translation =
    'ناخدا گفت: «ساعت ۷:۳۰ حرکت می‌کنیم!»\n'
    'کشتی ۱۲۰ متر طول داشت.';
const page =
    'Am Morgen ging sie mit großer Mühe in die Stadt. Die Straße war '
    'voller Menschen, und die Übermüdung war ihr anzusehen.\n'
    'Dort traf sie um 9 Uhr ihren alten Freund.';

/// Notes keep line breaks (example sentences are stored on one line).
const notes =
    'یادداشت با عدد 42 و کلمهٔ Schiff در وسط.\n'
    'خط دوم: «Kapitän» یعنی ناخدا!';

/// The narrow viewport: an iPhone SE (1st gen) / small Android width.
const narrow = Size(320, 640);

void main() {
  late AppDatabase db;
  late Deck deck;
  late VocabularyEntry longEntry;

  setUp(() async {
    db = openTestDatabase();
    final clock = FixedClock(DateTime.utc(2026, 10, 15));
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: deckName));
    final vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('seed'),
    );
    longEntry = await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: compound,
        meanings: const [
          VocabularyMeaning('ناخدای شرکت کشتیرانی بخار دانوب'),
          VocabularyMeaning('(شوخی) نمونهٔ کلمهٔ مرکب بسیار بلند'),
        ],
        lemma: compound,
        partOfSpeech: 'Nomen',
        grammarInfo: 'der, -s, -e',
        exampleSentence: example,
        exampleTranslation: translation,
        notes: notes,
        sourceContext: example,
      ).cleaned(),
    );
    await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'Straße',
        meanings: const [
          VocabularyMeaning('خیابان'),
          VocabularyMeaning('جاده'),
          VocabularyMeaning('کوچه (در بعضی شهرها)'),
        ],
      ).cleaned(),
    );
    await vocab.createEntry(
      VocabularyDraft(deckId: deck.id, original: 'Übermüdung').cleaned(),
    );
    await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'sich auf etw. (Akk.) freuen',
        meanings: const [VocabularyMeaning('منتظر چیزی بودن (با خوشحالی)')],
      ).cleaned(),
    );
  });
  tearDown(() => db.close());

  /// Scrolls the visible list to the end so every item is laid out.
  Future<void> scrollThrough(WidgetTester tester) async {
    final scrollables = find.byType(Scrollable).hitTestable();
    if (scrollables.evaluate().isEmpty) return;
    for (var i = 0; i < 12; i++) {
      await tester.drag(scrollables.first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
  }

  group('every screen lays out without overflow', () {
    final routes = <String, String Function()>{
      'today': () => '/today',
      'decks': () => '/words',
      'deck detail': () => '/words/decks/${deck.id}',
      'word detail': () => '/words/decks/${deck.id}/entries/${longEntry.id}',
      'edit form': () => '/words/decks/${deck.id}/entries/${longEntry.id}/edit',
      'add': () => '/add',
      'new word form': () => '/add/manual?deckId=${deck.id}',
      'csv import': () => '/add/csv?deckId=${deck.id}',
      'statistics': () => '/statistics',
      'settings': () => '/settings',
      'scan capture': () => '/add/scan?deckId=${deck.id}',
      'ai settings': () => '/settings/ai',
      'ai suggestions (no key)': () => '/words/decks/${deck.id}/enrich',
      'search all words': () => '/words/search',
      'tags': () => '/words/tags',
      'anki import': () => '/add/anki?deckId=${deck.id}',
      'reminder': () => '/settings/reminder',
      'practice setup': () => '/today/practice',
      'practice session': () => '/today/practice/session',
    };
    for (final textScale in [1.5, 2.0]) {
      for (final brightness in Brightness.values) {
        for (final MapEntry(key: name, value: route) in routes.entries) {
          testWidgets('$name at 320 px, ${textScale}x, ${brightness.name}', (
            tester,
          ) async {
            await pumpApp(
              tester,
              db,
              initialLocation: route(),
              size: narrow,
              textScale: textScale,
              brightness: brightness,
            );
            expect(
              Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
              brightness,
            );
            await scrollThrough(tester);
            expect(tester.takeException(), isNull);
            await unmountApp(tester);
          });
        }
      }
    }
  });

  testWidgets('create-deck sheet and duplicate dialog fit at 320 px, 2x', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/add/manual?deckId=${deck.id}',
      size: narrow,
      textScale: 2,
    );
    await tester.enterText(find.byKey(const Key('entryForm.word')), 'Straße');
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.0')),
      'گذرگاه',
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.save')));
    // Same word, different meaning: the dialog lists the existing meanings.
    expect(find.text('این لغت با معنی دیگری وجود دارد'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The actions scroll with the dialog content.
    await tester.ensureVisible(find.text('انصراف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(find.text('این لغت با معنی دیگری وجود دارد'), findsNothing);
    await unmountApp(tester);

    await pumpApp(
      tester,
      db,
      initialLocation: '/words',
      size: narrow,
      textScale: 2,
      brightness: Brightness.dark,
    );
    await tester.tap(find.byKey(const Key('decks.create')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('createDeck.submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  group('scanned-page flow', () {
    Future<void> openSelection(
      WidgetTester tester, {
      Size size = narrow,
      double textScale = 1,
      Brightness brightness = Brightness.light,
    }) async {
      await pumpApp(
        tester,
        db,
        initialLocation: '/add/scan?deckId=${deck.id}',
        imageSource: FakeScanImageSource(),
        recognitionEngine: FakeTextRecognitionEngine(page),
        size: size,
        textScale: textScale,
        brightness: brightness,
      );
      await scrollAndTap(tester, find.byKey(const Key('scan.gallery')));
      await readWholePageAsText(tester);
    }

    Finder word(String w) => find.byKey(Key('scan.word.${page.indexOf(w)}'));

    for (final (textScale, brightness) in [
      (1.5, Brightness.light),
      (2.0, Brightness.dark),
    ]) {
      testWidgets(
        'select, review and save at 320 px, ${textScale}x, ${brightness.name}',
        (tester) async {
          await openSelection(
            tester,
            textScale: textScale,
            brightness: brightness,
          );
          // Not yet in the deck, so it will be saved.
          await scrollTo(tester, word('Menschen'));
          await tester.tap(word('Menschen'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(const Key('scan.review')));
          await tester.pumpAndSettle();
          await scrollThrough(tester);
          expect(tester.takeException(), isNull);

          await scrollAndTap(tester, find.byKey(const Key('scan.save')));
          expect(find.byKey(const Key('scan.done')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await unmountApp(tester);
        },
      );
    }

    testWidgets('every word is a tap target of at least 48×48', (tester) async {
      await openSelection(tester, size: const Size(390, 844));
      final words = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('scan.word.'),
      );
      expect(words, findsWidgets);
      for (final element in words.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await unmountApp(tester);
    });

    testWidgets('words expose label, button role and selected state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openSelection(tester, size: const Size(390, 844));

      expect(
        tester.getSemantics(word('Mühe')),
        matchesSemantics(
          label: 'Mühe',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          hasTapAction: true,
          onTapHint: 'انتخاب لغت',
        ),
      );
      await tester.tap(word('Mühe'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(word('Mühe')),
        matchesSemantics(
          label: 'Mühe',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
          onTapHint: 'لغو انتخاب',
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await unmountApp(tester);
      semantics.dispose();
    });

    testWidgets('selected words keep readable contrast in both themes', (
      tester,
    ) async {
      for (final brightness in Brightness.values) {
        await openSelection(
          tester,
          size: const Size(390, 844),
          brightness: brightness,
        );
        await tester.tap(word('Mühe'));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await unmountApp(tester);
      }
    });
  });

  group('tap targets and labels', () {
    for (final (name, route) in [
      ('add', '/add'),
      ('settings', '/settings'),
      ('today', '/today'),
    ]) {
      testWidgets('$name meets tap-target and label guidelines', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpApp(tester, db, initialLocation: route);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await unmountApp(tester);
        semantics.dispose();
      });
    }

    testWidgets('deck and word detail meet the tap-target guideline', (
      tester,
    ) async {
      await pumpApp(tester, db, initialLocation: '/words/decks/${deck.id}');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await unmountApp(tester);
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/entries/${longEntry.id}',
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await unmountApp(tester);
    });

    for (final brightness in Brightness.values) {
      testWidgets('word detail text contrast, ${brightness.name}', (
        tester,
      ) async {
        await pumpApp(
          tester,
          db,
          initialLocation: '/words/decks/${deck.id}/entries/${longEntry.id}',
          brightness: brightness,
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await unmountApp(tester);
      });
    }
  });

  group('mixed-direction content', () {
    Text textOf(WidgetTester tester, String value) =>
        tester.widget<Text>(find.text(value).first);

    testWidgets('German is LTR in the book face, Persian RTL in the UI face', (
      tester,
    ) async {
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/entries/${longEntry.id}',
      );
      final headword = textOf(tester, compound);
      expect(headword.textDirection, TextDirection.ltr);
      expect(headword.style?.fontFamily, AppFonts.german);

      final meaning = textOf(tester, 'ناخدای شرکت کشتیرانی بخار دانوب');
      expect(meaning.textDirection, TextDirection.rtl);
      expect(meaning.style?.fontFamily, AppFonts.ui);

      // Multiline German example (with „quotes“, numbers and !) is LTR;
      // its Persian translation (with «» and Persian digits) is RTL.
      final storedExample = longEntry.exampleSentence!;
      final storedTranslation = longEntry.exampleTranslation!;
      await scrollTo(tester, find.text(storedTranslation));
      expect(textOf(tester, storedExample).textDirection, TextDirection.ltr);
      expect(
        textOf(tester, storedTranslation).textDirection,
        TextDirection.rtl,
      );

      // Multiline Persian notes with embedded German and digits stay RTL.
      await scrollTo(tester, find.text(notes));
      expect(textOf(tester, notes).textDirection, TextDirection.rtl);
      await unmountApp(tester);
    });

    testWidgets('word list shows headword prominently, meanings joined', (
      tester,
    ) async {
      await pumpApp(tester, db, initialLocation: '/words/decks/${deck.id}');
      await tester.tap(find.byKey(const Key('deck.toggleMeanings')));
      await tester.pumpAndSettle();
      final word = textOf(tester, 'Straße');
      expect(word.textDirection, TextDirection.ltr);
      expect(word.style?.fontFamily, AppFonts.german);
      expect(find.text('خیابان، جاده، کوچه (در بعضی شهرها)'), findsOneWidget);
      // A word without meaning shows a status badge instead.
      expect(find.text('Übermüdung'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('browser.results')),
          matching: find.text('بدون معنی'),
        ),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    test('user content in sentences is wrapped in bidi isolates', () {
      expect(bidiIsolate('Hallo!'), '\u2068Hallo!\u2069');
    });
  });
}
