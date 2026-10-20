import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../enrichment/domain/enrichment.dart';
import '../../review/domain/memory_coach.dart';
import '../../review/presentation/memory_coach_providers.dart';
import '../../vocabulary/domain/vocabulary_search.dart';
import '../domain/sentence_exercise.dart';
import '../domain/sentence_practice.dart';
import '../domain/word_selection.dart';
import 'sentence_practice_providers.dart';

/// What a sentence-practice session uses.
@immutable
class SentenceSessionConfig {
  const SentenceSessionConfig({
    this.direction = SentencePracticeDirection.produce,
    this.level = SentenceLevel.b1,
    this.size = AppConfig.sentencePracticeDefaultSize,
    this.deckId,
    this.tagId,
  });

  final SentencePracticeDirection direction;
  final SentenceLevel level;

  /// Target words (one exercise each).
  final int size;
  final String? deckId;
  final String? tagId;

  @override
  bool operator ==(Object other) =>
      other is SentenceSessionConfig &&
      other.direction == direction &&
      other.level == level &&
      other.size == size &&
      other.deckId == deckId &&
      other.tagId == tagId;

  @override
  int get hashCode => Object.hash(direction, level, size, deckId, tagId);
}

enum SentencePhase {
  /// Choosing words and generating exercises.
  generating,

  /// No saved word with a meaning matches the selection.
  noWords,

  /// Generation failed; nothing was recorded. The learner can retry.
  generationFailed,

  /// Writing an answer.
  answering,

  /// The answer is being checked.
  checking,

  /// Feedback (or the revealed model answer) is shown.
  reviewed,

  /// All exercises are finished.
  done,
}

@immutable
class SentenceSessionState {
  const SentenceSessionState({
    required this.phase,
    this.exercises = const [],
    this.rejected = 0,
    this.index = 0,
    this.answer = '',
    this.feedback,
    this.revealed = false,
    this.error,
    this.outcomes = const [],
  });

  final SentencePhase phase;
  final List<SentenceExercise> exercises;

  /// Words whose generated exercise failed validation and was left out.
  final int rejected;
  final int index;

  /// The learner's current answer. Kept through failures and retries.
  final String answer;

  /// Feedback on [answer], once checked.
  final SentenceFeedback? feedback;

  /// The model answer is visible.
  final bool revealed;

  /// The last failure (generation or checking).
  final Object? error;

  /// How the finished exercises ended.
  final List<SentencePracticeOutcome> outcomes;

  SentenceExercise? get current =>
      index < exercises.length ? exercises[index] : null;

  SentenceSessionState copyWith({
    SentencePhase? phase,
    String? answer,
    SentenceFeedback? Function()? feedback,
    bool? revealed,
    Object? Function()? error,
    int? index,
    List<SentencePracticeOutcome>? outcomes,
  }) => SentenceSessionState(
    phase: phase ?? this.phase,
    exercises: exercises,
    rejected: rejected,
    index: index ?? this.index,
    answer: answer ?? this.answer,
    feedback: feedback != null ? feedback() : this.feedback,
    revealed: revealed ?? this.revealed,
    error: error != null ? error() : this.error,
    outcomes: outcomes ?? this.outcomes,
  );
}

/// Runs one sentence-practice session.
///
/// AI requests are sent only on explicit actions: starting (or retrying)
/// the session generates all exercises in one request, "Check" sends one
/// request for the current answer. Nothing is retried automatically beyond
/// the shared OpenRouter policy.
///
/// Writes only sentence-practice history (when an exercise is finished):
/// never vocabulary, `flashcards` or `review_events`.
class SentencePracticeController extends Notifier<SentenceSessionState> {
  SentencePracticeController(this.config);

  final SentenceSessionConfig config;
  EnrichmentCancellation? _cancellation;

  @override
  SentenceSessionState build() {
    ref.onDispose(() => _cancellation?.cancel());
    Future.microtask(_generate);
    return const SentenceSessionState(phase: SentencePhase.generating);
  }

  /// Generates the session again after a failure (a new request).
  Future<void> retryGeneration() async {
    if (state.phase != SentencePhase.generationFailed) return;
    state = const SentenceSessionState(phase: SentencePhase.generating);
    await _generate();
  }

