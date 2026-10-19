import 'package:fsrs/fsrs.dart' as fsrs;

import 'flashcard.dart';
import 'review_event.dart';

/// Computes the next scheduling state of a card with FSRS (the `fsrs`
/// package 2.0.1: default parameters, 90 % desired retention, learning
/// steps of 1 and 10 minutes, a relearning step of 10 minutes).
///
/// The learner's two answers map to FSRS ratings: "remembered" → Good,
/// "not remembered" → Again.
class FsrsReviewScheduler {
  /// [scheduler] can be replaced, e.g. without interval fuzzing in tests.
  FsrsReviewScheduler([fsrs.Scheduler? scheduler])
    : _scheduler = scheduler ?? fsrs.Scheduler();

  /// Stored in `flashcards.scheduler_version` with every computed state.
  static const version = 'fsrs-2.0.1;default;retention=0.9';

  final fsrs.Scheduler _scheduler;

  /// The state after answering [outcome] at [nowUtc].
  ReviewState review(
    ReviewState current,
    ReviewOutcome outcome,
    DateTime nowUtc,
  ) {
    final now = nowUtc.toUtc();
    final card = current.isNew
        ? fsrs.Card(cardId: 0, due: now)
        : fsrs.Card(
            cardId: 0,
            state: _toFsrs(current.state),
            step: current.step,
            stability: current.stability,
            difficulty: current.difficulty,
            due: current.due.toUtc(),
            lastReview: current.lastReviewedAt?.toUtc(),
          );
    final next = _scheduler
        .reviewCard(
          card,
          outcome == ReviewOutcome.remembered
              ? fsrs.Rating.good
              : fsrs.Rating.again,
          reviewDateTime: now,
        )
        .card;
    final lapsed =
        current.state == CardState.review && outcome == ReviewOutcome.forgotten;
    return ReviewState(
      state: _fromFsrs(next.state),
      step: next.step,
      stability: next.stability,
      difficulty: next.difficulty,
      due: next.due.toUtc(),
      lastReviewedAt: now,
      reviewCount: current.reviewCount + 1,
      lapseCount: current.lapseCount + (lapsed ? 1 : 0),
      schedulerVersion: version,
    );
  }

  static fsrs.State _toFsrs(CardState state) => switch (state) {
    CardState.newCard || CardState.learning => fsrs.State.learning,
    CardState.review => fsrs.State.review,
    CardState.relearning => fsrs.State.relearning,
  };

  static CardState _fromFsrs(fsrs.State state) => switch (state) {
    fsrs.State.learning => CardState.learning,
    fsrs.State.review => CardState.review,
    fsrs.State.relearning => CardState.relearning,
  };
}
