import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../enrichment/data/openrouter_chat.dart';
import '../data/openrouter_sentence_practice_service.dart';
import '../domain/sentence_exercise.dart';

/// Sentence practice uses the same OpenRouter client (pacing, rate limits,
/// daily quota), key store, preferences and free-model catalog as AI
/// suggestions.
final sentencePracticeAiProvider = Provider<SentencePracticeAi>(
  (ref) => OpenRouterSentencePracticeService(
    OpenRouterChat(
      client: ref.watch(openRouterClientProvider),
      settings: ref.watch(aiSettingsStoreProvider),
      localState: ref.watch(aiLocalStateProvider),
      catalog: ref.watch(freeModelCatalogProvider),
    ),
  ),
);

/// Number of recorded sentence exercises.
final sentencePracticeCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(sentencePracticeRepositoryProvider).watchCount(),
);
