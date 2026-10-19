import 'dart:io';

import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/enrichment/presentation/ai_settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/ai_fakes.dart';

void main() {
  late InMemoryAiSettingsStore store;
  late FakeOpenRouter api;
  late ProviderContainer container;

  setUp(() {
    store = InMemoryAiSettingsStore();
    api = FakeOpenRouter();
    container = ProviderContainer(
      overrides: [
        aiSettingsStoreProvider.overrideWithValue(store),
        httpClientProvider.overrideWithValue(api.client),
        aiKeyValueStoreProvider.overrideWithValue(InMemoryAiKeyValueStore()),
      ],
      retry: (_, _) => null,
    );
  });
  tearDown(() => container.dispose());

  AiSettingsController controller() =>
      container.read(aiSettingsControllerProvider.notifier);
  Future<AiSettingsState> current() =>
      container.read(aiSettingsControllerProvider.future);

  test('starts unconfigured with the default model', () async {
    final state = await current();
    expect(state.isConfigured, isFalse);
    expect(state.model, 'anthropic/claude-haiku-5.5');
    expect(container.read(aiConfiguredProvider), isFalse);
  });

  test('saving stores the trimmed key, keeps only its last four '
      'characters in state and tests it', () async {
    api.keyInfo = keyInfoResponse(usage: 0.5, remaining: 4.5);
    // Free-only (default): the free route must be listed as free.
    api.models = modelsResponse(['openrouter/free']);
    await current();
    await controller().saveKey('  $testApiKey \n');

    expect(store.apiKey, testApiKey);
    final state = await current();
    expect(state.keySuffix, '1234');
    expect(state.isConfigured, isTrue);
    expect(container.read(aiConfiguredProvider), isTrue);
    final check = state.check as AiKeyCheckPassed;
    expect(check.info.usage, 0.5);
    expect(check.modelAvailable, isTrue);
    // The full key is not reachable from the UI state.
    expect(state.toString(), isNot(contains(testApiKey)));
  });

  test('malformed keys are rejected before saving', () async {
    await current();
    for (final (input, problem) in [
      ('', ApiKeyProblem.empty),
      ('   ', ApiKeyProblem.empty),
      ('sk-or-v1 with spaces inside it', ApiKeyProblem.containsWhitespace),
      ('sk-or-short', ApiKeyProblem.tooShort),
      ('k' * 300, ApiKeyProblem.tooLong),
    ]) {
      await expectLater(
        controller().saveKey(input),
        throwsA(
          isA<ArgumentError>().having((e) => e.invalidValue, 'value', problem),
        ),
      );
    }
    expect(store.writes, 0);
    expect(api.requests, isEmpty);
  });

  test('replacing a key overwrites the old one', () async {
    store.apiKey = testApiKey;
    api.keyInfo = keyInfoResponse();
    api.models = modelsResponse(['anthropic/claude-haiku-5.5']);
    await current();
    const newKey = 'sk-or-v1-9999999999999999999999999999new5678';
    await controller().saveKey(newKey);
    expect(store.apiKey, newKey);
    expect((await current()).keySuffix, '5678');
    // The test used the new key.
    expect(
      api.requests.last.url.path.endsWith('/models')
          ? api.requests[api.requests.length - 2].headers['Authorization']
          : api.requests.last.headers['Authorization'],
      'Bearer $newKey',
    );
  });

  test('removing the key deletes it and turns AI off', () async {
    store.apiKey = testApiKey;
    await current();
    await controller().removeKey();
    expect(store.apiKey, isNull);
    expect((await current()).isConfigured, isFalse);
    expect(container.read(aiConfiguredProvider), isFalse);
  });

  test(
    'an invalid key is reported (and stays saved for replacement)',
    () async {
      api.keyInfo = errorResponse(401);
      await current();
      await controller().saveKey(testApiKey);
      final check = (await current()).check as AiKeyCheckFailed;
      expect(
        (check.error as EnrichmentException).error,
        EnrichmentError.invalidKey,
      );
      // No model check after a failed key check.
      expect(
        api.requests.where((r) => r.url.path.endsWith('/models')),
        isEmpty,
      );
    },
  );

  test('offline: the key check reports a network error', () async {
    store.apiKey = testApiKey;
    api.keyInfo = const SocketException('offline');
    await current();
    await controller().testKey();
    final check = (await current()).check as AiKeyCheckFailed;
    expect((check.error as EnrichmentException).error, EnrichmentError.network);
  });

  test(
    'a delisted model is flagged; an unreachable list is "unknown"',
    () async {
      store.apiKey = testApiKey;
      api.keyInfo = keyInfoResponse();
      api.models = modelsResponse(['openai/gpt-4o-mini']);
      await current();
      await controller().testKey();
      expect(
        ((await current()).check as AiKeyCheckPassed).modelAvailable,
        isFalse,
      );

      api.models = const SocketException('offline');
      await controller().testKey();
      expect(
        ((await current()).check as AiKeyCheckPassed).modelAvailable,
        isNull,
      );
    },
  );

  test('testing without a key sends nothing', () async {
    await current();
    await controller().testKey();
    expect((await current()).check, isA<AiKeyCheckFailed>());
    expect(api.requests, isEmpty);
  });

  test('selecting a model persists catalog ids only', () async {
    await current();
    await controller().selectModel('openai/gpt-5-mini');
    expect(store.model, 'openai/gpt-5-mini');
    await controller().selectModel('evil/unknown');
    expect(store.model, 'anthropic/claude-haiku-5.5');
  });

  test('secure storage failures surface as errors, not crashes', () async {
    store.failing = true;
    await expectLater(current(), throwsA(isA<StorageException>()));
  });

  group('secure storage write failures', () {
    final storageError = throwsA(
      isA<StorageException>().having(
        (e) => e.toString(),
        'toString',
        isNot(contains(testApiKey)),
      ),
    );

    test(
      'a failed save throws, stays unconfigured and sends nothing',
      () async {
        await current();
        store.failWrites = true;
        await expectLater(controller().saveKey(testApiKey), storageError);
        final state = await current();
        expect(state.isConfigured, isFalse);
        expect(state.check, isA<AiKeyCheckIdle>());
        expect(container.read(aiConfiguredProvider), isFalse);
        expect(api.requests, isEmpty);
      },
    );

    test('a failed replacement keeps showing the key that is stored', () async {
      store.apiKey = 'sk-or-v1-0000000000000000000000000000old0abcd';
      await current();
      store.failWrites = true;
      await expectLater(controller().saveKey(testApiKey), storageError);
      expect((await current()).keySuffix, 'abcd');
      expect(api.requests, isEmpty);
    });

    test('a failed removal throws and the key stays configured', () async {
      store.apiKey = testApiKey;
      await current();
      store.failDeletes = true;
      await expectLater(controller().removeKey(), storageError);
      expect(store.apiKey, testApiKey);
      expect((await current()).isConfigured, isTrue);
    });

    test('a failed model change keeps the previous model', () async {
      await current();
      store.failWrites = true;
      await expectLater(
        controller().selectModel('openai/gpt-5-mini'),
        storageError,
      );
      expect((await current()).model, 'anthropic/claude-haiku-5.5');
    });
  });
}
