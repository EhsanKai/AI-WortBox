import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../../vocabulary/domain/vocabulary_search.dart';
import '../domain/flashcard.dart';
import '../domain/review_event.dart';
import 'memory_coach_providers.dart';
import 'review_providers.dart';

/// Which words a review session uses and whether it is scheduled.
@immutable
class PracticeConfig {
  const PracticeConfig({
    this.deckId,
    this.difficultOnly = false,
    this.scheduled = true,
    this.coach = false,
  });

  /// One deck, or every deck when null.
  final String? deckId;
  final bool difficultOnly;

  /// Scheduled review (FSRS, due cards only) rather than free practice.
  final bool scheduled;

  /// Focused practice of the Memory Coach's words (see
  /// `findStrugglingWords`), in every deck.
  final bool coach;

  /// Difficult-word and Memory Coach practice are always free practice: the
  /// manual mark and the coach's suggestions are kept separate from FSRS
  /// scheduling.
  bool get isScheduled => scheduled && !difficultOnly && !coach;

  @override
  bool operator ==(Object other) =>
      other is PracticeConfig &&
      other.deckId == deckId &&
      other.difficultOnly == difficultOnly &&
      other.scheduled == scheduled &&
      other.coach == coach;

  @override
  int get hashCode => Object.hash(deckId, difficultOnly, scheduled, coach);
}

/// A word asked in one direction.
@immutable
class StudyCard {
  const StudyCard(this.entry, this.direction);

  final VocabularyEntry entry;
  final CardDirection direction;

  /// German shown, Persian recalled.
  bool get asksMeaning => direction == CardDirection.forward;

  /// Identifies the card (word and direction); the same card can appear
  /// twice in a session when FSRS brings it back for a learning step.
  (String, CardDirection) get key => (entry.id, direction);
}

enum PracticePhase {
  loading,

  /// Nothing is due (scheduled) or no word with a meaning matches (free).
  empty,

  /// Loading the session failed.
  failed,

  /// Only the prompt side is shown; the answer is not built at all.
  question,

  /// The answer is revealed; waiting for the learner's outcome.
  answer,
  done,
}

@immutable
class PracticeState {
  const PracticeState({
    required this.phase,
    this.cards = const [],
    this.index = 0,
    this.remembered = 0,
    this.forgotten = 0,
    this.isRecording = false,
    this.error,
  });

  final PracticePhase phase;
  final List<StudyCard> cards;
  final int index;
  final int remembered;
  final int forgotten;

  /// An outcome is being saved; further taps are ignored.
  final bool isRecording;

  /// Saving the last outcome (or loading) failed; the card stays so it can
  /// be retried.
  final Object? error;

  StudyCard? get current => index < cards.length ? cards[index] : null;

  /// Different cards in the session. A card repeated for a learning step
  /// (appended to [cards] after its answer) is counted once, so the total
  /// shown does not grow while reviewing.
  int get total => {for (final c in cards) c.key}.length;

  /// Different cards shown so far, including the current one (1-based).
  int get position =>
      {for (final c in cards.take(index + 1)) c.key}.length.clamp(0, total);

  /// Different cards answered at least once, for the progress bar.
  int get answeredCards => {for (final c in cards.take(index)) c.key}.length;

  /// The current card was already answered in this session and is shown
  /// again for an FSRS learning step.
  bool get isRepeat {
    final card = current;
    return card != null && cards.take(index).any((c) => c.key == card.key);
  }

  int get answered => remembered + forgotten;

  PracticeState copyWith({
    PracticePhase? phase,
    List<StudyCard>? cards,
    int? index,
    int? remembered,
    int? forgotten,
    bool? isRecording,
    Object? Function()? error,
  }) => PracticeState(
    phase: phase ?? this.phase,
    cards: cards ?? this.cards,
    index: index ?? this.index,
    remembered: remembered ?? this.remembered,
    forgotten: forgotten ?? this.forgotten,
    isRecording: isRecording ?? this.isRecording,
    error: error != null ? error() : this.error,
  );
}

/// One review session: shows the prompt side of each card, reveals the
/// answer on request and records the learner's own outcome.
///
/// Scheduled sessions review the cards FSRS says are due and advance their
/// scheduling state with every answer (`StudyRepository.recordAnswer`); a
/// card that is due again within minutes (a learning step) returns at the
/// end of the session. Free practice (all words, difficult words only, or
/// the Memory Coach's words) records review events but never changes
/// scheduling state.
///
/// Only an explicit "remembered"/"not remembered" after the reveal is
/// recorded, once per tap.
class PracticeController extends Notifier<PracticeState> {
  PracticeController(this.config);

