import 'dart:convert';
import 'dart:io';

import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_practice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/ai_fakes.dart';
import '../helpers/app_harness.dart';
import '../helpers/learning_data.dart';
import '../helpers/sentence_fakes.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeOpenRouter api;

  setUp(() {
    db = openTestDatabase();
    api = FakeOpenRouter();
  });
  tearDown(() => db.close());

  // gehen is marked difficult, so it comes first; Haus was practised
  // recently (seed), so it comes last. "ohne Bedeutung" has no meaning.
  final generated = completionResponse({
    'items': [gehenItem('1'), hausItem('2')],
  });

  Future<void> open(
    WidgetTester tester, {
    String location = '/today/sentences',
    Locale locale = const Locale('fa'),
    bool withKey = true,
  }) => pumpApp(
    tester,
    db,
    initialLocation: location,
    httpClient: api.client,
    aiSettings: InMemoryAiSettingsStore(apiKey: withKey ? testApiKey : null),
    locale: locale,
  );

  Future<void> start(WidgetTester tester) =>
      scrollAndTap(tester, find.byKey(const Key('sp.start')));

  Future<void> tapKey(WidgetTester tester, String key) =>
      scrollAndTap(tester, find.byKey(Key(key)));

  testWidgets('Today → sentence practice: generate, answer, check, reveal, '
      'finish; FSRS state, review history and words are unchanged', (
    tester,
  ) async {
    await seedLearningData(db);
    final before = await dumpLearningData(db);
    api.completions = [generated, completionResponse(feedbackContent())];
    await open(tester, location: '/today');

    await scrollAndTap(tester, find.byKey(const Key('today.sentences')));
    expect(find.byKey(const Key('sp.separateNote')), findsOneWidget);
    expect(api.requests, isEmpty, reason: 'nothing is sent before Start');
    await start(tester);

    // Exercise 1: the Persian sentence; the German answer stays hidden.
    expect(find.text('تمرین 1 از 2'), findsNothing);
    expect(find.byKey(const Key('sp.progress')), findsOneWidget);
    expect(find.text('دیروز زود به خانه رفتم.'), findsOneWidget);
    expect(find.text('Gestern ging ich früh nach Hause.'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('sp.targetWord')),
        matching: find.text('gehen'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('sp.answer')),
      'Gestern ging ich früh nach hause.',
    );
    await tester.pump();
    await tapKey(tester, 'sp.check');
    expect(find.byKey(const Key('sp.feedback')), findsOneWidget);
    expect(find.byKey(const Key('sp.verdict')), findsOneWidget);
    expect(find.text('خطاهای کوچک'), findsOneWidget);
    expect(find.text('حرف بزرگ'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('sp.modelAnswerText')));
    expect(find.text('Gestern ging ich früh nach Hause.'), findsOneWidget);
    await tapKey(tester, 'sp.next');

    // Exercise 2: reveal without checking.
    expect(find.text('خانهٔ ما باغ بزرگی دارد.'), findsOneWidget);
    expect(find.text('Unser Haus hat einen großen Garten.'), findsNothing);
    await tapKey(tester, 'sp.reveal');
    expect(find.text('Unser Haus hat einen großen Garten.'), findsOneWidget);
    expect(find.byKey(const Key('sp.feedback')), findsNothing);
    await tapKey(tester, 'sp.next');

    expect(find.byKey(const Key('sp.summary')), findsOneWidget);
    expect(
      find.text('برنامهٔ مرور (FSRS) و آمار مرور تغییر نکرد.'),
      findsOneWidget,
    );
    expect(api.completionCalls, 2);

    final after = await dumpLearningData(db);
    for (final table in before.keys) {
      if (table == 'sentence_practice_events') continue;
      expect(after[table], before[table], reason: table);
    }
    final history = await db.select(db.sentencePracticeEvents).get();
    expect(history.length, before['sentence_practice_events']!.length + 2);
    expect(history.skip(1).map((e) => e.outcome), [
      SentencePracticeOutcome.minorErrors,
      SentencePracticeOutcome.revealed,
    ]);
    // No answer or AI text is stored anywhere.
    final text = (await dumpLearningData(db)).toString();
    expect(text, isNot(contains('nach hause')));
    expect(text, isNot(contains('Gestern')));
  });

  testWidgets('a failed check keeps the typed answer; checking again works', (
    tester,
  ) async {
    await seedLearningData(db);
    api.completions = [
      generated,
      const SocketException('offline'),
      completionResponse(
        feedbackContent(
          verdict: 'correct',
          corrections: [],
          correctedAnswer: null,
        ),
      ),
    ];
    await open(tester);
    await start(tester);

    await tester.enterText(find.byKey(const Key('sp.answer')), 'Ich ging.');
    await tester.pump();
    await tapKey(tester, 'sp.check');
    expect(find.byKey(const Key('sp.checkError')), findsOneWidget);
    expect(find.textContaining('پاسخ شما حفظ شد'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('sp.answer')));
    expect(field.controller!.text, 'Ich ging.');
    expect(await db.select(db.sentencePracticeEvents).get(), hasLength(1));

    await tapKey(tester, 'sp.check');
    expect(find.byKey(const Key('sp.feedback')), findsOneWidget);
    expect(find.text('درست'), findsOneWidget);
    expect(api.completionCalls, 3);
  });

  testWidgets('a failed generation explains itself and can be retried', (
    tester,
  ) async {
    await seedLearningData(db);
    api.completions = [const SocketException('offline'), generated];
    await open(tester);
    await start(tester);

    expect(find.byKey(const Key('sp.generationFailed')), findsOneWidget);
    expect(find.textContaining('چیزی ذخیره یا تغییر نکرد'), findsOneWidget);
    expect(api.completionCalls, 1);

    await tapKey(tester, 'sp.retryGeneration');
    expect(find.byKey(const Key('sp.prompt')), findsOneWidget);
    expect(api.completionCalls, 2);
  });

  testWidgets('an answer cut off while the model was reasoning gets its '
      'own message and content-free technical details; retry works', (
    tester,
  ) async {
    await seedLearningData(db);
    final cutOff = http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'model': 'minimax/minimax-m3.1-flash:free',
          'choices': [
            {
              'finish_reason': 'length',
              'message': {'role': 'assistant', 'content': null},
            },
          ],
          'usage': {
            'completion_tokens': 1350,
            'completion_tokens_details': {'reasoning_tokens': 1350},
          },
        }),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
    api.completions = [cutOff, cutOff, generated];
    await open(tester);
    await start(tester);

    expect(find.textContaining('ظرفیت خروجی'), findsOneWidget);
    await scrollAndTap(tester, find.byKey(const Key('sp.technicalDetails')));
    expect(find.textContaining('finish=length'), findsWidgets);
    expect(find.textContaining('reasoning 1350'), findsWidgets);
    expect(find.textContaining(testApiKey), findsNothing);

    await scrollAndTap(tester, find.byKey(const Key('sp.retryGeneration')));
    expect(find.byKey(const Key('sp.prompt')), findsOneWidget);
    expect(api.completionCalls, 3);
  });

  testWidgets('an answer that cannot be used is reported as such', (
    tester,
  ) async {
    await seedLearningData(db);
    api.completions = [
      completionResponse('nonsense'),
      completionResponse('still nonsense'),
    ];
    await open(tester);
    await start(tester);
    expect(find.byKey(const Key('sp.generationFailed')), findsOneWidget);
    expect(api.completionCalls, 2);
  });

  testWidgets('without a key the session cannot start and nothing is sent', (
    tester,
  ) async {
    await seedLearningData(db);
    await open(tester, withKey: false);
    await scrollTo(tester, find.byKey(const Key('sp.needsKey')));
    expect(find.byKey(const Key('sp.needsKey')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('sp.start')));
    final start = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('sp.start')),
    );
    expect(start.onPressed, isNull);
    expect(api.requests, isEmpty);
  });

  testWidgets('no words with a meaning: an empty state, no request', (
    tester,
  ) async {
    await open(
      tester,
      location: '/today/sentences/session?direction=produce&level=b1&size=5',
    );
    expect(find.byKey(const Key('sp.noWords')), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('clearing the history needs confirmation and keeps words', (
    tester,
  ) async {
    await seedLearningData(db);
    final words = await db.select(db.vocabularyEntries).get();
    await open(tester);
    await tapKey(tester, 'sp.clearHistory');
    await tester.tap(find.byKey(const Key('sp.clearConfirm')));
    await tester.pumpAndSettle();
    expect(await db.select(db.sentencePracticeEvents).get(), isEmpty);
    expect(await db.select(db.vocabularyEntries).get(), words);
    expect(await db.select(db.flashcards).get(), isNotEmpty);
  });

  testWidgets('English, understanding direction: German prompt, Persian '
      'answer field, LTR layout', (tester) async {
    await seedLearningData(db);
    api.completions = [generated];
    await open(
      tester,
      location: '/today/sentences/session?direction=understand&level=a2&size=3',
      locale: const Locale('en'),
    );
    expect(find.text('Exercise 1 of 2'), findsOneWidget);
    expect(find.text('Gestern ging ich früh nach Hause.'), findsOneWidget);
    expect(find.text('دیروز زود به خانه رفتم.'), findsNothing);
    final field = tester.widget<TextField>(find.byKey(const Key('sp.answer')));
    expect(field.textDirection, TextDirection.rtl);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('sp.progress')))),
      TextDirection.ltr,
    );
    expect(find.text('Your answer (Persian)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
