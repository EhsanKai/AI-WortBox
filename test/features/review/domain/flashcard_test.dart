import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial review state is new, unreviewed and due now (UTC)', () {
    final now = DateTime.utc(2026, 10, 15, 9);
    final state = ReviewState.initial(now);
    expect(state.isNew, isTrue);
    expect(state.due, now);
    expect(state.due.isUtc, isTrue);
    expect(state.stability, isNull);
    expect(state.difficulty, isNull);
    expect(state.lastReviewedAt, isNull);
    expect(state.reviewCount, 0);
    expect(state.lapseCount, 0);
  });

  test('persisted enum names are stable', () {
    expect(CardDirection.values.map((v) => v.name), ['forward', 'reverse']);
    expect(CardState.values.map((v) => v.name), [
      'newCard',
      'learning',
      'review',
      'relearning',
    ]);
  });
}
