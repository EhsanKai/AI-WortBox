import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_direction.dart';
import 'package:ai_wortbox/features/review/domain/review_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 9);
  final startOfToday = DateTime.utc(2026, 10, 19);
  final endOfToday = DateTime.utc(2026, 10, 20);
  const forward = CardDirection.forward;
  const reverse = CardDirection.reverse;

  QueueEntry entry(String id, {String deck = 'd', int age = 0}) => QueueEntry(
    entryId: id,
    deckId: deck,
    createdAt: DateTime.utc(2026, 10, 1).add(Duration(minutes: age)),
  );

  ReviewState review(DateTime due, {DateTime? last}) => ReviewState(
    state: CardState.review,
    due: due,
    stability: 3,
    difficulty: 5,
    lastReviewedAt: last ?? due.subtract(const Duration(days: 3)),
    reviewCount: 2,
  );

  ReviewState learning(DateTime due) => ReviewState(
    state: CardState.learning,
    step: 1,
    due: due,
    stability: 1,
    difficulty: 5,
    lastReviewedAt: now,
    reviewCount: 1,
  );

  List<DueCard> queue({
    required List<QueueEntry> entries,
    Map<(String, CardDirection), ReviewState> cards = const {},
    Set<CardDirection> directions = const {forward},
    Map<String, int> newLeft = const {'d': 20},
    int? limit,
  }) => buildDueQueue(
    entries: entries,
    cards: cards,
    directions: directions,
    newCardsLeft: newLeft,
    nowUtc: now,
    startOfTodayUtc: startOfToday,
    endOfTodayUtc: endOfToday,
    limit: limit,
  );

  String describe(DueCard c) => '${c.entryId}/${c.direction.name}';

  test('due today, learning within 20 minutes and new cards are due; '
      'future cards are not', () {
    final result = queue(
      entries: [entry('a'), entry('b'), entry('c'), entry('d'), entry('e')],
      cards: {
        ('a', forward): review(DateTime.utc(2026, 10, 19, 23)), // later today
        ('b', forward): review(DateTime.utc(2026, 10, 21)), // future
        ('c', forward): learning(now.add(const Duration(minutes: 10))),
        ('d', forward): learning(now.add(const Duration(minutes: 30))),
      },
    );
    // Scheduled cards by due time, then new ones.
    expect(result.map(describe), ['c/forward', 'a/forward', 'e/forward']);
    expect(result.last.state.isNew, isTrue);
  });

  test('only the chosen direction is reviewed', () {
    final result = queue(entries: [entry('a')], directions: {reverse});
    expect(result.map(describe), ['a/reverse']);
  });

  test('new cards: oldest word first, within each deck\'s daily limit', () {
    final result = queue(
      entries: [
        entry('young', age: 5),
        entry('old', age: 1),
        entry('mid', age: 3),
        entry('x', deck: 'other'),
      ],
      newLeft: {'d': 2, 'other': 0},
    );
    expect(result.map(describe), ['old/forward', 'mid/forward']);
  });

  group('both directions', () {
    const both = {forward, reverse};

    test('a new word is asked once per day, German → Persian first', () {
      final result = queue(entries: [entry('a')], directions: both);
      expect(result.map(describe), ['a/forward']);
    });

    test('the sibling waits until the next day after one direction was '
        'answered today', () {
      final graduated = review(
        DateTime.utc(2026, 10, 22),
        last: now.subtract(const Duration(hours: 1)),
      );
      final today = queue(
        entries: [entry('a')],
        directions: both,
        cards: {('a', forward): graduated},
      );
      expect(today, isEmpty);

      final tomorrow = buildDueQueue(
        entries: [entry('a')],
        cards: {('a', forward): graduated},
        directions: both,
        newCardsLeft: const {'d': 20},
        nowUtc: now.add(const Duration(days: 1)),
        startOfTodayUtc: startOfToday.add(const Duration(days: 1)),
        endOfTodayUtc: endOfToday.add(const Duration(days: 1)),
      );
      expect(tomorrow.map(describe), ['a/reverse']);
    });

    test('a card in a learning step stays even when its sibling was also '
        'answered today; of two due cards the earlier one is taken', () {
      final result = queue(
        entries: [entry('a'), entry('b')],
        directions: both,
        cards: {
          ('a', forward): learning(now.add(const Duration(minutes: 5))),
          ('a', reverse): learning(now.add(const Duration(minutes: 1))),
          ('b', forward): review(DateTime.utc(2026, 10, 19, 12)),
          ('b', reverse): review(DateTime.utc(2026, 10, 18)),
        },
      );
      expect(result.map(describe), ['b/reverse', 'a/reverse', 'a/forward']);
    });
  });

  test('limit keeps the most urgent cards', () {
    final result = queue(
      entries: [entry('a'), entry('b'), entry('c')],
      cards: {('c', forward): review(DateTime.utc(2026, 10, 18))},
      limit: 2,
    );
    expect(result.map(describe), ['c/forward', 'a/forward']);
  });

  test('direction setting: default, parsing and alternation', () {
    expect(ReviewDirection.parse(null), ReviewDirection.germanToPersian);
    expect(ReviewDirection.parse('bogus'), ReviewDirection.germanToPersian);
    expect(ReviewDirection.parse('both'), ReviewDirection.both);
    expect(ReviewDirection.germanToPersian.cardDirections, {forward});
    expect(ReviewDirection.persianToGerman.cardDirections, {reverse});
    expect(ReviewDirection.both.cardDirections, {forward, reverse});
    expect(
      [for (var i = 0; i < 4; i++) ReviewDirection.both.directionAt(i)],
      [forward, reverse, forward, reverse],
    );
  });
}
