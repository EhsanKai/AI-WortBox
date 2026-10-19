import 'dart:convert';
import 'dart:io';

import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/ai_fakes.dart';
import '../helpers/app_harness.dart';
import '../helpers/test_database.dart';

void main() {
  final start = DateTime.utc(2026, 10, 15, 8);
  late AppDatabase db;
  late Deck deck;
  late DriftVocabularyRepository vocab;

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

  /// A word saved from a scan: no meaning, with its sentence.
  Future<VocabularyEntry> scanned(String word, String context) async {
    await vocab.importEntries(deck.id, [
      ImportCandidate(
        rowNumber: 1,
        draft: VocabularyDraft(
          deckId: deck.id,
          original: word,
          sourceContext: context,
          sourceType: VocabularySourceType.image,
        ),
      ),
    ], DuplicateStrategy.skip);
    return (await vocab.getEntries(deck.id))
        .firstWhere((e) => e.original == word);
  }

  Future<VocabularyEntry> withMeaning(String word, String meaning) =>
      vocab.createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: word,
          meanings: [VocabularyMeaning(meaning)],
        ),
      );

  group('AI settings (bring your own key)', () {
    testWidgets('explains BYOK, links to the key page, saves a hidden key, '
        'tests it, never shows it again, and removes it', (tester) async {
      final store = InMemoryAiSettingsStore();
      final api = FakeOpenRouter(
        keyInfo: keyInfoResponse(usage: 0.0123),
        models: modelsResponse(['anthropic/claude-haiku-5.5']),
      );
      final launched = <Uri>[];
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings',
        aiSettings: store,
        httpClient: api.client,
        launchedUrls: launched,
      );

      expect(find.text('غیرفعال — کلید OpenRouter تنظیم نشده'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.ai')));
      await tester.pumpAndSettle();

      expect(find.textContaining('از حساب OpenRouter خود شما'), findsOneWidget);
      await tester.tap(find.byKey(const Key('ai.getKey')));
      expect(launched, [Uri.parse('https://openrouter.ai/keys')]);

      // Hidden by default; no autocorrect or keyboard learning.
      final field = tester.widget<TextField>(
        find.byKey(const Key('ai.keyField')),
      );
      expect(field.obscureText, isTrue);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.enableIMEPersonalizedLearning, isFalse);

      await tester.enterText(find.byKey(const Key('ai.keyField')), testApiKey);
      await tester.tap(find.byKey(const Key('ai.save')));
      await tester.pumpAndSettle();

      expect(store.apiKey, testApiKey);
      expect(find.byKey(const Key('ai.keyField')), findsNothing);
      expect(find.text('کلید ذخیره‌شده: ••••1234'), findsOneWidget);
      // The full key is not shown anywhere.
      expect(find.textContaining(testApiKey), findsNothing);
      expect(
        find.text('فعال — کلید OpenRouter شما ذخیره شده است'),
        findsOneWidget,
      );
      await scrollTo(tester, find.byKey(const Key('ai.checkResult')));
      expect(find.textContaining('کلید معتبر است'), findsOneWidget);
      expect(find.textContaining('۰٫۰۱۲۳'), findsOneWidget);

      await scrollAndTap(tester, find.byKey(const Key('ai.remove')));
      await tester.tap(find.byKey(const Key('ai.confirmRemove')));
      await tester.pumpAndSettle();
      expect(store.apiKey, isNull);
      await scrollTo(tester, find.byKey(const Key('ai.keyField')));
      expect(find.byKey(const Key('ai.keyField')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('secure-storage failures are shown; no success is claimed', (
      tester,
    ) async {
      final store = InMemoryAiSettingsStore()..failWrites = true;
      final api = FakeOpenRouter(
        keyInfo: keyInfoResponse(),
        models: modelsResponse(['anthropic/claude-haiku-5.5']),
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings/ai',
        aiSettings: store,
        httpClient: api.client,
      );

      // Saving fails: error shown, still "off", no key test sent.
      await tester.enterText(find.byKey(const Key('ai.keyField')), testApiKey);
      await tester.tap(find.byKey(const Key('ai.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai.storageError')), findsOneWidget);
      expect(
        find.text('کلید در فضای امن این دستگاه ذخیره نشد. دوباره تلاش کنید.'),
        findsOneWidget,
      );
      // The typed key stays only in the (obscured) field for another try;
      // it appears in no message.
      expect(find.textContaining(testApiKey), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ai.keyField')))
            .obscureText,
        isTrue,
      );
      expect(find.byKey(const Key('ai.savedKey')), findsNothing);
      expect(find.byKey(const Key('ai.checkResult')), findsNothing);
      expect(store.apiKey, isNull);
      expect(api.requests, isEmpty);

      // Saving works again; then removing fails: error, no "removed"
      // message, key still configured.
      store.failWrites = false;
      await scrollAndTap(tester, find.byKey(const Key('ai.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai.storageError')), findsNothing);
      expect(store.apiKey, testApiKey);

      store.failDeletes = true;
      await scrollAndTap(tester, find.byKey(const Key('ai.remove')));
      await tester.tap(find.byKey(const Key('ai.confirmRemove')));
      await tester.pumpAndSettle();
      expect(store.apiKey, testApiKey);
      await scrollTo(tester, find.byKey(const Key('ai.storageError')));
      expect(
        find.text('کلید از فضای امن این دستگاه حذف نشد. دوباره تلاش کنید.'),
        findsOneWidget,
      );
      expect(find.text('کلید حذف شد.'), findsNothing);
      expect(find.byKey(const Key('ai.savedKey')), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('an invalid key shows an actionable message', (tester) async {
      final api = FakeOpenRouter(keyInfo: errorResponse(401));
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings/ai',
        httpClient: api.client,
      );
      await tester.enterText(find.byKey(const Key('ai.keyField')), testApiKey);
      await tester.tap(find.byKey(const Key('ai.save')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const Key('ai.checkResult')));
      expect(
        find.text(
          'OpenRouter این کلید را نپذیرفت. کلید را بررسی یا جایگزین کنید.',
        ),
        findsOneWidget,
      );
      await unmountApp(tester);
    });

    testWidgets('a malformed key is not saved', (tester) async {
      final store = InMemoryAiSettingsStore();
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings/ai',
        aiSettings: store,
      );
      await tester.enterText(find.byKey(const Key('ai.keyField')), 'sk or');
      await tester.tap(find.byKey(const Key('ai.save')));
      await tester.pumpAndSettle();
      expect(
        find.text('کلید نباید فاصله یا خط جدید داشته باشد.'),
        findsOneWidget,
      );
      expect(store.writes, 0);
      await unmountApp(tester);
    });
  });

  group('enrichment', () {
    testWidgets('without a key: explains setup and sends nothing', (
      tester,
    ) async {
      await scanned('ging', 'Am Morgen ging sie in die Stadt.');
      // Default harness client fails the test on any request.
      await pumpApp(tester, db, initialLocation: '/words/decks/${deck.id}');
      await tester.tap(find.byKey(const Key('deck.enrich')));
      await tester.pumpAndSettle();
      expect(find.text('هوش مصنوعی تنظیم نشده است'), findsOneWidget);
      expect(find.byKey(const Key('enrich.start')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('batch: only words without meanings are sent, reviewed and '
        'saved in one go; review state untouched', (tester) async {
      final ging = await scanned('ging', 'Am Morgen ging sie in die Stadt.');
      final bank = await withMeaning('Bank', 'بانک');
      await db
          .into(db.flashcards)
          .insert(
            FlashcardsCompanion.insert(
              id: 'card',
              entryId: ging.id,
              direction: CardDirection.forward,
              state: CardState.review,
              due: start.add(const Duration(days: 2)),
              createdAt: start,
              updatedAt: start,
              reviewCount: const Value(3),
            ),
          );
      final cardBefore = await db.select(db.flashcards).getSingle();
      final api = FakeOpenRouter(
        completions: [completionResponse(enrichmentContent(), cost: 0)],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );

      // Nothing is sent before the user starts.
      expect(find.byKey(const Key('enrich.privacy')), findsOneWidget);
      expect(find.textContaining('۱ لغت بدون معنی'), findsOneWidget);
      expect(api.requests, isEmpty);

      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 1);
      expect(api.requests.single.body, contains('Am Morgen ging sie'));
      expect(api.requests.single.body, isNot(contains('Bank')));

      expect(find.text('پیشنهاد هوش مصنوعی — بررسی کنید'), findsOneWidget);
      final meaning = tester.widget<CheckboxListTile>(
        find.byKey(Key('enrich.item.${ging.id}.meaning.0')),
      );
      expect(meaning.value, isTrue);

      await tester.tap(find.byKey(const Key('enrich.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('enrich.done')), findsOneWidget);
      // Free-only by default: no cost.
      expect(find.text('مدل‌های رایگان — بدون هزینه'), findsOneWidget);

      final saved = (await vocab.getEntry(ging.id))!;
      expect(saved.original, 'ging');
      expect(saved.sourceContext, 'Am Morgen ging sie in die Stadt.');
      expect(saved.meanings.single.text, 'رفتن');
      expect(saved.lemma, 'gehen');
      expect(saved.enrichmentStatus, EnrichmentStatus.ready);
      expect(saved.enrichmentMetadata?.provider, 'openrouter');
      expect(await vocab.getEntry(bank.id), bank);
      expect(await db.select(db.flashcards).getSingle(), cardBefore);
      await unmountApp(tester);
    });

    testWidgets('offline: the item fails with a clear message and nothing '
        'changes; the user retries', (tester) async {
      final ging = await scanned('ging', 'Am Morgen ging sie in die Stadt.');
      final api = FakeOpenRouter(
        completions: [
          const SocketException('offline'),
          completionResponse(enrichmentContent()),
        ],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      // Not repeated automatically: the request may have been sent.
      expect(api.completionCalls, 1);

      expect(
        find.text(
          'اتصال به اینترنت برقرار نیست. پیشنهاد هوش مصنوعی به اینترنت نیاز دارد.',
        ),
        findsOneWidget,
      );
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('enrich.save')),
      );
      expect(save.onPressed, isNull);
      expect(await vocab.getEntry(ging.id), ging);

      await tester.tap(find.byKey(const Key('enrich.retry')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 2);
      expect(find.text('پیشنهاد هوش مصنوعی — بررسی کنید'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('a timeout is not repeated automatically; the message warns '
        'that it may have been charged; the user can retry', (tester) async {
      final ging = await scanned('ging', 'Am Morgen ging sie in die Stadt.');
      final api = FakeOpenRouter(
        completions: [
          errorResponse(408),
          completionResponse(enrichmentContent()),
        ],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();

      expect(api.completionCalls, 1);
      expect(
        find.textContaining('ممکن است OpenRouter درخواست را پردازش کرده'),
        findsOneWidget,
      );
      expect(await vocab.getEntry(ging.id), ging);

      await tester.tap(find.byKey(const Key('enrich.retry')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 2);
      expect(find.text('پیشنهاد هوش مصنوعی — بررسی کنید'), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('an invalid key stops the batch after the first request', (
      tester,
    ) async {
      await scanned('ging', 'Sie ging.');
      await scanned('Mühe', 'Mit Mühe.');
      final api = FakeOpenRouter(completions: [errorResponse(401)]);
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      // Both words went in one request; nothing more is sent.
      expect(api.completionCalls, 1);
      expect(find.byKey(const Key('enrich.stopError')), findsOneWidget);
      expect(find.text('در صف'), findsNothing);
      expect(find.byKey(const Key('enrich.retry')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('insufficient credits are reported without retrying', (
      tester,
    ) async {
      await scanned('ging', 'Sie ging.');
      final api = FakeOpenRouter(completions: [errorResponse(402)]);
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 1);
      expect(find.textContaining('اعتبار حساب یا سقف این کلید'), findsWidgets);
      await unmountApp(tester);
    });

    testWidgets('the review screen fits at 320 px, 2x text, dark', (
      tester,
    ) async {
      await scanned('Donaudampfschifffahrtsgesellschaft', 'Die Donau…');
      final api = FakeOpenRouter(
        completions: [
          completionResponse(
            enrichmentContent(
              meanings: [
                {'text': 'شرکت کشتیرانی بخار دانوب', 'explanation': 'تاریخی'},
                {'text': 'نمونهٔ کلمهٔ مرکب بلند', 'explanation': null},
              ],
              partOfSpeech: 'noun',
              grammarInfo: 'die, -, -en',
              lemma: null,
              isAmbiguous: true,
            ),
          ),
        ],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
        size: const Size(320, 640),
        textScale: 2,
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        await tester.drag(visibleScrollable(), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    });

    testWidgets('a word with meanings: suggestions are added only after the '
        'user selects them; other entries are untouched', (tester) async {
      final gehen = await withMeaning('gehen', 'رفتن');
      final ging = await withMeaning('ging', 'رفت');
      final api = FakeOpenRouter(
        completions: [
          completionResponse(
            enrichmentContent(
              meanings: [
                {'text': 'رفت', 'explanation': null},
                {'text': 'گذشت', 'explanation': null},
              ],
            ),
          ),
        ],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/entries/${ging.id}',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('entryDetail.enrich')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();

      // Only the genuinely new meaning is offered, unselected.
      final offered = find.byKey(Key('enrich.item.${ging.id}.meaning.0'));
      expect(tester.widget<CheckboxListTile>(offered).value, isFalse);
      expect(find.byKey(Key('enrich.item.${ging.id}.meaning.1')), findsNothing);

      // Deselect the preselected empty fields to save only the meaning.
      for (final field in ['lemma', 'partOfSpeech', 'grammarInfo', 'example']) {
        await scrollAndTap(
          tester,
          find.byKey(Key('enrich.item.${ging.id}.field.$field')),
        );
      }
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('enrich.save')))
            .onPressed,
        isNull,
      );
      await scrollAndTap(tester, offered);
      await tester.tap(find.byKey(const Key('enrich.save')));
      await tester.pumpAndSettle();

      final saved = (await vocab.getEntry(ging.id))!;
      expect(saved.meanings.map((m) => m.text), ['رفت', 'گذشت']);
      expect(saved.lemma, isNull);
      expect(saved.userEditedAt, ging.userEditedAt);
      expect(await vocab.getEntry(gehen.id), gehen);
      await unmountApp(tester);
    });

    testWidgets('a partial batch failure keeps the completed words; retry '
        'sends only the failed word', (tester) async {
      final ging = await scanned('ging', 'Am Morgen ging sie in die Stadt.');
      final muehe = await scanned('Mühe', 'Mit großer Mühe.');
      final api = FakeOpenRouter(
        completions: [
          // Only "ging" was answered.
          completionResponse({
            'items': [
              {'word': 'ging', ...enrichmentContent()},
            ],
          }),
          completionResponse(
            enrichmentContent(
              meanings: [
                {'text': 'زحمت', 'explanation': null},
              ],
              partOfSpeech: 'noun',
              grammarInfo: 'die Mühe, -, -n',
              lemma: null,
            ),
          ),
        ],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 1);
      expect(
        find.descendant(
          of: find.byKey(Key('enrich.item.${ging.id}')),
          matching: find.text('پیشنهاد هوش مصنوعی — بررسی کنید'),
        ),
        findsOneWidget,
      );
      await scrollTo(tester, find.byKey(Key('enrich.item.${muehe.id}.error')));
      expect(find.byKey(Key('enrich.item.${muehe.id}.error')), findsOneWidget);

      await scrollAndTap(tester, find.byKey(const Key('enrich.retry')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 2);
      // Only the failed word is sent again.
      expect(api.requests.last.body, contains('Mühe'));
      expect(api.requests.last.body, isNot(contains('Am Morgen ging')));
      expect(find.text('پیشنهاد هوش مصنوعی — بررسی کنید'), findsNWidgets(2));
      await unmountApp(tester);
    });

    testWidgets('an interrupted run resumes: answered words come from the '
        'cache without a new request', (tester) async {
      final ging = await scanned('ging', 'Am Morgen ging sie in die Stadt.');
      await scanned('Mühe', 'Mit großer Mühe.');
      final api = FakeOpenRouter(
        completions: [
          completionResponse({
            'items': [
              {'word': 'ging', ...enrichmentContent()},
              {
                'word': 'Mühe',
                ...enrichmentContent(
                  meanings: [
                    {'text': 'زحمت', 'explanation': null},
                  ],
                  partOfSpeech: 'noun',
                  grammarInfo: 'die Mühe, -, -n',
                  lemma: null,
                ),
              },
            ],
          }),
        ],
      );
      Future<void> open() => pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await open();
      expect(find.byKey(const Key('enrich.resume')), findsNothing);
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 1);
      // The app is closed before saving.
      await unmountApp(tester);

      await open();
      expect(find.byKey(const Key('enrich.resume')), findsOneWidget);
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 1);
      expect(find.byKey(Key('enrich.item.${ging.id}.cached')), findsOneWidget);

      await tester.tap(find.byKey(const Key('enrich.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('enrich.done')), findsOneWidget);
      expect((await vocab.getEntry(ging.id))!.meanings.single.text, 'رفتن');
      await unmountApp(tester);

      // Finished: no resume offer any more.
      await open();
      expect(find.byKey(const Key('enrich.resume')), findsNothing);
      await unmountApp(tester);
    });

    testWidgets('a used-up daily free quota stops the run and is explained', (
      tester,
    ) async {
      await scanned('ging', 'Sie ging.');
      final api = FakeOpenRouter(
        completions: [
          errorResponse(
            429,
            message: 'Rate limit exceeded: free-models-per-day',
            headers: {'x-ratelimit-limit': '50', 'x-ratelimit-remaining': '0'},
          ),
        ],
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/words/decks/${deck.id}/enrich',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await tester.tap(find.byKey(const Key('enrich.start')));
      await tester.pumpAndSettle();
      expect(api.completionCalls, 1);
      expect(find.byKey(const Key('enrich.stopError')), findsOneWidget);
      expect(
        find.textContaining('درخواست‌های رایگان امروزِ حساب OpenRouter'),
        findsWidgets,
      );
      expect(find.byKey(const Key('enrich.retry')), findsNothing);
      await unmountApp(tester);
    });
  });

  group('free usage settings', () {
    testWidgets('free-only is on by default; the routing mode and batch size '
        'are saved; paid models need an explicit confirmation', (tester) async {
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings/ai',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
      );
      await scrollTo(tester, find.byKey(const Key('ai.freeOnly')));
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('ai.freeOnly')))
            .value,
        isTrue,
      );
      // The paid model choice is hidden in free-only mode.
      expect(find.byKey(const Key('ai.model')), findsNothing);
      expect(find.text('مدل فعلی: openrouter/free'), findsOneWidget);
      expect(find.text('هنوز درخواستی فرستاده نشده است.'), findsOneWidget);
      expect(find.byKey(const Key('ai.rateStatus')), findsOneWidget);
      expect(find.textContaining('هنوز بررسی نشده است'), findsOneWidget);

      await tester.tap(find.text('رایگان باکیفیت'));
      await tester.pumpAndSettle();
      // No verified list yet: the free router is used (and said so).
      expect(find.byKey(const Key('ai.qualityUnverified')), findsOneWidget);

      await scrollAndTap(tester, find.byKey(const Key('ai.batchSize')));
      await tester.tap(find.text('۳').last);
      await tester.pumpAndSettle();

      final settings = await db.select(db.appSettings).get();
      final values = {for (final r in settings) r.key: r.value};
      expect(values['ai.routing'], 'qualityFree');
      expect(values['ai.wordsPerRequest'], '3');

      // Turning free-only off asks first; cancelling keeps it on.
      await scrollAndTap(tester, find.byKey(const Key('ai.freeOnly')));
      expect(find.byKey(const Key('ai.confirmPaid')), findsOneWidget);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ai.model')), findsNothing);

      await scrollAndTap(tester, find.byKey(const Key('ai.freeOnly')));
      await tester.tap(find.byKey(const Key('ai.confirmPaid')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const Key('ai.model')));
      expect(find.byKey(const Key('ai.model')), findsOneWidget);
      expect(
        (await (db.select(
          db.appSettings,
        )..where((s) => s.key.equals('ai.freeOnly'))).getSingle()).value,
        'false',
      );
      await unmountApp(tester);
    });

    testWidgets('refresh shows the free requests left and verified models', (
      tester,
    ) async {
      final api = FakeOpenRouter(
        keyInfo: http.Response(
          jsonEncode({
            'data': {
              'usage': 0,
              'is_free_tier': true,
              'free_model_daily_requests': {
                'used': 8,
                'limit': 50,
                'remaining': 42,
              },
            },
          }),
          200,
        ),
        models: modelsResponse([
          'openrouter/free',
          'google/gemma-4-31b-it:free',
          'openai/gpt-5-mini',
        ]),
      );
      await pumpApp(
        tester,
        db,
        initialLocation: '/settings/ai',
        aiSettings: InMemoryAiSettingsStore(apiKey: testApiKey),
        httpClient: api.client,
      );
      await scrollAndTap(tester, find.byKey(const Key('ai.refreshUsage')));
      await tester.pumpAndSettle();
      expect(
        find.text('حدود ۴۲ از ۵۰ درخواست رایگان امروز باقی مانده است'),
        findsOneWidget,
      );
      // The key went only to OpenRouter's key endpoint.
      final keyCall = api.requests.firstWhere(
        (r) => r.url.path.endsWith('/key'),
      );
      expect(keyCall.url.host, 'openrouter.ai');
      expect(find.textContaining(testApiKey), findsNothing);
      await unmountApp(tester);
    });
  });
}
