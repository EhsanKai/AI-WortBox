import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../data/openrouter_client.dart';
import '../domain/ai_model_catalog.dart';

/// Problems with a key as typed (checked before it is saved).
enum ApiKeyProblem { empty, containsWhitespace, tooShort, tooLong }

/// Basic shape check only; OpenRouter decides whether the key is valid.
ApiKeyProblem? checkApiKeyFormat(String key) {
  if (key.isEmpty) return ApiKeyProblem.empty;
  if (key.contains(RegExp(r'\s'))) return ApiKeyProblem.containsWhitespace;
  if (key.length < 20) return ApiKeyProblem.tooShort;
  if (key.length > 256) return ApiKeyProblem.tooLong;
  return null;
}

/// Result of "test key".
sealed class AiKeyCheck {
  const AiKeyCheck();
}

final class AiKeyCheckIdle extends AiKeyCheck {
  const AiKeyCheckIdle();
}

final class AiKeyCheckRunning extends AiKeyCheck {
  const AiKeyCheckRunning();
}

final class AiKeyCheckPassed extends AiKeyCheck {
  const AiKeyCheckPassed(this.info, {required this.modelAvailable});

  final OpenRouterKeyInfo info;

  /// Whether the selected model is currently listed with structured-output
  /// support; null if the list could not be loaded.
  final bool? modelAvailable;
}

final class AiKeyCheckFailed extends AiKeyCheck {
  const AiKeyCheckFailed(this.error);

  final Object error;
}

/// What the AI settings screen shows. Holds only the last four characters
/// of the key, never the key itself.
@immutable
class AiSettingsState {
  const AiSettingsState({
    required this.keySuffix,
    required this.model,
    this.check = const AiKeyCheckIdle(),
  });

  /// Last characters of the saved key, or null when none is saved.
  final String? keySuffix;
  final String model;
  final AiKeyCheck check;

  bool get isConfigured => keySuffix != null;

  AiSettingsState copyWith({
    String? Function()? keySuffix,
    String? model,
    AiKeyCheck? check,
  }) => AiSettingsState(
    keySuffix: keySuffix != null ? keySuffix() : this.keySuffix,
    model: model ?? this.model,
    check: check ?? this.check,
  );
}

String _suffix(String key) =>
    key.length <= 4 ? key : key.substring(key.length - 4);

class AiSettingsController extends AsyncNotifier<AiSettingsState> {
  @override
  Future<AiSettingsState> build() async {
    final store = ref.watch(aiSettingsStoreProvider);
    final key = (await store.readApiKey())?.trim();
    return AiSettingsState(
      keySuffix: key == null || key.isEmpty ? null : _suffix(key),
      model: AiModelCatalog.resolve(await store.readModel()),
    );
  }

  AiSettingsState get _current => state.requireValue;

  /// Saves (or replaces) the key, then tests it. Throws [ArgumentError]
  /// with an [ApiKeyProblem] for malformed input, without saving, and
  /// [StorageException] when secure storage fails (the state then shows
  /// whatever key is actually stored).
  Future<void> saveKey(String raw) async {
    final key = raw.trim();
    final problem = checkApiKeyFormat(key);
    if (problem != null) throw ArgumentError.value(problem);
    await _syncOnFailure(
      () => ref.read(aiSettingsStoreProvider).writeApiKey(key),
    );
    state = AsyncData(
      _current.copyWith(
        keySuffix: () => _suffix(key),
        check: const AiKeyCheckIdle(),
      ),
    );
    await testKey();
  }

  /// Deletes the key. Throws [StorageException] when secure storage fails
  /// (the state then shows whatever key is actually stored).
  Future<void> removeKey() async {
    await _syncOnFailure(
      () => ref.read(aiSettingsStoreProvider).deleteApiKey(),
    );
    state = AsyncData(
      _current.copyWith(keySuffix: () => null, check: const AiKeyCheckIdle()),
    );
  }

  /// Throws [StorageException] when secure storage fails; the previous
  /// model stays selected.
  Future<void> selectModel(String modelId) async {
    final model = AiModelCatalog.resolve(modelId);
    await ref.read(aiSettingsStoreProvider).writeModel(model);
    state = AsyncData(
      _current.copyWith(model: model, check: const AiKeyCheckIdle()),
    );
  }

  /// Runs a secure-storage write. On failure, re-reads the stored key so
  /// the screen never shows an outcome that did not happen, then rethrows.
  Future<void> _syncOnFailure(Future<void> Function() write) async {
    try {
      await write();
    } on StorageException {
      try {
        final stored = (await ref.read(aiSettingsStoreProvider).readApiKey())
            ?.trim();
        state = AsyncData(
          _current.copyWith(
            keySuffix: () =>
                stored == null || stored.isEmpty ? null : _suffix(stored),
            check: const AiKeyCheckIdle(),
          ),
        );
      } on StorageException {
        // Unreadable as well: keep the last known state.
      }
      rethrow;
    }
  }

  /// Checks the saved key with OpenRouter and the selected model against
  /// the public model list. Sends the key only to OpenRouter.
  Future<void> testKey() async {
    final key = (await ref.read(aiSettingsStoreProvider).readApiKey())?.trim();
    if (key == null || key.isEmpty) {
      state = AsyncData(
        _current.copyWith(
          check: const AiKeyCheckFailed(
            EnrichmentException(EnrichmentError.notConfigured),
          ),
        ),
      );
      return;
    }
    state = AsyncData(_current.copyWith(check: const AiKeyCheckRunning()));
    final client = ref.read(openRouterClientProvider);
    try {
      final info = await client.keyInfo(key);
      bool? modelAvailable;
      try {
        modelAvailable = await client.supportsStructuredOutputs(_current.model);
      } on EnrichmentException {
        modelAvailable = null;
      }
      state = AsyncData(
        _current.copyWith(
          check: AiKeyCheckPassed(info, modelAvailable: modelAvailable),
        ),
      );
    } on AppException catch (e) {
      state = AsyncData(_current.copyWith(check: AiKeyCheckFailed(e)));
    }
  }
}

final aiSettingsControllerProvider =
    AsyncNotifierProvider<AiSettingsController, AiSettingsState>(
      AiSettingsController.new,
    );

/// Whether the user has saved a key (AI features can be offered).
final aiConfiguredProvider = Provider<bool>(
  (ref) => ref.watch(aiSettingsControllerProvider).value?.isConfigured ?? false,
);
