import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../../vocabulary/domain/vocabulary_search.dart';
import '../domain/flashcard.dart';
import '../domain/review_event.dart';
import 'review_providers.dart';

/// Which words a review session uses and whether it is scheduled.
@immutable
class PracticeConfig {
  const PracticeConfig({
    this.deckId,
    this.difficultOnly = false,
    this.scheduled = true,
  });

  /// One deck, or every deck when null.
  final String? deckId;
  final bool difficultOnly;

  /// Scheduled review (FSRS, due cards only) rather than free practice.
  final bool scheduled;

  /// Difficult-word practice is always free practice: the manual mark is
  /// kept separate from FSRS scheduling.
  bool get isScheduled => scheduled && !difficultOnly;

  @override
  bool operator ==(Object other) =>
      other is PracticeConfig &&
      other.deckId == deckId &&
      other.difficultOnly == difficultOnly &&
      other.scheduled == scheduled;

  @override
  int get hashCode => Object.hash(deckId, difficultOnly, scheduled);
}

/// A word asked in one direction.
@immutable
class StudyCard {
  const StudyCard(this.entry, this.direction);

  final VocabularyEntry entry;
  final CardDirection direction;

  /// German shown, Persian recalled.
  bool get asksMeaning => direction == CardDirection.forward;
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
/// end of the session. Free practice (all words, or difficult words only)
/// records review events but never changes scheduling state.
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
      cards = config.isScheduled ? await _dueCards() : await _freeCards();
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