  Future<void> _generate() async {
    try {
      final words = await _chooseWords();
      if (!ref.mounted) return;
      if (words.isEmpty) {
        state = const SentenceSessionState(phase: SentencePhase.noWords);
        return;
      }
      final cancellation = _cancellation = EnrichmentCancellation();
      final generated = await ref
          .read(sentencePracticeAiProvider)
          .generate(
            words,
            direction: config.direction,
            level: config.level,
            cancellation: cancellation,
          );
      if (!ref.mounted) return;
      state = SentenceSessionState(
        phase: SentencePhase.answering,
        exercises: List.unmodifiable(generated.exercises),
        rejected: generated.rejected.length,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = SentenceSessionState(
        phase: SentencePhase.generationFailed,
        error: e,
      );
    }
  }

  Future<List<PracticeWord>> _chooseWords() async {
    final entries = await ref
        .read(vocabularyRepositoryProvider)
        .search(
          VocabularyQuery(deckId: config.deckId, tagId: config.tagId),
          limit: 1 << 20,
        );
    final now = ref.read(clockProvider).nowUtc();
    final rule = ref.read(memoryCoachRuleProvider);
    final events = await ref
        .read(reviewRepositoryProvider)
        .eventsSince(now.subtract(rule.lookback));
    final struggling = {
      for (final w in findStrugglingWords(events, now: now, rule: rule))
        w.entryId,
    };
    final chosen = selectPracticeWords(
      entries,
      lastPracticed: await ref
          .read(sentencePracticeRepositoryProvider)
          .lastPracticedByEntry(),
      struggling: struggling,
      nowUtc: now,
      count: config.size,
      random: ref.read(randomProvider),
    );
    return [for (final e in chosen) PracticeWord.fromEntry(e)];
  }

  void updateAnswer(String text) {
    if (state.phase != SentencePhase.answering) return;
    state = state.copyWith(answer: text);
  }

  /// Checks the current answer. On failure the answer stays as typed and
  /// the learner can try again.
  Future<void> submit() async {
    final exercise = state.current;
    final answer = state.answer.trim();
    if (exercise == null ||
        answer.isEmpty ||
        state.phase != SentencePhase.answering) {
      return;
    }
    state = state.copyWith(phase: SentencePhase.checking, error: () => null);
    try {
      final cancellation = _cancellation = EnrichmentCancellation();
      final feedback = await ref
          .read(sentencePracticeAiProvider)
          .evaluate(
            exercise,
            answer,
            direction: config.direction,
            level: config.level,
            cancellation: cancellation,
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: SentencePhase.reviewed,
        feedback: () => feedback,
        revealed: true,
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(phase: SentencePhase.answering, error: () => e);
    }
  }

  /// Shows the model answer without checking an answer.
  void reveal() {
    if (state.phase != SentencePhase.answering) return;
    state = state.copyWith(
      phase: SentencePhase.reviewed,
      revealed: true,
      error: () => null,
    );
  }

  /// Ends the current exercise (after feedback, after revealing, or
  /// skipped) and records only how it ended.
  Future<void> next() async {
    final exercise = state.current;
    if (exercise == null ||
        state.phase == SentencePhase.checking ||
        state.phase == SentencePhase.generating) {
      return;
    }
    final outcome =
        state.feedback?.verdict.outcome ??
        (state.revealed
            ? SentencePracticeOutcome.revealed
            : SentencePracticeOutcome.skipped);
    try {
      await ref
          .read(sentencePracticeRepositoryProvider)
          .record(
            entryId: exercise.word.entryId,
            direction: config.direction,
            level: config.level,
            outcome: outcome,
          );
    } on StorageException {
      // History only steers which words come next; the session goes on.
    }
    if (!ref.mounted) return;
    final next = state.index + 1;
    state = SentenceSessionState(
      phase: next >= state.exercises.length
          ? SentencePhase.done
          : SentencePhase.answering,
      exercises: state.exercises,
      rejected: state.rejected,
      index: next,
      outcomes: List.unmodifiable([...state.outcomes, outcome]),
    );
  }
}

final sentencePracticeControllerProvider = NotifierProvider.autoDispose
    .family<
      SentencePracticeController,
      SentenceSessionState,
      SentenceSessionConfig
    >(SentencePracticeController.new);
