import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_client.dart';
import 'package:ai_wortbox/features/enrichment/data/openrouter_enrichment_service.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/ai_fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 16, 9);
  late FakeOpenRouter api;
  late InMemoryAiSettingsStore store;
  late List<Duration> sleeps;

  OpenRouterEnrichmentService service({
    Duration timeout = const Duration(seconds: 45),
  }) => OpenRouterEnrichmentService(
    client: OpenRouterClient(
      api.client,
      requestTimeout: timeout,
      sleep: (d) async => sleeps.add(d),
    ),
    settings: store,
    clock: FixedClock(now),
  );

  const request = EnrichmentRequest(
    original: 'Mühe',
    sourceContext: 'Am Morgen ging sie mit großer Mühe in die Stadt.',
    existingMeanings: ['زحمت'],
    sourceLanguage: Language.german,
    definitionLanguage: Language.persian,
  );

  Matcher failsWith(EnrichmentError error) => throwsA(
    isA<EnrichmentException>().having((e) => e.error, 'error', error),
  );

  setUp(() {
    api = FakeOpenRouter();
    store = InMemoryAiSettingsStore(apiKey: testApiKey);
    sleeps = [];
  });

  group('requests', () {
    test('sends the documented request with the user key in the '
        'Authorization header only', () async {
      api.completions = [completionResponse(enrichmentContent())];
      await service().enrich(request);

      final sent = api.requests.single;
      expect(sent.method, 'POST');
      expect(
        sent.url.toString(),
        'https://openrouter.ai/api/v1/chat/completions',
      );
      expect(sent.headers['Authorization'], 'Bearer $testApiKey');
      expect(sent.headers['X-OpenRouter-Title'], 'AI WortBox');
      expect(sent.body, isNot(contains(testApiKey)));

      final body = jsonDecode(sent.body) as Map<String, Object?>;
      expect(body['model'], 'anthropic/claude-haiku-5.5');
      final format = body['response_format']! as Map;
      expect(format['type'], 'json_schema');
      expect((format['json_schema']! as Map)['strict'], isTrue);
      expect(body['provider'], {'require_parameters': true});

      // Only the word, its context and existing meanings are sent.
      final user = jsonDecode(
        ((body['messages']! as List).last as Map)['content']! as String,
      );
      expect(user, {
        'word': 'Mühe',
        'sentence_context': 'Am Morgen ging sie mit großer Mühe in die Stadt.',
        'existing_meanings': ['زحمت'],
        'word_language': 'German',
        'meaning_language': 'Persian',
      });
    });

    test('uses the selected catalog model; unknown ids fall back', () async {
      store.model = 'openai/gpt-4o-mini';
      api.completions = [
        completionResponse(enrichmentContent()),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(request);
      store.model = 'someone/unknown-model';
      await service().enrich(request);
      final models = [
        for (final r in api.requests) (jsonDecode(r.body) as Map)['model'],
      ];
      expect(models, ['openai/gpt-4o-mini', 'anthropic/claude-haiku-5.5']);
    });

    test('no saved key: throws notConfigured and sends nothing', () async {
      store.apiKey = null;
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.notConfigured),
      );
      store.apiKey = '   ';
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.notConfigured),
      );
      expect(api.requests, isEmpty);
    });
  });

  group('responses', () {
    test(
      'returns a validated proposal with the reported model and cost',
      () async {
        api.completions = [
          completionResponse(
            enrichmentContent(),
            model: 'anthropic/claude-haiku-5.5-20261001',
            cost: 0.00042,
          ),
        ];
        final proposal = await service().enrich(request);
        expect(proposal.meanings.single.text, 'رفتن');
        expect(proposal.lemma, 'gehen');
        expect(proposal.model, 'anthropic/claude-haiku-5.5-20261001');
        expect(proposal.provider, 'openrouter');
        expect(proposal.generatedAt, now);
        expect(proposal.costUsd, 0.00042);
      },
    );

    test('no cost reported: no cost is invented', () async {
      api.completions = [completionResponse(enrichmentContent())];
      expect((await service().enrich(request)).costUsd, isNull);
    });

    test('malformed content is rejected', () async {
      api.completions = [completionResponse('not json at all')];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.malformedResponse),
      );
    });

    test('a truncated answer (finish_reason length) is rejected', () async {
      api.completions = [
        completionResponse(enrichmentContent(), finishReason: 'length'),
      ];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.malformedResponse),
      );
    });

    test('a body without choices is rejected', () async {
      api.completions = [http.Response('{"id": "x"}', 200)];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.malformedResponse),
      );
    });

    test('a 200 response carrying an error object is an error and is not '
        'repeated (generation may have run)', () async {
      api.completions = [
        http.Response(
          jsonEncode({
            'error': {'code': 502, 'message': 'provider disconnected'},
          }),
          200,
        ),
      ];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.modelUnavailable),
      );
      expect(api.completionCalls, 1);
      expect(sleeps, isEmpty);
    });
  });

  group('errors and retries', () {
    for (final (status, error) in [
      (400, EnrichmentError.badRequest),
      (401, EnrichmentError.invalidKey),
      (402, EnrichmentError.insufficientCredits),
      (403, EnrichmentError.forbidden),
    ]) {
      test('$status → $error, not retried', () async {
        api.completions = [errorResponse(status)];
        await expectLater(service().enrich(request), failsWith(error));
        expect(api.completionCalls, 1);
        expect(sleeps, isEmpty);
      });
    }

    test('400 about the model → modelUnavailable', () async {
      api.completions = [
        errorResponse(400, message: 'xyz is not a valid model ID'),
      ];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.modelUnavailable),
      );
    });

    test('429 is retried, honouring Retry-After, then succeeds', () async {
      api.completions = [
        errorResponse(429, headers: {'retry-after': '3'}),
        completionResponse(enrichmentContent()),
      ];
      final proposal = await service().enrich(request);
      expect(proposal.meanings, isNotEmpty);
      expect(api.completionCalls, 2);
      expect(sleeps, [const Duration(seconds: 3)]);
    });

    test('Retry-After is capped', () async {
      api.completions = [
        errorResponse(503, headers: {'retry-after': '3600'}),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(request);
      expect(sleeps, [const Duration(seconds: 20)]);
    });

    test('repeated 429 gives up after the retry limit with backoff', () async {
      api.completions = [
        errorResponse(429),
        errorResponse(429),
        errorResponse(429),
      ];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.rateLimited),
      );
      expect(api.completionCalls, 3);
      expect(sleeps, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('402 with Retry-After (in-flight budget) is retried', () async {
      api.completions = [
        errorResponse(402, headers: {'retry-after': '1'}),
        completionResponse(enrichmentContent()),
      ];
      await service().enrich(request);
      expect(api.completionCalls, 2);
    });

    test(
      '503 (no provider available) is retried and finally reported',
      () async {
        api.completions = [
          errorResponse(503),
          errorResponse(503),
          errorResponse(503),
        ];
        await expectLater(
          service().enrich(request),
          failsWith(EnrichmentError.modelUnavailable),
        );
        expect(api.completionCalls, 3);
      },
    );

    // These can happen after a provider started generating (and billing):
    // the user decides whether to repeat them.
    for (final (status, error) in [
      (408, EnrichmentError.timeout),
      (500, EnrichmentError.server),
      (502, EnrichmentError.modelUnavailable),
    ]) {
      test('$status is ambiguous: reported as $error, not retried', () async {
        api.completions = [
          errorResponse(status),
          completionResponse(enrichmentContent()),
        ];
        await expectLater(service().enrich(request), failsWith(error));
        expect(api.completionCalls, 1);
        expect(sleeps, isEmpty);
      });
    }

    test('a network failure is reported as network and not retried', () async {
      api.completions = [
        http.ClientException('Connection closed while receiving data'),
        completionResponse(enrichmentContent()),
      ];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.network),
      );
      expect(api.completionCalls, 1);
      expect(sleeps, isEmpty);
    });

    test('a client-side timeout is reported as timeout and not retried '
        '(the request may still complete and be billed)', () async {
      Future<http.Response> never() => Completer<http.Response>().future;
      api.completions = [never, completionResponse(enrichmentContent())];
      await expectLater(
        service(timeout: const Duration(milliseconds: 10)).enrich(request),
        failsWith(EnrichmentError.timeout),
      );
      expect(api.completionCalls, 1);
      expect(sleeps, isEmpty);
    });

    test('a later user retry sends a new request', () async {
      Future<http.Response> never() => Completer<http.Response>().future;
      api.completions = [never, completionResponse(enrichmentContent())];
      final s = service(timeout: const Duration(milliseconds: 10));
      await expectLater(s.enrich(request), failsWith(EnrichmentError.timeout));
      expect((await s.enrich(request)).meanings, isNotEmpty);
      expect(api.completionCalls, 2);
    });

    test('only pre-generation rejections are retryable', () {
      bool retryable(int status, [Duration? after]) =>
          OpenRouterClient.isRejectedBeforeGeneration(
            status,
            retryAfter: after,
          );
      expect(retryable(429), isTrue);
      expect(retryable(503), isTrue);
      expect(retryable(402, const Duration(seconds: 1)), isTrue);
      for (final status in [400, 401, 402, 403, 404, 408, 500, 502]) {
        expect(retryable(status), isFalse, reason: '$status');
      }
    });

    test('an error body that is not JSON still maps by status', () async {
      api.completions = [http.Response('<html>Bad gateway</html>', 401)];
      await expectLater(
        service().enrich(request),
        failsWith(EnrichmentError.invalidKey),
      );
    });

    test('exceptions never contain the key', () async {
      api.completions = [errorResponse(401, message: 'Bad key $testApiKey')];
      try {
        await service().enrich(request);
        fail('should throw');
      } on EnrichmentException catch (e) {
        expect(e.toString(), isNot(contains(testApiKey)));
        expect(e.toString(), isNot(contains('Bad key')));
        expect(e.statusCode, 401);
      }
    });
  });

  group('cancellation', () {
    test('cancelling during a request stops it with cancelled', () async {
      final pending = Completer<http.Response>();
      api.completions = [() => pending.future];
      final cancellation = EnrichmentCancellation();
      final result = service().enrich(request, cancellation: cancellation);
      await Future<void>.delayed(Duration.zero);
      cancellation.cancel();
      await expectLater(result, failsWith(EnrichmentError.cancelled));
      // A late response is ignored.
      pending.complete(completionResponse(enrichmentContent()));
    });

    test('a cancelled token sends nothing', () async {
      final cancellation = EnrichmentCancellation()..cancel();
      await expectLater(
        service().enrich(request, cancellation: cancellation),
        failsWith(EnrichmentError.cancelled),
      );
      expect(api.requests, isEmpty);
    });
  });

  group('key and model checks', () {
    OpenRouterClient client() => OpenRouterClient(api.client);

    test('keyInfo reads usage and limits from GET /key', () async {
      api.keyInfo = keyInfoResponse(usage: 1.25, remaining: 3.75);
      final info = await client().keyInfo(testApiKey);
      expect(info.usage, 1.25);
      expect(info.limitRemaining, 3.75);
      final sent = api.requests.single;
      expect(sent.method, 'GET');
      expect(sent.url.toString(), 'https://openrouter.ai/api/v1/key');
      expect(sent.headers['Authorization'], 'Bearer $testApiKey');
    });

    test('keyInfo maps an invalid key', () async {
      api.keyInfo = errorResponse(401);
      await expectLater(
        client().keyInfo(testApiKey),
        failsWith(EnrichmentError.invalidKey),
      );
    });

    test('keyInfo maps network failures', () async {
      api.keyInfo = const SocketException('offline');
      await expectLater(
        client().keyInfo(testApiKey),
        failsWith(EnrichmentError.network),
      );
    });

    test('the model list is public: no key is sent', () async {
      api.models = modelsResponse(['anthropic/claude-haiku-5.5']);
      expect(
        await client().supportsStructuredOutputs('anthropic/claude-haiku-5.5'),
        isTrue,
      );
      expect(
        await client().supportsStructuredOutputs('openai/gpt-4o-mini'),
        isFalse,
      );
      for (final r in api.requests) {
        expect(r.headers.containsKey('Authorization'), isFalse);
        expect(
          r.url.queryParameters['supported_parameters'],
          'structured_outputs',
        );
      }
    });
  });
}
