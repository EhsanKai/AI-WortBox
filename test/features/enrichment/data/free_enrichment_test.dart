import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/features/enrichment/data/ai_local_store.dart';
import 'package:ai_wortbox/features/enrichment/data/enrichment_cache.dart';
import 'package:ai_wortbox/features/enrichment/data/free_model_catalog.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_client.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_enrichment_service.dart';
import 'package:ai_wortbox/features/enrichment/data/request_scheduler.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/ai_fakes.dart';

/// Free-only mode (the default): zero-cost enforcement, free-only
/// fallback, rate limits, the daily quota, retry limits, batches, partial
/// failures and the cache.
void main() {
  final start = DateTime.utc(2026, 10, 19, 9);
  late FixedClock clock;
  late FakeOpenRouter api;
  late InMemoryAiSettingsStore keys;
  late InMemoryAiKeyValueStore kv;
  late AiLocalState local;
  late List<Duration> sleeps;

  setUp(() {
    clock = FixedClock(start);
    api = FakeOpenRouter();
    // A paid model is saved from earlier use: free-only must ignore it.
    keys = InMemoryAiSettingsStore(
      apiKey: testApiKey,
      model: 'openai/gpt-5-mini',
    );
    kv = InMemoryAiKeyValueStore();
    local = AiLocalState(kv, clock: clock);
    sleeps = [];
  });

  OpenRouterClient client({bool paced = false}) => OpenRouterClient(
    api.client,
    clock: clock,
    random: ZeroRandom(),
    sleep: (d) async {
      sleeps.add(d);
      clock.advance(d);
    },
    scheduler: paced
        ? RequestScheduler(
            clock: clock,
            localState: local,
            sleep: (d) async {
              sleeps.add(d);
              clock.advance(d);
            },
          )
        : null,
  );

  OpenRouterEnrichmentService service({OpenRouterClient? using}) {
    final c = using ?? client();
    return OpenRouterEnrichmentService(
      client: c,
      settings: keys,
      clock: clock,
      localState: local,
      cache: EnrichmentCache(kv, clock: clock),
      catalog: FreeModelCatalog(c, clock: clock),
    );
  }

  EnrichmentRequest word(String original, [String? context]) =>
      EnrichmentRequest(
        original: original,
        sourceContext: context,
        sourceLanguage: Language.german,
        definitionLanguage: Language.persian,
      );

  final ging = word('ging', 'Am Morgen ging sie in die Stadt.');
  final tisch = word('Tisch', 'Der Tisch ist alt.');
  final muehe = word('Mühe', 'Mit großer Mühe.');

  Map<String, Object?> tischContent() => enrichmentContent(
    meanings: [
      {'text': 'میز', 'explanation': null},
    ],
    partOfSpeech: 'noun',
    grammarInfo: 'der Tisch, -(e)s, -e',
    lemma: null,
    exampleSentence: 'Der Tisch ist neu.',
    exampleTranslation: 'میز نو است.',
  );

  Map<String, Object?> mueheContent() => enrichmentContent(
    meanings: [
      {'text': 'زحمت', 'explanation': null},
    ],
    partOfSpeech: 'noun',
    grammarInfo: 'die Mühe, -, -n',
    lemma: null,
  );

  Map<String, Object?> item(String id, String word, Map<String, Object?> c) => {
    'id': id,
    'word': word,
    ...c,
  };

  Map<String, Object?> body(int i) =>
      jsonDecode(api.requests[i].body) as Map<String, Object?>;
  List<Map<String, Object?>> completionBodies() => [
    for (final r in api.requests)
      if (r.url.path.endsWith('/chat/completions'))
        jsonDecode(r.body) as Map<String, Object?>,
  ];

  Matcher failsWith(EnrichmentError error) => throwsA(
    isA<EnrichmentException>().having((e) => e.error, 'error', error),
  );

  /// A platform (account) 429 with OpenRouter's rate-limit headers.
  http.Response accountLimit({
    required DateTime reset,
    String remaining = '0',
    String limit = '20',
    String? retryAfter,
    String message = 'Rate limit exceeded',
  }) => errorResponse(
    429,
    message: message,
    headers: {
      'x-ratelimit-limit': limit,
      'x-ratelimit-remaining': remaining,
      'x-ratelimit-reset': '${reset.millisecondsSinceEpoch}',
      'retry-after': ?retryAfter,
    },
  );

  group('zero-cost enforcement', () {
    test('by default the free router is used with a zero max_price, no '
        'plugins and no paid model, even if one was chosen earlier', () async {
      api.completions = [completionResponse(enrichmentContent(), cost: 0)];
      await service().enrich(ging);
      final sent = body(0);
      expect(sent['model'], 'openrouter/free');
      expect(sent['provider'], {
        'require_parameters': true,
        'max_price': {'prompt': 0, 'completion': 0, 'request': 0},
      });
      expect(sent.containsKey('plugins'), isFalse);
      expect(sent.containsKey('models'), isFalse);
      expect(api.requests.single.body, isNot(contains('gpt-5-mini')));
    });

    test(
      'a reported cost above zero stops everything; nothing is kept',
      () async {
        api.completions = [
          completionResponse(enrichmentContent(), cost: 0.0004),
        ];
        await expectLater(
          service().enrich(ging),
          failsWith(EnrichmentError.paidModelBlocked),
        );
        expect(await EnrichmentCache(kv, clock: clock).count(), 0);
        expect(api.completionCalls, 1);
      },
    );

    test('an answering model that is not recognisably free is blocked '
        'unless OpenRouter reports a zero cost', () async {
      api.completions = [
        completionResponse(enrichmentContent(), model: 'openai/gpt-5-mini'),
        completionResponse(
          enrichmentContent(),
          model: 'openai/gpt-5-mini',
          cost: 0,
        ),
      ];
      await expectLater(
        service().enrich(ging),
        failsWith(EnrichmentError.paidModelBlocked),
      );
      final proposal = await service().enrich(ging);
      expect(proposal.costUsd, 0);
    });

    test('the model actually used is reported and remembered', () async {
      api.completions = [
        completionResponse(enrichmentContent(), model: 'x/actual-model:free'),
      ];
      final proposal = await service().enrich(ging);
      expect(proposal.model, 'x/actual-model:free');
      expect((await local.readUsage()).lastModelUsed, 'x/actual-model:free');
    });

    test('Auto Free fallback stays on the free router (without a schema '
        'the second time)', () async {
      api.completions = [
        errorResponse(404, message: 'No endpoints found'),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      final bodies = completionBodies();
      expect(
        [for (final b in bodies) b['model']],
        ['openrouter/free', 'openrouter/free'],
      );
      expect(bodies[0].containsKey('response_format'), isTrue);
      expect(bodies[1].containsKey('response_format'), isFalse);
      // The prompt then spells out the JSON shape.
      expect(
        ((bodies[1]['messages']! as List).first as Map)['content'],
        contains('JSON Schema of the answer'),
      );
      for (final b in bodies) {
        expect((b['provider']! as Map)['max_price'], isNotNull);
      }
    });

    test('Quality Free uses the best verified free models and falls back '
        'only to free ones; paid models in the list are never used', () async {
      kv.values['ai.routing'] = 'qualityFree';
      api.models = modelsResponse([
        'openai/gpt-5-mini',
        'nvidia/nemotron-3-super-120b-a12b:free',
        'google/gemma-4-31b-it:free',
        'openrouter/free',
      ]);
      api.completions = [
        errorResponse(404),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      expect(
        [for (final b in completionBodies()) b['model']],
        [
          'google/gemma-4-31b-it:free',
          'nvidia/nemotron-3-super-120b-a12b:free',
        ],
      );
      // The model list is public: no key is sent for it.
      final listCall = api.requests.firstWhere(
        (r) => r.url.path.endsWith('/models'),
      );
      expect(listCall.headers.containsKey('Authorization'), isFalse);
    });

    test('Quality Free: when free status cannot be verified, only the free '
        'router is used', () async {
      kv.values['ai.routing'] = 'qualityFree';
      api.models = const SocketException('offline');
      api.completions = [completionResponse(enrichmentContent())];
      await service().enrich(ging);
      expect(completionBodies().single['model'], 'openrouter/free');
    });

    test('unreadable preferences keep free-only on', () async {
      kv.failing = true;
      api.completions = [completionResponse(enrichmentContent())];
      final proposal = await service().enrich(ging);
      expect(proposal.meanings, isNotEmpty);
      expect(completionBodies().single['model'], 'openrouter/free');
    });

    test('an invalid key is never retried or sent to another model', () async {
      api.completions = [errorResponse(401), errorResponse(401)];
      await expectLater(
        service().enrich(ging),
        failsWith(EnrichmentError.invalidKey),
      );
      expect(api.completionCalls, 1);
      expect(sleeps, isEmpty);
    });

    for (final status in [402, 403]) {
      test('$status is not worked around with another model', () async {
        api.completions = [errorResponse(status), errorResponse(status)];
        await expectLater(
          service().enrich(ging),
          throwsA(isA<EnrichmentException>()),
        );
        expect(api.completionCalls, 1);
      });
    }
  });

  group('HTTP 429', () {
    test('an account 429 honours Retry-After exactly, then succeeds', () async {
      api.completions = [
        accountLimit(
          reset: start.add(const Duration(seconds: 3)),
          retryAfter: '3',
        ),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      expect(api.completionCalls, 2);
      expect(sleeps, [const Duration(seconds: 3)]);
    });

    test('without Retry-After, the rate-limit reset is waited for', () async {
      api.completions = [
        accountLimit(reset: start.add(const Duration(seconds: 7))),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      expect(sleeps, [const Duration(seconds: 7)]);
    });

    test('a wait beyond the limit is not shortened: the request fails with '
        'the time to retry, and the next request waits for it', () async {
      final reset = start.add(const Duration(seconds: 50));
      api.completions = [
        accountLimit(reset: reset, retryAfter: '50'),
        completionResponse(enrichmentContent()),
      ];
      final s = service(using: client(paced: true));
      await expectLater(
        s.enrich(ging),
        throwsA(
          isA<EnrichmentException>()
              .having((e) => e.error, 'error', EnrichmentError.rateLimited)
              .having((e) => e.retryAt, 'retryAt', reset)
              .having((e) => e.upstream, 'upstream', isFalse),
        ),
      );
      expect(api.completionCalls, 1);
      // Still cooling down: nothing is sent.
      await expectLater(s.enrich(ging), failsWith(EnrichmentError.rateLimited));
      expect(api.completionCalls, 1);
      clock.set(reset);
      await s.enrich(ging);
      expect(api.completionCalls, 2);
    });

    test('a provider (upstream) 429 is flagged and another free attempt is '
        'made instead of hammering the same route', () async {
      api.completions = [
        errorResponse(429, message: 'Provider returned error'),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      expect(api.completionCalls, 2);
      expect(completionBodies()[1].containsKey('response_format'), isFalse);
    });
  });

  group('daily quota', () {
    final midnight = DateTime.utc(2026, 10, 20);

    test('the daily free-model 429 pauses free requests until the reset; '
        'nothing more is sent, even after a restart', () async {
      api.completions = [
        accountLimit(
          reset: midnight,
          limit: '50',
          message: 'Rate limit exceeded: free-models-per-day',
        ),
        completionResponse(enrichmentContent()),
      ];
      await expectLater(
        service(using: client(paced: true)).enrich(ging),
        throwsA(
          isA<EnrichmentException>()
              .having(
                (e) => e.error,
                'error',
                EnrichmentError.dailyQuotaExhausted,
              )
              .having((e) => e.retryAt, 'retryAt', midnight),
        ),
      );
      expect(api.completionCalls, 1);
      expect(sleeps, isEmpty);
      expect((await local.readUsage()).pausedUntil, midnight);

      // A new scheduler (app restart) still respects the persisted pause.
      final restarted = service(using: client(paced: true));
      await expectLater(
        restarted.enrich(ging),
        failsWith(EnrichmentError.dailyQuotaExhausted),
      );
      expect(api.completionCalls, 1);

      clock.set(midnight.add(const Duration(minutes: 1)));
      await service(using: client(paced: true)).enrich(ging);
      expect(api.completionCalls, 2);
    });

    test('recognised from the headers alone (nothing left, reset hours '
        'away); never retried', () async {
      api.completions = [
        accountLimit(reset: start.add(const Duration(hours: 5)), limit: '50'),
        completionResponse(enrichmentContent()),
      ];
      await expectLater(
        service().enrich(ging),
        failsWith(EnrichmentError.dailyQuotaExhausted),
      );
      expect(api.completionCalls, 1);
    });

    test('the per-minute limit is not mistaken for the daily quota', () async {
      api.completions = [
        accountLimit(reset: start.add(const Duration(seconds: 10))),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      expect(api.completionCalls, 2);
    });

    test('OpenRouter reporting no free requests left pauses; a later report '
        'of some left lifts the pause', () async {
      await local.recordRemoteQuota(remaining: 0, limit: 50);
      expect((await local.readUsage()).pausedUntil, midnight);
      await expectLater(
        service(using: client(paced: true)).enrich(ging),
        failsWith(EnrichmentError.dailyQuotaExhausted),
      );
      expect(api.requests, isEmpty);

      await local.recordRemoteQuota(remaining: 900, limit: 1000);
      api.completions = [completionResponse(enrichmentContent())];
      await service(using: client(paced: true)).enrich(ging);
      final usage = await local.readUsage();
      expect(usage.pausedUntil, isNull);
      expect(usage.requestsToday, 1);
      expect(usage.estimatedRemaining(clock.nowUtc()), 899);
    });
  });

  group('retry limits', () {
    test('at most 2 retries, with exponential backoff', () async {
      api.completions = [
        errorResponse(503),
        errorResponse(503),
        errorResponse(503),
        completionResponse(enrichmentContent()),
      ];
      await expectLater(
        service().enrich(ging),
        failsWith(EnrichmentError.modelUnavailable),
      );
      // Same-route retries used the budget: no extra fallback request.
      expect(api.completionCalls, 3);
      expect(sleeps, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('fallbacks share the same budget: never more than 3 requests per '
        'batch', () async {
      kv.values['ai.routing'] = 'qualityFree';
      api.models = modelsResponse([
        'a/one:free',
        'b/two:free',
        'c/three:free',
        'openrouter/free',
      ]);
      api.completions = [
        errorResponse(404),
        errorResponse(404),
        errorResponse(404),
        completionResponse(enrichmentContent()),
      ];
      await expectLater(
        service().enrich(ging),
        failsWith(EnrichmentError.modelUnavailable),
      );
      expect(api.completionCalls, 3);
    });

    test(
      'timeouts and network failures are not retried automatically',
      () async {
        api.completions = [
          const SocketException('offline'),
          completionResponse(enrichmentContent()),
        ];
        await expectLater(
          service().enrich(ging),
          failsWith(EnrichmentError.network),
        );
        expect(api.completionCalls, 1);
      },
    );

    test('backoff jitter stays within 0–50 % of the step', () {
      final c = OpenRouterClient(api.client, random: Random(7));
      for (var n = 0; n < 3; n++) {
        for (var k = 0; k < 20; k++) {
          final d = c.backoff(n);
          final base = const Duration(seconds: 1) * (1 << n);
          expect(d >= base && d <= base * 1.5, isTrue, reason: '$d');
        }
      }
    });
  });

  group('batches and partial failures', () {
    test('several words go in one request with ids; answers are matched '
        'by id and word, not by position', () async {
      api.completions = [
        completionResponse({
          'items': [
            item('3', 'Mühe', mueheContent()),
            item('1', 'ging', enrichmentContent()),
            item('2', 'Tisch', tischContent()),
          ],
        }),
      ];
      final outcomes = await service().enrichBatch([ging, tisch, muehe]);
      expect(api.completionCalls, 1);
      final sent = body(0);
      expect(
        ((sent['response_format']! as Map)['json_schema']! as Map)['name'],
        'vocabulary_batch',
      );
      final user = jsonDecode(
        ((sent['messages']! as List).last as Map)['content']! as String,
      );
      expect(
        [for (final w in (user as Map)['words'] as List) (w as Map)['id']],
        ['1', '2', '3'],
      );
      final texts = [
        for (final o in outcomes)
          (o as EnrichmentSucceeded).proposal.meanings.first.text,
      ];
      expect(texts, ['رفتن', 'میز', 'زحمت']);
      expect(
        (outcomes[1] as EnrichmentSucceeded).proposal.grammarInfo,
        'der Tisch, -(e)s, -e',
      );
    });

    test('a missing or invalid item fails alone; the others are kept and '
        'cached; retrying sends only the failed words', () async {
      api.completions = [
        completionResponse({
          'items': [
            item('1', 'ging', enrichmentContent()),
            // Meanings not in Persian: invalid.
            item(
              '2',
              'Tisch',
              enrichmentContent(
                meanings: [
                  {'text': 'table', 'explanation': null},
                ],
              ),
            ),
            // Mühe is missing.
          ],
        }),
        completionResponse({
          'items': [
            item('1', 'Tisch', tischContent()),
            item('2', 'Mühe', mueheContent()),
          ],
        }),
      ];
      final s = service();
      final first = await s.enrichBatch([ging, tisch, muehe]);
      expect(first[0], isA<EnrichmentSucceeded>());
      expect(
        (first[1] as EnrichmentFailed).error.error,
        EnrichmentError.malformedResponse,
      );
      expect(first[2], isA<EnrichmentFailed>());

      final second = await s.enrichBatch([ging, tisch, muehe]);
      expect(api.completionCalls, 2);
      final user = jsonDecode(
        ((body(1)['messages']! as List).last as Map)['content']! as String,
      );
      expect(
        [for (final w in (user as Map)['words'] as List) (w as Map)['word']],
        ['Tisch', 'Mühe'],
      );
      expect((second[0] as EnrichmentSucceeded).proposal.fromCache, isTrue);
      expect(second.every((o) => o is EnrichmentSucceeded), isTrue);
    });

    test('an item about a different word is never accepted', () async {
      api.completions = [
        completionResponse({
          'items': [
            item('1', 'ging', enrichmentContent()),
            item('2', 'Haus', tischContent()),
          ],
        }),
      ];
      final outcomes = await service().enrichBatch([ging, tisch]);
      expect(outcomes[0], isA<EnrichmentSucceeded>());
      expect(outcomes[1], isA<EnrichmentFailed>());
    });

    test('a wholly unusable answer gets one free fallback attempt', () async {
      api.completions = [
        completionResponse('Sorry, I cannot help with that.'),
        completionResponse({
          'items': [
            item('1', 'ging', enrichmentContent()),
            item('2', 'Tisch', tischContent()),
          ],
        }),
      ];
      final outcomes = await service().enrichBatch([ging, tisch]);
      expect(api.completionCalls, 2);
      expect(outcomes.every((o) => o is EnrichmentSucceeded), isTrue);
    });

    test('nothing is sent without a key', () async {
      keys.apiKey = null;
      await expectLater(
        service().enrichBatch([ging, tisch]),
        failsWith(EnrichmentError.notConfigured),
      );
      expect(api.requests, isEmpty);
    });
  });

  group('cache', () {
    test('a cached word is not sent again; statistics count the hit', () async {
      api.completions = [completionResponse(enrichmentContent())];
      final s = service();
      final first = await s.enrich(ging);
      final again = await s.enrich(ging);
      expect(api.completionCalls, 1);
      expect(first.fromCache, isFalse);
      expect(again.fromCache, isTrue);
      expect(again.meanings, first.meanings);
      expect(again.lemma, 'gehen');
      final usage = await local.readUsage();
      expect((usage.cacheHits, usage.cacheMisses), (1, 1));
    });

    test('the key depends on case, sentence and existing meanings', () {
      final key = EnrichmentCache.keyFor;
      expect(key(word('Essen')), isNot(key(word('essen'))));
      expect(key(word('ging', 'A.')), isNot(key(word('ging', 'B.'))));
      expect(key(word('ging', ' A. ')), key(word('ging', 'A.')));
      expect(
        key(
          EnrichmentRequest(
            original: 'ging',
            existingMeanings: const ['رفت'],
            sourceLanguage: Language.german,
            definitionLanguage: Language.persian,
          ),
        ),
        isNot(key(word('ging'))),
      );
    });

    test('expired and damaged entries are misses', () async {
      final cache = EnrichmentCache(kv, clock: clock);
      api.completions = [
        completionResponse(enrichmentContent()),
        completionResponse(enrichmentContent()),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(ging);
      clock.advance(const Duration(days: 91));
      expect((await cache.lookup([ging])), isEmpty);
      await service().enrich(ging);
      kv.values[EnrichmentCache.keyFor(ging)] = '{not json';
      expect((await cache.lookup([ging])), isEmpty);
      await service().enrich(ging);
      expect(api.completionCalls, 3);
    });

    test('the oldest entries are evicted beyond the limit', () async {
      final cache = EnrichmentCache(kv, clock: clock, maxEntries: 2);
      api.completions = [
        for (var i = 0; i < 3; i++) completionResponse(enrichmentContent()),
      ];
      final s = OpenRouterEnrichmentService(
        client: client(),
        settings: keys,
        clock: clock,
        localState: local,
        cache: cache,
      );
      for (final w in [word('eins'), word('zwei'), word('drei')]) {
        await s.enrich(w);
        clock.advance(const Duration(minutes: 1));
      }
      expect(await cache.count(), 2);
      expect(await cache.lookup([word('eins')]), isEmpty);
      expect(await cache.lookup([word('drei')]), hasLength(1));
    });
  });
}
