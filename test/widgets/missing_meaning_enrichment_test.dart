import 'dart:async';
import 'dart:convert';

import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/enrichment/presentation/enrichment_controller.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/ai_fakes.dart';
import '../helpers/app_harness.dart';
import '../helpers/test_database.dart';

/// "Missing meaning" filter, multi-selection and batch AI meanings for the
/// selected words (meanings-only requests through the existing BYOK
/// enrichment).
void main() {
  final start = DateTime.utc(2026, 10, 15, 8);
  late AppDatabase db;
  late Deck deck;
  late DriftVocabularyRepository vocab;

  const persian = {
    'Apfel': 'سیب',
    'Baum': 'درخت',
    'Dach': 'بام',
    'Ei': 'تخم‌مرغ',
    'Feld': 'مزرعه',
    'Garten': 'باغ',
    'Hund': 'سگ',
    'Insel': 'جزیره',
    'Jacke': 'کت',
    'Katze': 'گربه',
  };

  setUp(() async {
    db = openTestDatabase();
    final clock = FixedClock(start);
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Buch'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('seed'),
    );
  });
  tearDown(() => db.close());

  Future<VocabularyEntry> add(String word, [String? meaning]) =>
      vocab.createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: word,
          meanings: [if (meaning != null) VocabularyMeaning(meaning)],
        ),
      );

  /// Words of the last request, as sent.
  List<Map<String, Object?>> sentWords(FakeOpenRouter api, [int? index]) {
    final completions = [
      for (final r in api.requests)
        if (r.url.path.endsWith('/chat/completions')) r,
    ];
    final body =
        jsonDecode(completions[index ?? completions.length - 1].body) as Map;
    final user = jsonDecode(
      ((body['messages']! as List).last as Map)['content']! as String,
    );
    return [
      for (final w in (user as Map)['words'] as List)
        (w as Map).cast<String, Object?>(),
    ];
  }

  /// Answers the words of the request just sent, in reverse order, leaving
  /// out [skip].
  Future<http.Response> Function() answer(
    FakeOpenRouter api, {
    Set<String> skip = const {},
  }) =>
      () async => completionResponse({
        'items': [
          for (final w in sentWords(api).reversed)
            if (!skip.contains(w['word']))
              {
                'id': w['id'],
                'word': w['word'],
                'meanings': [
                  {'text': persian[w['word']], 'explanation': null},
                ],
                'isAmbiguous': false,
              },
        ],
      }, cost: 0);

  String fa(int n) => '$n'.replaceAllMapped(
    RegExp('[0-9]'),
    (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)],
  );

  String selectedCount(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('browser.selectedCount'))).data!;

  IconButton iconButton(WidgetTester tester, String key) =>
      tester.widget<IconButton>(find.byKey(Key(key)));

  testWidgets('filter, select all/clear/deselect, then 10 words get meanings '
      'in 2 requests; edits and rejections are honoured; nothing else '
      'changes', (tester) async {
    final entries = {for (final w in persian.keys) w: await add(w)};
    final bank = await add('Bank', 'بانک');
    await db
        .into(db.flashcards)
        .insert(
          FlashcardsCompanion.insert(
            id: 'card',
            entryId: entries['Apfel']!.id,
            direction: CardDirection.forward,
            state: CardState.review,
            due: start.add(const Duration(days: 3)),
            createdAt: start,
            updatedAt: start,
            reviewCount: const Value(4),
          ),
        );
    final cardBefore = await db.select(db.flashcards).getSingle();
    final api = FakeOpenRouter();
    api.completions = [answer(api), answer(api)];
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/search',
      aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
      httpClient: api.client,
    );
    final apfel = find.byKey(Key('browser.entry.${entries['Apfel']!.id}'));
    expect(find.byKey(Key('browser.entry.${bank.id}')), findsOneWidget);

    await tester.tap(find.byKey(const Key('browser.missingMeaning')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('browser.missingMeaning')),
        matching: find.text('بدون معنی'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(Key('browser.entry.${bank.id}')), findsNothing);
    expect(apfel, findsOneWidget);

    // Selection: long-press, select all, clear, deselect and reselect.
    await tester.longPress(apfel);
    await tester.pumpAndSettle();
    expect(selectedCount(tester), '${fa(1)} انتخاب‌شده');
    await tester.tap(find.byKey(const Key('browser.selectAll')));
    await tester.pumpAndSettle();
    expect(selectedCount(tester), '${fa(10)} انتخاب‌شده');
    await tester.tap(find.byKey(const Key('browser.clearSelection')));
    await tester.pumpAndSettle();
    expect(selectedCount(tester), '${fa(0)} انتخاب‌شده');
    expect(iconButton(tester, 'browser.enrichSelected').onPressed, isNull);
    await tester.tap(find.byKey(const Key('browser.selectAll')));
    await tester.pumpAndSettle();
    await tester.tap(apfel);
    await tester.pumpAndSettle();
    expect(selectedCount(tester), '${fa(9)} انتخاب‌شده');
    await tester.tap(apfel);
    await tester.pumpAndSettle();
    expect(selectedCount(tester), '${fa(10)} انتخاب‌شده');

    await tester.tap(find.byKey(const Key('browser.enrichSelected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('enrich.privacy')), findsOneWidget);
    expect(find.textContaining('${fa(10)} لغت انتخاب‌شده'), findsOneWidget);
    expect(find.byKey(const Key('enrich.excluded')), findsNothing);
    // Nothing is sent before the user starts.
    expect(api.requests, isEmpty);

    await tester.tap(find.byKey(const Key('enrich.start')));
    await tester.pumpAndSettle();
    // 10 words, 5 per request (the default): 2 requests instead of 10.
    expect(api.completionCalls, 2);
    for (final i in [0, 1]) {
      expect(sentWords(api, i), hasLength(5));
    }
    expect({
      for (final i in [0, 1])
        for (final w in sentWords(api, i)) w['word'],
    }, persian.keys.toSet());
    for (final r in api.requests) {
      expect(r.body, contains('vocabulary_meanings'));
      expect(r.body, isNot(contains('Bank')));
      expect(r.body, isNot(contains(testApiKey)));
    }

    // Correct one suggestion, reject another.
    final apfelId = entries['Apfel']!.id;
    final baumId = entries['Baum']!.id;
    await scrollAndTap(
      tester,
      find.byKey(Key('enrich.item.$apfelId.meaning.0.edit')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('enrich.editField')), '   ');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('enrich.editSave')))
          .onPressed,
      isNull,
      reason: 'a blank meaning cannot be saved',
    );
    await tester.enterText(
      find.byKey(const Key('enrich.editField')),
      'سیب سرخ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('enrich.editSave')));
    await tester.pumpAndSettle();
    expect(find.text('سیب سرخ'), findsOneWidget);
    expect(
      find.byKey(Key('enrich.item.$apfelId.meaning.0.edited')),
      findsOneWidget,
    );
    await scrollAndTap(
      tester,
      find.byKey(Key('enrich.item.$baumId.meaning.0')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(Key('enrich.item.$baumId.meaning.0')),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('enrich.save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('enrich.done')), findsOneWidget);

    for (final MapEntry(key: word, value: entry) in entries.entries) {
      final saved = (await vocab.getEntry(entry.id))!;
      switch (word) {
        case 'Apfel':
          expect(saved.meanings.single.text, 'سیب سرخ');
        case 'Baum':
          expect(saved.meanings, isEmpty);
          expect(saved, entry, reason: 'a rejected word is not touched');
        default:
          expect(saved.meanings.single.text, persian[word]);
      }
      if (word != 'Baum') {
        expect(saved.enrichmentStatus, EnrichmentStatus.ready);
        expect(saved.enrichmentMetadata?.model, isNotEmpty);
        // Nothing but the meaning was requested or saved.
        expect(saved.lemma, isNull);
        expect(saved.exampleSentence, isNull);
        expect(saved.grammarInfo, isNull);
      }
    }
    expect(await vocab.getEntry(bank.id), bank);
    expect(await db.select(db.flashcards).getSingle(), cardBefore);
    expect(await db.select(db.reviewEvents).get(), isEmpty);

    // Back in the list: selection ended; only the rejected word is still
    // missing a meaning.
    await tester.tap(find.byKey(const Key('enrich.backToWords')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browser.selectionBar')), findsNothing);
    expect(find.byKey(Key('browser.entry.$baumId')), findsOneWidget);
    expect(apfel, findsNothing);
    await unmountApp(tester);
  });

  testWidgets('selected words that already have a meaning are left out and '
      'never changed; a selection with only such words sends nothing', (
    tester,
  ) async {
    final bank = await add('Bank', 'بانک');
    final hund = await add('Hund');
    final api = FakeOpenRouter();
    api.completions = [answer(api)];
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/search',
      aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
      httpClient: api.client,
    );

    // Only the word with a meaning.
    await tester.longPress(find.byKey(Key('browser.entry.${bank.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.enrichSelected')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('هیچ‌کدام از لغت‌های انتخاب‌شده'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('enrich.start')), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Both words: only the one without a meaning is sent.
    await tester.longPress(find.byKey(Key('browser.entry.${bank.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.selectAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.enrichSelected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('enrich.excluded')), findsOneWidget);
    expect(find.byKey(Key('enrich.item.${bank.id}')), findsNothing);
    await tester.tap(find.byKey(const Key('enrich.start')));
    await tester.pumpAndSettle();
    expect(api.completionCalls, 1);
    expect(sentWords(api).map((w) => w['word']), ['Hund']);
    expect(api.requests.single.body, isNot(contains('بانک')));
    await tester.tap(find.byKey(const Key('enrich.save')));
    await tester.pumpAndSettle();
    expect((await vocab.getEntry(hund.id))!.meanings.single.text, 'سگ');
    expect(await vocab.getEntry(bank.id), bank);
    await unmountApp(tester);
  });

  testWidgets('an unusable batch answer is split once into smaller '
      'requests; a word missing from an answer fails alone and retry sends '
      'only that word', (tester) async {
    final entries = [
      for (final w in ['Dach', 'Ei', 'Feld', 'Garten']) await add(w),
    ];
    final api = FakeOpenRouter();
    Future<http.Response> respond() async {
      final words = sentWords(api);
      if (words.length == 4) return completionResponse('{"items": [');
      // "Dach" is left out of every answer except when sent alone.
      return answer(api, skip: words.length > 1 ? {'Dach'} : const {})();
    }

    api.completions = List.filled(8, respond);
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/search',
      aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
      httpClient: api.client,
    );
    await tester.longPress(find.byKey(Key('browser.entry.${entries[0].id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.selectAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.enrichSelected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enrich.start')));
    await tester.pumpAndSettle();

    final sizes = [
      for (var i = 0; i < api.completionCalls; i++) sentWords(api, i).length,
    ];
    // The 4-word answer was cut off (one free fallback attempt too); then
    // two requests of 2 words each.
    expect(sizes.where((n) => n == 4), isNotEmpty);
    expect(sizes.skipWhile((n) => n == 4), [2, 2]);
    final dach = entries[0].id;
    await scrollTo(tester, find.byKey(Key('enrich.item.$dach.error')));
    expect(find.byKey(Key('enrich.item.$dach.error')), findsOneWidget);
    for (final e in entries.skip(1)) {
      final meaning = find.byKey(Key('enrich.item.${e.id}.meaning.0'));
      await scrollTo(tester, meaning);
      expect(meaning, findsOneWidget);
    }

    final before = api.completionCalls;
    await scrollAndTap(tester, find.byKey(const Key('enrich.retry')));
    await tester.pumpAndSettle();
    expect(api.completionCalls, before + 1);
    expect(sentWords(api).map((w) => w['word']), ['Dach']);
    expect(find.byKey(Key('enrich.item.$dach.error')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a word another run is requesting is not sent twice', (
    tester,
  ) async {
    final hund = await add('Hund');
    final katze = await add('Katze');
    final jobs = EnrichmentJobRegistry()..claim([hund.id]);
    final api = FakeOpenRouter();
    api.completions = [answer(api), answer(api)];
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/search',
      aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
      httpClient: api.client,
      enrichmentJobs: jobs,
    );
    await tester.longPress(find.byKey(Key('browser.entry.${hund.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.selectAll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.enrichSelected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enrich.start')));
    await tester.pumpAndSettle();
    expect(sentWords(api).map((w) => w['word']), ['Katze']);
    expect(
      find.textContaining('این لغت در اجرای دیگری در حال درخواست است'),
      findsOneWidget,
    );
    // This run released its own words; the other run still holds "Hund".
    expect(jobs.isBusy(katze.id), isFalse);
    expect(jobs.isBusy(hund.id), isTrue);

    // When the other run has finished, retrying sends it.
    jobs.release([hund.id]);
    await scrollAndTap(tester, find.byKey(const Key('enrich.retry')));
    await tester.pumpAndSettle();
    expect(sentWords(api).map((w) => w['word']), ['Hund']);
    await unmountApp(tester);
  });

  testWidgets('stopping a running request saves nothing and frees the words', (
    tester,
  ) async {
    final hund = await add('Hund');
    final reply = Completer<http.Response>();
    final jobs = EnrichmentJobRegistry();
    final api = FakeOpenRouter(completions: [() => reply.future]);
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/search',
      aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
      httpClient: api.client,
      enrichmentJobs: jobs,
    );
    await tester.longPress(find.byKey(Key('browser.entry.${hund.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('browser.enrichSelected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enrich.start')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(api.completionCalls, 1);
    expect(jobs.isBusy(hund.id), isTrue);
    expect(find.byKey(const Key('enrich.progressDetail')), findsOneWidget);

    await tester.tap(find.byKey(const Key('enrich.cancel')));
    await tester.pumpAndSettle();
    expect(jobs.isBusy(hund.id), isFalse);
    expect(find.byKey(const Key('enrich.save')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('enrich.save')))
          .onPressed,
      isNull,
    );
    reply.complete(answer(api)());
    await tester.pumpAndSettle();
    expect((await vocab.getEntry(hund.id))!.meanings, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('the filter chips and selection bar fit at 320 px, 2x text', (
    tester,
  ) async {
    final hund = await add('Hund');
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/search',
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.tap(find.byKey(const Key('browser.missingMeaning')));
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(Key('browser.entry.${hund.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browser.enrichSelected')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });
}