  final PracticeConfig config;
  late final String _sessionId = ref.read(idGeneratorProvider).newId();

  @override
  PracticeState build() {
    Future.microtask(_load);
    return const PracticeState(phase: PracticePhase.loading);
  }

  Future<void> _load() async {
    List<StudyCard> cards;
    try {
      cards = config.isScheduled
          ? await _dueCards()
          : config.coach
          ? await _coachCards()
          : await _freeCards();
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = PracticeState(phase: PracticePhase.failed, error: e);
      return;
    }
    if (!ref.mounted) return;
    state = PracticeState(
      phase: cards.isEmpty ? PracticePhase.empty : PracticePhase.question,
      cards: List.unmodifiable(cards),
    );
  }

  Future<List<StudyCard>> _dueCards() async {
    final direction = await ref.read(reviewDirectionProvider.future);
    final due = await ref
        .read(studyRepositoryProvider)
        .dueQueue(
          deckId: config.deckId,
          directions: direction.cardDirections,
          limit: AppConfig.reviewSessionSize,
        );
    final vocabulary = ref.read(vocabularyRepositoryProvider);
    return [
      for (final card in due)
        if (await vocabulary.getEntry(card.entryId) case final entry?
            when entry.hasMeanings)
          StudyCard(entry, card.direction),
    ];
  }

  Future<List<StudyCard>> _freeCards() async {
    final direction = await ref.read(reviewDirectionProvider.future);
    final entries = await ref
        .read(vocabularyRepositoryProvider)
        .search(
          VocabularyQuery(
            deckId: config.deckId,
            difficultOnly: config.difficultOnly,
          ),
          limit: AppConfig.maxSearchResults,
        );
    final words = entries.where((e) => e.hasMeanings).toList()
      ..shuffle(ref.read(randomProvider));
    return [
      for (final (i, entry)
          in words.take(AppConfig.practiceSessionSize).indexed)
        StudyCard(entry, direction.directionAt(i)),
    ];
  }

  /// The coach's words with a meaning, most struggled-with first.
  Future<List<StudyCard>> _coachCards() async {
    final direction = await ref.read(reviewDirectionProvider.future);
    final rule = ref.read(memoryCoachRuleProvider);
    final now = ref.read(clockProvider).nowUtc();
    final suggestions = await resolveSuggestions(
      await ref
          .read(reviewRepositoryProvider)
          .eventsSince(now.subtract(rule.lookback)),
      now: now,
      rule: rule,
      vocabulary: ref.read(vocabularyRepositoryProvider),
    );
    return [
      for (final (i, s)
          in suggestions
              .where((s) => s.entry.hasMeanings)
              .take(AppConfig.practiceSessionSize)
              .indexed)
        StudyCard(s.entry, direction.directionAt(i)),
    ];
  }

  void reveal() {
    if (state.phase != PracticePhase.question) return;
    state = state.copyWith(phase: PracticePhase.answer);
  }

  /// Records [outcome] for the current card and moves on. Ignored before
  /// the answer is revealed and while a previous tap is being saved.
  Future<void> answer(ReviewOutcome outcome) async {
    final card = state.current;
    if (state.phase != PracticePhase.answer ||
        state.isRecording ||
        card == null) {
      return;
    }
    state = state.copyWith(isRecording: true, error: () => null);
    var cards = state.cards;
    try {
      if (config.isScheduled) {
        final (next, _) = await ref
            .read(studyRepositoryProvider)
            .recordAnswer(
              entryId: card.entry.id,
              direction: card.direction,
              sessionId: _sessionId,
              outcome: outcome,
            );
        final soon = ref
            .read(clockProvider)
            .nowUtc()
            .add(AppConfig.reviewLearnAhead);
        if (next.state != CardState.review && !next.due.isAfter(soon)) {
          cards = List.unmodifiable([...cards, card]);
        }
      } else {
        await ref
            .read(reviewRepositoryProvider)
            .record(
              entryId: card.entry.id,
              sessionId: _sessionId,
              direction: card.direction,
              outcome: outcome,
            );
      }
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isRecording: false, error: () => e);
      return;
    }
    if (!ref.mounted) return;
    final next = state.index + 1;
    state = state.copyWith(
      cards: cards,
      index: next,
      remembered:
          state.remembered + (outcome == ReviewOutcome.remembered ? 1 : 0),
      forgotten: state.forgotten + (outcome == ReviewOutcome.forgotten ? 1 : 0),
      phase: next >= cards.length ? PracticePhase.done : PracticePhase.question,
      isRecording: false,
    );
  }
}

final practiceControllerProvider = NotifierProvider.autoDispose
    .family<PracticeController, PracticeState, PracticeConfig>(
      PracticeController.new,
    );
