import 'package:ai_wortbox/features/enrichment/domain/free_model_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);

  OpenRouterModelInfo model(
    String id, {
    Map<String, Object?>? pricing = const {'prompt': '0', 'completion': '0'},
    Object? overrides,
    List<String> params = const ['response_format', 'structured_outputs'],
    List<String>? outputs,
    String? expires,
  }) {
    final prices = pricing == null
        ? null
        : {...pricing, 'overrides': ?overrides};
    return OpenRouterModelInfo.fromJson({
      'id': id,
      'pricing': ?prices,
      'supported_parameters': params,
      if (outputs != null) 'architecture': {'output_modalities': outputs},
      'expiration_date': expires,
    })!;
  }

  bool free(OpenRouterModelInfo m) => FreeModelPolicy.isVerifiedFree(m, now);

  group('free-model filtering', () {
    test('a :free variant with zero prices is free', () {
      expect(free(model('google/gemma-4-31b-it:free')), isTrue);
      expect(free(model('openrouter/free')), isTrue);
    });

    test('zero token prices alone are not enough without the :free id '
        '(paid media models list "0" token prices)', () {
      expect(free(model('google/lyria-3-pro-preview')), isFalse);
    });

    test('any non-zero, missing or unparseable price is not free', () {
      expect(
        free(
          model('a/b:free', pricing: {'prompt': '0', 'completion': '0.000001'}),
        ),
        isFalse,
      );
      expect(
        free(
          model(
            'a/b:free',
            pricing: {'prompt': '0', 'completion': '0', 'image': '0.01'},
          ),
        ),
        isFalse,
      );
      expect(
        free(
          model(
            'a/b:free',
            pricing: {'prompt': '0', 'completion': '0', 'request': '0.0'},
          ),
        ),
        isTrue,
      );
      expect(free(model('a/b:free', pricing: {'prompt': '0'})), isFalse);
      expect(free(model('a/b:free', pricing: null)), isFalse);
      expect(
        free(model('a/b:free', pricing: {'prompt': '0', 'completion': 'free'})),
        isFalse,
      );
      expect(
        free(model('a/b:free', pricing: {'prompt': '0', 'completion': null})),
        isFalse,
      );
      expect(
        free(model('a/b:free', pricing: {'prompt': '-1', 'completion': '0'})),
        isFalse,
      );
    });

    test('conditional price overrides are not verifiable', () {
      expect(
        free(
          model(
            'a/b:free',
            overrides: [
              {'condition': 'x', 'prompt': '0.1'},
            ],
          ),
        ),
        isFalse,
      );
      expect(free(model('a/b:free', overrides: const [])), isTrue);
    });

    test('expired or non-text models are not used', () {
      expect(free(model('a/b:free', expires: '2026-10-01')), isFalse);
      expect(free(model('a/b:free', expires: '2026-12-31')), isTrue);
      expect(free(model('a/b:free', outputs: ['image'])), isFalse);
      expect(free(model('a/b:free', outputs: ['text', 'image'])), isTrue);
    });

    test('answering model ids: :free, the router, or verified ids only', () {
      expect(FreeModelPolicy.isFreeModelId('x/y:free'), isTrue);
      expect(FreeModelPolicy.isFreeModelId('openrouter/free'), isTrue);
      expect(FreeModelPolicy.isFreeModelId('openai/gpt-5-mini'), isFalse);
      expect(
        FreeModelPolicy.isFreeModelId('x/special', verifiedIds: {'x/special'}),
        isTrue,
      );
    });
  });

  group('quality ranking', () {
    test('ranks verified free models by score; excludes paid, unsuitable '
        'and the router itself', () {
      final ranked = const FreeModelQuality().rank([
        model('openrouter/free'),
        model('liquid/lfm-2.5-2.6b:free'),
        model('google/gemma-4-31b-it:free', params: ['response_format']),
        model('nvidia/nemotron-3-super-120b-a12b:free'),
        model('nvidia/nemotron-3.5-content-safety:free'),
        model('cohere/north-mini-code:free'),
        model(
          'openai/gpt-5-mini',
          pricing: {'prompt': '0.0000002', 'completion': '0.000002'},
        ),
      ], now);
      expect(
        [for (final m in ranked) m.id],
        [
          // 80 + 15 (structured outputs)
          'nvidia/nemotron-3-super-120b-a12b:free',
          // 86 + 5 (JSON mode only)
          'google/gemma-4-31b-it:free',
          'liquid/lfm-2.5-2.6b:free',
        ],
      );
    });

    test('scores are configurable and matched by the longest prefix', () {
      const quality = FreeModelQuality(
        scores: {'a/': 10, 'a/best': 90},
        structuredOutputBonus: 0,
      );
      final ranked = quality.rank([
        model('a/other:free'),
        model('a/best-model:free'),
        model('z/unknown:free'),
      ], now);
      expect(
        [for (final m in ranked) m.id],
        [
          'a/best-model:free',
          'z/unknown:free', // default 50
          'a/other:free',
        ],
      );
    });
  });

  group('attempt planning (zero-cost fallback)', () {
    test('paid mode: only the chosen model, no fallback', () {
      expect(
        planAttempts(
          freeOnly: false,
          mode: FreeRoutingMode.autoFree,
          paidModel: 'openai/gpt-5-mini',
        ),
        [
          const ModelAttempt(
            'openai/gpt-5-mini',
            StructuredOutputMode.jsonSchema,
          ),
        ],
      );
    });

    test('Auto Free: the free router, with then without a schema', () {
      expect(
        planAttempts(
          freeOnly: true,
          mode: FreeRoutingMode.autoFree,
          paidModel: 'openai/gpt-5-mini',
        ),
        [
          const ModelAttempt(
            'openrouter/free',
            StructuredOutputMode.jsonSchema,
          ),
          const ModelAttempt(
            'openrouter/free',
            StructuredOutputMode.promptOnly,
          ),
        ],
      );
    });

    test('Quality Free: top verified models, then the router; never the '
        'paid model', () {
      final attempts = planAttempts(
        freeOnly: true,
        mode: FreeRoutingMode.qualityFree,
        paidModel: 'openai/gpt-5-mini',
        rankedFree: [
          model('a/one:free'),
          model('b/two:free', params: const []),
          model('c/three:free'),
        ],
      );
      expect(attempts, [
        const ModelAttempt('a/one:free', StructuredOutputMode.jsonSchema),
        const ModelAttempt('b/two:free', StructuredOutputMode.promptOnly),
        const ModelAttempt('openrouter/free', StructuredOutputMode.jsonSchema),
      ]);
      expect(attempts.any((a) => a.model == 'openai/gpt-5-mini'), isFalse);
    });

    test('Quality Free without a verified list falls back to the router', () {
      expect(
        planAttempts(
          freeOnly: true,
          mode: FreeRoutingMode.qualityFree,
          paidModel: 'openai/gpt-5-mini',
        ).map((a) => a.model).toSet(),
        {'openrouter/free'},
      );
    });
  });
}
