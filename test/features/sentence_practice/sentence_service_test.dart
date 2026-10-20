import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/features/enrichment/data/ai_local_store.dart';
import 'package:ai_wortbox/features/enrichment/data/free_model_catalog.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_chat.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_client.dart';
import 'package:ai_wortbox/features/enrichment/domain/free_model_policy.dart';
import 'package:ai_wortbox/features/sentence_practice/data/openrouter_sentence_practice_service.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_exercise.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_practice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/ai_fakes.dart';
import '../../helpers/sentence_fakes.dart';

void main() {
  late FixedClock clock;
  late FakeOpenRouter api;
  late InMemoryAiSettingsStore keys;
  late InMemoryAiKeyValueStore kv;
  late AiLocalState local;

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 10, 20, 9));
    api = FakeOpenRouter();
    // A paid model saved from earlier use must be ignored in free-only mode.
    keys = InMemoryAiSettingsStore(
      apiKey: testApiKey,
      model: 'openai/gpt-5-mini',
    );
    kv = InMemoryAiKeyValueStore();
    local = AiLocalState(kv, clock: clock);
  });

  OpenRouterSentencePracticeService service() {
    final client = OpenRouterClient(
      api.client,
      clock: clock,
      random: ZeroRandom(),
      sleep: (d) async => clock.advance(d),
    );
    return OpenRouterSentencePracticeService(
      OpenRouterChat(
        client: client,
        settings: keys,
        localState: local,
        catalog: FreeModelCatalog(client, clock: clock),
      ),
    );
  }

  String message(Map<String, dynamic> body, int i) =>
      ((body['messages'] as List)[i] as Map)['content'] as String;

  Map<String, dynamic> body(int i) =>
      jsonDecode(api.requests[i].body) as Map<String, dynamic>;

  http.Response exercises(
    List<Map<String, Object?>> items, {
    double? cost,
    String? model,
  }) => completionResponse(
    {'items': items},
    cost: cost,
    model: model ?? 'google/gemma-4-31b-it:free',
  );

  Future<GeneratedExercises> generate([
    List<PracticeWord> words = const [haus, gehen],
  ]) => service().generate(
    words,
    direction: SentencePracticeDirection.produce,
    level: SentenceLevel.b1,
  );

  const exercise = SentenceExercise(
    word: haus,
    german: 'Unser Haus hat einen großen Garten.',
    persian: 'خانهٔ ما باغ بزرگی دارد.',
    usedForm: 'Haus',
  );

  Future<SentenceFeedback> evaluate(String answer) => service().evaluate(
    exercise,
    answer,
    direction: SentencePracticeDirection.produce,
    level: SentenceLevel.b1,
  );

  Matcher fails(EnrichmentError error) => throwsA(
    isA<EnrichmentException>().having((e) => e.error, 'error', error),
  );

  group('generation', () {
    test('one request generates the session from the saved words', () async {
      api.completions = [
        exercises([hausItem(), gehenItem()]),
      ];
      final r = await generate();
      expect(r.exercises.map((e) => e.word.entryId), ['e-haus', 'e-gehen']);
      expect(api.completionCalls, 1);

      final b = body(0);
      final user = jsonDecode(message(b, 1)) as Map;
      expect(user['level'], 'B1');
      final words = user['words'] as List;
      expect(words.first, {
        'id': '1',
        'word': 'Haus',
        'base_form': 'Haus',
        'word_class': 'Nomen',
        'saved_persian_meanings': ['خانه'],
      });
      // Nothing else (deck names, notes, review data) is sent.
      expect(api.requests.single.body, isNot(contains('e-haus')));
    });

    test('free-only policy: free router, zero max_price, the saved paid '
        'model is ignored, the key only in the Authorization header', () async {
      api.completions = [
        exercises([hausItem()]),
      ];
      await generate([haus]);
      final b = body(0);
      expect(b['model'], FreeModelPolicy.routerModel);
      expect((b['provider'] as Map)['max_price'], OpenRouterChat.zeroMaxPrice);
      expect(
        api.requests.single.headers['Authorization'],
        'Bearer $testApiKey',
      );
      expect(api.requests.single.body, isNot(contains(testApiKey)));
      expect(api.requests.single.body, isNot(contains('gpt-5-mini')));
    });

    test('a paid answer is blocked and nothing is returned', () async {
      api.completions = [
        exercises([hausItem()], cost: 0.002),
      ];
      await expectLater(
        generate([haus]),
        fails(EnrichmentError.paidModelBlocked),
      );
      expect(api.completionCalls, 1);
    });

    test(
      'an answer from a model that is not recognisably free is blocked',
      () async {
        api.completions = [
          exercises([hausItem()], model: 'openai/gpt-5-mini'),
        ];
        await expectLater(
          generate([haus]),
          fails(EnrichmentError.paidModelBlocked),
        );
      },
    );

    test('with free-only turned off by the user, the chosen model is used '
        'without a zero price ceiling', () async {
      await local.writePreferences(const AiPreferences(freeOnly: false));
      api.completions = [
        exercises([hausItem()], model: 'openai/gpt-5-mini', cost: 0.0001),
      ];
      await generate([haus]);
      expect(body(0)['model'], 'openai/gpt-5-mini');
      expect((body(0)['provider'] as Map).containsKey('max_price'), isFalse);
    });

    test('no key: nothing is sent', () async {
      keys.apiKey = null;
      await expectLater(generate(), fails(EnrichmentError.notConfigured));
      expect(api.requests, isEmpty);
    });

    test('an exercise that omits the target word is left out', () async {
      api.completions = [
        exercises([
          {...hausItem(), 'german': 'Unser Garten ist groß.'},
          gehenItem(),
        ]),
      ];
      final r = await generate();
      expect(r.exercises.single.word, gehen);
      expect(r.rejected, [haus]);
    });

    test('invalid JSON falls back once to the free router without a schema, '
        'within the retry budget', () async {
      api.completions = [
        completionResponse('this is not json'),
        exercises([hausItem()]),
      ];
      final r = await generate([haus]);
      expect(r.exercises, hasLength(1));
      expect(api.completionCalls, 2);
      expect(body(0).containsKey('response_format'), isTrue);
      expect(body(1).containsKey('response_format'), isFalse);
      expect(body(1)['model'], FreeModelPolicy.routerModel);
    });

    test(
      'empty or cut-off output on every attempt fails as malformed',
      () async {
        api.completions = [
          completionResponse(''),
          completionResponse({'items': []}, finishReason: 'length'),
        ];
        await expectLater(
          generate([haus]),
          fails(EnrichmentError.malformedResponse),
        );
        expect(api.completionCalls, 2);
      },
    );

    test(
      'network errors and timeouts are not repeated automatically',
      () async {
        api.completions = [const SocketException('offline')];
        await expectLater(generate(), fails(EnrichmentError.network));
        expect(api.completionCalls, 1);

        api = FakeOpenRouter(completions: [TimeoutException('slow')]);
        await expectLater(generate(), fails(EnrichmentError.timeout));
        expect(api.completionCalls, 1);
      },
    );

    test('a model provider\'s rate limit moves to the next free attempt '
        'once, then is reported', () async {
      api.completions = [
        for (var i = 0; i < 5; i++)
          errorResponse(429, message: 'Rate limit exceeded'),
      ];
      await expectLater(generate(), fails(EnrichmentError.rateLimited));
      expect(api.completionCalls, 2);
    });

    test('OpenRouter\'s per-minute limit is waited for and retried at most '
        'twice', () async {
      final reset = clock.nowUtc().add(const Duration(seconds: 10));
      api.completions = [
        for (var i = 0; i < 5; i++)
          errorResponse(
            429,
            message: 'Rate limit exceeded',
            headers: {
              'x-ratelimit-limit': '20',
              'x-ratelimit-remaining': '0',
              'x-ratelimit-reset': '${reset.millisecondsSinceEpoch}',
            },
          ),
      ];
      await expectLater(generate(), fails(EnrichmentError.rateLimited));
      expect(api.completionCalls, 3);
    });

    test('the daily free quota is not retried', () async {
      api.completions = [
        errorResponse(429, message: 'Rate limit exceeded: free-models-per-day'),
      ];
      await expectLater(generate(), fails(EnrichmentError.dailyQuotaExhausted));
      expect(api.completionCalls, 1);
    });

    test('an invalid key is reported without fallback', () async {
      api.completions = [errorResponse(401)];
      await expectLater(generate(), fails(EnrichmentError.invalidKey));
      expect(api.completionCalls, 1);
    });
  });

  group('evaluation', () {
    test('sends the exercise and the answer as data and returns validated '
        'feedback', () async {
      api.completions = [completionResponse(feedbackContent())];
      final f = await evaluate('Unser haus hat einen großen Garten.');
      expect(f.verdict, SentenceVerdict.minorErrors);
      expect(f.corrections.single.corrected, 'Haus');

      final b = body(0);
      expect(b['model'], FreeModelPolicy.routerModel);
      expect((b['provider'] as Map)['max_price'], OpenRouterChat.zeroMaxPrice);
      final user = jsonDecode(message(b, 1)) as Map;
      expect(user['learner_answer'], 'Unser haus hat einen großen Garten.');
      expect(user['shown_to_learner'], exercise.persian);
      expect(user['reference_answer'], exercise.german);
      expect(user['target_word'], 'Haus');
      final system = message(b, 0);
      expect(
        system,
        contains('Never mark an answer wrong only because it differs'),
      );
    });

    test(
      'contradictory feedback is retried with another free attempt',
      () async {
        api.completions = [
          completionResponse(
            feedbackContent(verdict: 'correct', targetWord: 'missing'),
          ),
          completionResponse(
            feedbackContent(verdict: 'incorrect', targetWord: 'missing'),
          ),
        ];
        final f = await evaluate('Unser Garten ist groß.');
        expect(f.verdict, SentenceVerdict.incorrect);
        expect(f.targetWord, TargetWordUse.missing);
        expect(api.completionCalls, 2);
      },
    );

    test('an understanding exercise uses the understanding prompt', () async {
      api.completions = [
        completionResponse(
          feedbackContent(
            verdict: 'acceptable',
            corrections: [],
            correctedAnswer: null,
            naturalVersion: 'خانهٔ ما باغ بزرگی دارد.',
            explanation: 'ترجمهٔ شما درست است.',
          ),
        ),
      ];
      final f = await service().evaluate(
        exercise,
        'خانه ما یک باغ بزرگ دارد',
        direction: SentencePracticeDirection.understand,
        level: SentenceLevel.a2,
      );
      expect(f.verdict, SentenceVerdict.acceptable);
      final b = body(0);
      final system = message(b, 0);
      expect(system, contains('how a Persian-speaking learner understood'));
      final user = jsonDecode(message(b, 1)) as Map;
      expect(user['shown_to_learner'], exercise.german);
      expect(user['level'], 'A2');
    });

    test('timeouts fail at once (the user retries)', () async {
      api.completions = [TimeoutException('slow')];
      await expectLater(
        evaluate('Unser Haus.'),
        fails(EnrichmentError.timeout),
      );
      expect(api.completionCalls, 1);
    });
  });
}
