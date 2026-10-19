import 'dart:convert';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/csv_import/data/csv_file_source.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/tags/data/drift_tag_repository.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/fixtures.dart';
import '../helpers/phase5_fakes.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  late Deck other;
  late DriftVocabularyRepository vocab;
  late DriftTagRepository tags;
  late VocabularyEntry haus;
  final clock = FixedClock(DateTime.utc(2026, 10, 19, 8));

  setUp(() async {
    db = openTestDatabase();
    final decks = DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    );
    deck = await decks.createDeck(const DeckDraft(name: 'Kafka'));
    other = await decks.createDeck(const DeckDraft(name: 'Reise'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('seed'),
    );
    tags = DriftTagRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('t'),
    );
    haus = await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'das Haus',
        meanings: const [VocabularyMeaning('خانه')],
        exampleSentence: 'Das Haus ist alt.',
      ),
    );
    await vocab.createEntry(
      VocabularyDraft(
        deckId: other.id,
        original: 'der Bahnhof',
        meanings: const [VocabularyMeaning('ایستگاه قطار')],
      ),
    );
  });
  tearDown(() => db.close());

  Finder text(String value) => find.text(value);

  // Drift `watch(...).first` does not complete inside widget tests' fake
  // async zone; one-shot queries do.
  Future<Map<String, List<String>>> tagNames(String deckId) =>
      tags.getTagNamesForDeck(deckId);

  group('search and filters (A, G)', () {
    testWidgets('search across decks by Persian and German; difficult '
        'filter; clearing restores the list', (tester) async {
      await vocab.setDifficult(haus.id, difficult: true);
      await pumpApp(tester, db, initialLocation: '/words');
      await tester.tap(find.byKey(const Key('decks.search')));
      await tester.pumpAndSettle();

      expect(text('das Haus'), findsOneWidget);
      expect(text('der Bahnhof'), findsOneWidget);
      // Each result names its deck.
      expect(find.textContaining('Reise'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('browser.search')), 'قطار');
      await tester.pumpAndSettle();
      expect(text('der Bahnhof'), findsOneWidget);
      expect(text('das Haus'), findsNothing);

      await tester.enterText(find.byKey(const Key('browser.search')), 'xyz');
      await tester.pumpAndSettle();
      expect(text('لغتی با این عبارت پیدا نشد.'), findsOneWidget);
      expect(text('das Haus'), findsNothing);
      expect(text('der Bahnhof'), findsNothing);

      await tester.tap(find.byKey(const Key('browser.clearAll')));
      await tester.pumpAndSettle();
      expect(text('das Haus'), findsOneWidget);
      expect(text('der Bahnhof'), findsOneWidget);

      await tester.tap(find.byKey(const Key('browser.difficult')));
      await tester.pumpAndSettle();
      expect(text('das Haus'), findsOneWidget);
      expect(text('der Bahnhof'), findsNothing);
      expect(find.byKey(Key('entry.${haus.id}.difficult')), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('word page: difficult mark, tags, pronunciation (B, D, G)', () {
    testWidgets('mark difficult, add a new tag, filter the deck by it', (
      tester,
    ) async {
      final speech = FakeSpeechService();
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/entries/${haus.id}',
        speech: speech,
      );

      await tester.tap(find.byKey(const Key('entryDetail.difficult')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('entryDetail.difficultBadge')),
        findsOneWidget,
      );
      expect((await vocab.getEntry(haus.id))!.isDifficult, isTrue);

      await tester.tap(find.byKey(const Key('entryDetail.speakWord')));
      await tester.pumpAndSettle();
      expect(speech.spoken, [('das Haus', Language.german)]);

      await scrollAndTap(tester, find.byKey(const Key('entryDetail.editTags')));
      await tester.enterText(find.byKey(const Key('entryTags.newName')), 'B1');
      await tester.tap(find.byKey(const Key('entryTags.create')));
      await tester.pumpAndSettle();
      // A duplicate name (other case) is rejected with a message.
      await tester.enterText(find.byKey(const Key('entryTags.newName')), 'b1');
      await tester.tap(find.byKey(const Key('entryTags.create')));
      await tester.pumpAndSettle();
      expect(text('برچسبی با همین نام وجود دارد.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('entryTags.save')));
      await tester.pumpAndSettle();

      expect(await tagNames(deck.id), {
        haus.id: ['B1'],
      });
      final tagId = (await db.select(db.tags).getSingle()).id;
      await scrollTo(tester, find.byKey(Key('entryDetail.tag.$tagId')));
      expect(find.byKey(Key('entryDetail.tag.$tagId')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('missing German voice is reported without crashing', (
      tester,
    ) async {
      final speech = FakeSpeechService()
        ..failWith = SpeechError.voiceUnavailable;
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/entries/${haus.id}',
        speech: speech,
      );
      await tester.tap(find.byKey(const Key('entryDetail.speakWord')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('صدای آلمانی روی این دستگاه نصب نیست'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });

    testWidgets('tag filter in a deck, and deleting a tag keeps the word', (
      tester,
    ) async {
      final b1 = await tags.createTag('B1');
      await tags.setEntryTags(haus.id, {b1.id});
      await vocab.createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: 'der Baum',
          meanings: const [VocabularyMeaning('درخت')],
        ),
      );
      await pumpApp(tester, db, initialLocation: '/words/decks/${deck.id}');
      expect(text('der Baum'), findsOneWidget);
      await tester.tap(find.byKey(const Key('browser.tag')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('browser.tag.${b1.id}')));
      await tester.pumpAndSettle();
      expect(text('das Haus'), findsOneWidget);
      expect(text('der Baum'), findsNothing);
      await unmountApp(tester);

      await pumpApp(tester, db, initialLocation: '/words/tags');
      await tester.tap(find.byKey(Key('tags.${b1.id}.delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('خود لغت‌ها حذف نمی‌شوند'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tags.confirmDelete')));
      await tester.pumpAndSettle();
      expect(await db.select(db.tags).get(), isEmpty);
      expect(await vocab.getEntry(haus.id), isNotNull);
      await unmountApp(tester);
    });
  });

  group('practice and statistics (F, H)', () {
    testWidgets('Persian → German practice records outcomes; statistics '
        'and streak update', (tester) async {
      await pumpApp(tester, db, initialLocation: '/statistics', clock: clock);
      expect(find.byKey(const Key('stats.empty')), findsOneWidget);
      await unmountApp(tester);

      await pumpApp(tester, db, initialLocation: '/today', clock: clock);
      await tester.tap(find.byKey(const Key('today.practice')));
      await tester.pumpAndSettle();
      // Persian → German as free practice (German → Persian scheduled review
      // is the default; see review_flow_test.dart).
      await scrollAndTap(
        tester,
        find.byKey(const Key('reviewDirection.persianToGerman')),
      );
      await scrollAndTap(tester, find.byKey(const Key('practice.free')));
      await scrollAndTap(tester, find.byKey(const Key('practice.start')));

      // Two words with meanings: the Persian side is shown first, the
      // German word is hidden.
      expect(find.byKey(const Key('practice.meaning')), findsOneWidget);
      expect(find.byKey(const Key('practice.word')), findsNothing);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('practice.reveal')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('practice.word')), findsOneWidget);
        await scrollAndTap(
          tester,
          find.byKey(
            Key(i == 0 ? 'practice.remembered' : 'practice.forgotten'),
          ),
        );
      }
      expect(find.byKey(const Key('practice.summary')), findsOneWidget);
      final events = await db.select(db.reviewEvents).get();
      expect(events, hasLength(2));

      await tester.tap(find.byKey(const Key('practice.finish')));
      await tester.pumpAndSettle();
      // The Today tile now shows the streak.
      expect(find.textContaining('روز پیاپی تمرین'), findsOneWidget);
      await unmountApp(tester);

      await pumpApp(tester, db, initialLocation: '/statistics', clock: clock);
      expect(find.byKey(const Key('stats.empty')), findsNothing);
      expect(find.byKey(const Key('stats.streak')), findsOneWidget);
      expect(find.byKey(const Key('stats.reviews')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('revealed answer and filled statistics fit at 320 px, 2x, '
        'dark', (tester) async {
      await vocab.updateEntry(
        haus.id,
        VocabularyDraft(
          deckId: deck.id,
          original: 'Donaudampfschifffahrtsgesellschaftskapitän',
          lemma: 'Donaudampfschifffahrtsgesellschaftskapitän',
          grammarInfo: 'der, -s, -e',
          exampleSentence: 'Der Kapitän sagte: „Wir fahren um 7.30 Uhr ab!“',
          meanings: const [
            VocabularyMeaning('ناخدای شرکت کشتیرانی بخار دانوب'),
            VocabularyMeaning('(شوخی) نمونهٔ کلمهٔ مرکب بسیار بلند'),
          ],
        ),
      );
      Future<void> narrow(String location) => pumpApp(
        tester,
        db,
        initialLocation: location,
        size: const Size(320, 640),
        textScale: 2,
        brightness: Brightness.dark,
        clock: clock,
      );
      await narrow('/today/practice/session?deckId=${deck.id}');
      await scrollAndTap(tester, find.byKey(const Key('practice.reveal')));
      await scrollAndTap(tester, find.byKey(const Key('practice.remembered')));
      expect(tester.takeException(), isNull);
      await unmountApp(tester);

      await narrow('/statistics');
      for (var i = 0; i < 8; i++) {
        await tester.drag(visibleScrollable(), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('stats.empty')), findsNothing);
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });

    testWidgets('difficult-only practice with no difficult words explains '
        'how to mark them', (tester) async {
      await pumpApp(
        tester,
        db,
        initialLocation: '/today/practice/session?difficult=1',
      );
      expect(find.textContaining('دشوار علامت بزنید'), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('reminder (E)', () {
    testWidgets('permission denied is explained and the reminder stays off; '
        'when allowed it is scheduled once', (tester) async {
      final reminders = FakeReminderScheduler()..grantPermission = false;
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings/reminder',
        reminders: reminders,
      );
      await tester.tap(find.byKey(const Key('reminder.enabled')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder.error')), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('reminder.enabled')))
            .value,
        isFalse,
      );
      expect(reminders.scheduled, isEmpty);

      reminders.grantPermission = true;
      await tester.tap(find.byKey(const Key('reminder.enabled')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reminder.error')), findsNothing);
      expect(reminders.scheduled.keys, [1]);

      await tester.tap(find.byKey(const Key('reminder.enabled')));
      await tester.pumpAndSettle();
      expect(reminders.scheduled, isEmpty);
      await unmountApp(tester);
    });
  });

  group('export (C, I)', () {
    testWidgets('CSV and Anki exports from the deck menu', (tester) async {
      final b1 = await tags.createTag('B1');
      await tags.setEntryTags(haus.id, {b1.id});
      final sink = FakeExportSink();
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}',
        exportSink: sink,
        clock: clock,
      );

      await tester.tap(find.byKey(const Key('deck.menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deck.exportCsv')));
      await tester.pumpAndSettle();
      expect(find.text('فایل ذخیره شد.'), findsOneWidget);
      final (csvName, csvBytes, csvType) = sink.saved.single;
      expect(csvName, 'AI WortBox - Kafka - 2026-10-19.csv');
      expect(csvType, 'text/csv');
      final csv = utf8.decode(csvBytes.skip(3).toList());
      expect(csv, contains('das Haus,خانه,,,,Das Haus ist alt.,,,B1'));
      expect(csv, isNot(contains('Bahnhof'))); // other deck

      await tester.tap(find.byKey(const Key('deck.menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('deck.exportAnki')));
      await tester.pumpAndSettle();
      final (ankiName, ankiBytes, _) = sink.saved.last;
      expect(ankiName, endsWith('.apkg'));
      final zip = ZipDecoder().decodeBytes(ankiBytes);
      expect(zip.findFile('collection.anki2'), isNotNull);
      await unmountApp(tester);
    });

    testWidgets('cancelled save, failed save and empty deck', (tester) async {
      final empty = await DriftDeckRepository(
        db,
        clock: clock,
        ids: SequentialIdGenerator('e'),
      ).createDeck(const DeckDraft(name: 'Leer'));
      final sink = FakeExportSink()..cancel = true;
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}',
        exportSink: sink,
      );
      Future<void> exportCsv() async {
        await tester.tap(find.byKey(const Key('deck.menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('deck.exportCsv')));
        await tester.pumpAndSettle();
      }

      await exportCsv();
      expect(find.text('ذخیرهٔ فایل لغو شد.'), findsOneWidget);
      sink
        ..cancel = false
        ..fail = true;
      await exportCsv();
      expect(find.textContaining('فایل ذخیره نشد'), findsOneWidget);
      await unmountApp(tester);

      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${empty.id}',
        exportSink: sink,
      );
      await exportCsv();
      expect(find.text('این دسته لغتی برای خروجی ندارد.'), findsOneWidget);
      expect(sink.saved, isEmpty);
      await unmountApp(tester);
    });
  });

  group('Anki import (I)', () {
    testWidgets('a package exported by Anki is imported through the normal '
        'preview, with meanings and tags', (tester) async {
      await pumpApp(
        tester,
        db,
        initialLocation: '/add',
        fileSource: FakeCsvFileSource(
          PickedCsvFile(
            name: 'Deutsch.apkg',
            bytes: ankiFixture('modern_anki21b.apkg'),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('add.anki')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('csv.pickFile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('csv.ankiFile')), findsOneWidget);
      expect(find.byKey(const Key('csv.delimiter')), findsNothing);
      await scrollAndTap(tester, find.byKey(const Key('csv.confirmLanguages')));
      await scrollAndTap(tester, find.byKey(const Key('csv.import')));
      expect(find.byKey(const Key('csv.result')), findsOneWidget);

      // Imported into the preselected deck, which already has "das Haus"
      // with "خانه": that note's extra meaning is a different-meaning
      // duplicate and is skipped by the default strategy, not merged.
      final imported = {
        for (final e in await vocab.getEntries(deck.id)) e.original: e,
      };
      expect(
        imported.keys,
        containsAll(['das Haus', 'gehen', 'die Mühe', 'sich freuen']),
      );
      expect(await vocab.getEntry(haus.id), haus);
      expect(imported['gehen']!.meanings.map((m) => m.text), [
        'رفتن / راه رفتن',
      ]);
      expect(imported['gehen']!.sourceType, VocabularySourceType.csv);
      expect((await tagNames(deck.id))[imported['sich freuen']!.id], [
        'Verben',
      ]);
      await unmountApp(tester);
    });

    testWidgets('a file that is not an Anki package shows a clear error', (
      tester,
    ) async {
      await pumpApp(
        tester,
        db,
        initialLocation: '/add/anki',
        fileSource: FakeCsvFileSource(
          PickedCsvFile(
            name: 'broken.apkg',
            bytes: ZipEncoder().encodeBytes(
              Archive()..add(ArchiveFile.bytes('media', utf8.encode('{}'))),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('csv.pickFile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('csv.fileError')), findsOneWidget);
      expect(find.textContaining('بستهٔ Anki'), findsWidgets);
      await unmountApp(tester);
    });
  });
}
