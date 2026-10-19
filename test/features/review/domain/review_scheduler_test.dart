import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/review/domain/review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

void main() {
  final scheduler = FsrsReviewScheduler(fsrs.Scheduler(enableFuzzing: false));
  final t0 = DateTime.utc(2026, 10, 19, 9);

  test('a new card answered "remembered" enters learning: next step in '
      '10 minutes, FSRS memory state set, counted and versioned', () {
    final next = scheduler.review(
      ReviewState.initial(t0),
      ReviewOutcome.remembered,
      t0,
    );
    expect(next.state, CardState.learning);
    expect(next.step, 1);
    expect(next.due, t0.add(const Duration(minutes: 10)));
    expect(next.stability, isNotNull);
    expect(next.difficulty, isNotNull);
    expect(next.lastReviewedAt, t0);
    expect(next.reviewCount, 1);
    expect(next.lapseCount, 0);
    expect(next.schedulerVersion, FsrsReviewScheduler.version);
  });

  test('"not remembered" on a new card repeats the first step (1 minute)', () {
    final next = scheduler.review(
      ReviewState.initial(t0),
      ReviewOutcome.forgotten,
      t0,
    );
    expect(next.state, CardState.learning);
    expect(next.step, 0);
    expect(next.due, t0.add(const Duration(minutes: 1)));
  });

  test('graduation, growing intervals, then a lapse into relearning', () {
    var state = scheduler.review(
      ReviewState.initial(t0),
      ReviewOutcome.remembered,
      t0,
    );
    var now = state.due;
    state = scheduler.review(state, ReviewOutcome.remembered, now);
    expect(state.state, CardState.review);
    expect(state.step, isNull);
    final firstInterval = state.due.difference(now);
    expect(firstInterval, greaterThanOrEqualTo(const Duration(days: 1)));

    now = state.due;
    final stabilityBefore = state.stability!;
    state = scheduler.review(state, ReviewOutcome.remembered, now);
    expect(state.state, CardState.review);
    expect(state.stability, greaterThan(stabilityBefore));
    expect(state.due.difference(now), greaterThan(firstInterval));
    expect(state.reviewCount, 3);

    now = state.due;
    state = scheduler.review(state, ReviewOutcome.forgotten, now);
    expect(state.state, CardState.relearning);
    expect(state.lapseCount, 1);
    expect(state.due, now.add(const Duration(minutes: 10)));
  });

  test('both directions use the same policy: identical histories give '
      'identical states', () {
    ReviewState run() {
      var s = ReviewState.initial(t0);
      var now = t0;
      for (final outcome in [
        ReviewOutcome.remembered,
        ReviewOutcome.forgotten,
        ReviewOutcome.remembered,
        ReviewOutcome.remembered,
      ]) {
        s = scheduler.review(s, outcome, now);
        now = s.due;
      }
      return s;
    }

    expect(run(), run());
  });
}
