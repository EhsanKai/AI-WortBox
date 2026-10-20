import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/memory_coach.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);
  var counter = 0;

  /// An answer for [entry] given [daysAgo] days (plus [minutes]) before
  /// [now], in session [session].
  ReviewEvent answer(
    String entry,
    ReviewOutcome outcome, {
    required String session,
    double daysAgo = 1,
    int minutes = 0,
    bool deleted = false,
  }) {
    final at = now.subtract(
      Duration(minutes: (daysAgo * 24 * 60).round() + minutes),
    );
    return ReviewEvent(
      id: 'e${counter++}'.padLeft(4, '0'),
      entryId: deleted ? null : entry,
      sessionId: session,
      direction: CardDirection.forward,
      outcome: outcome,
      reviewedAt: at,
      localDay: LocalDay.of(at),
    );
  }

  const forgot = ReviewOutcome.forgotten;
  const knew = ReviewOutcome.remembered;

  List<String> ids(Iterable<ReviewEvent> events) => [
    for (final w in findStrugglingWords(events, now: now)) w.entryId,
  ];

  test('no history, or only successful answers: nothing qualifies', () {
    expect(findStrugglingWords(const [], now: now), isEmpty);
    expect(
      ids([
        answer('a', knew, session: 's1', daysAgo: 3),
        answer('a', knew, session: 's2', daysAgo: 2),
      ]),
      isEmpty,
    );
  });

  test('a single failure, or failures in one session only (a new word '
      'forgotten twice in its first session), are not enough', () {
    expect(ids([answer('a', forgot, session: 's1')]), isEmpty);
    expect(
      ids([
        answer('new', forgot, session: 's1', minutes: 10),
        answer('new', forgot, session: 's1', minutes: 5),
        answer('new', knew, session: 's1'),
      ]),
      isEmpty,
    );
  });

  test('failures in two different sessions qualify, with the evidence', () {
    final words = findStrugglingWords([
      answer('a', forgot, session: 's1', daysAgo: 5),
      answer('a', knew, session: 's2', daysAgo: 4),
      answer('a', forgot, session: 's3', daysAgo: 2),
      answer('b', knew, session: 's3', daysAgo: 2),
    ], now: now);
    expect(words, hasLength(1));
    expect(words.single.entryId, 'a');
    expect(words.single.failures, 2);
    expect(words.single.attempts, 3);
    expect(words.single.lastFailedAt, now.subtract(const Duration(days: 2)));
  });

  test('recent success outweighs older failures: three correct answers in a '
      'row since the last failure remove the word', () {
    final failures = [
      answer('a', forgot, session: 's1', daysAgo: 6),
      answer('a', forgot, session: 's2', daysAgo: 5),
    ];
    expect(ids(failures), ['a']);
    final twoRight = [
      ...failures,
      answer('a', knew, session: 's3', daysAgo: 4),
      answer('a', knew, session: 's4', daysAgo: 3),
    ];
    expect(ids(twoRight), ['a'], reason: 'not yet recovered');
    expect(
      ids([...twoRight, answer('a', knew, session: 's5', daysAgo: 2)]),
      isEmpty,
    );
    // A new failure after the streak brings it back.
    expect(
      ids([
        ...twoRight,
        answer('a', knew, session: 's5', daysAgo: 2),
        answer('a', forgot, session: 's6', daysAgo: 1),
      ]),
      ['a'],
    );
  });

  test('only the last 8 answers within 30 days count', () {
    // Old failures outside the lookback are ignored.
    expect(
      ids([
        answer('a', forgot, session: 's1', daysAgo: 40),
        answer('a', forgot, session: 's2', daysAgo: 35),
        answer('a', forgot, session: 's3', daysAgo: 2),
      ]),
      isEmpty,
    );
    // Failures pushed out of the 8-answer window by later answers are
    // ignored (here: 8 later answers with one failure, so there is no
    // recovery streak but only one failed session in the window).
    final events = [
      answer('a', forgot, session: 's0', daysAgo: 20),
      answer('a', forgot, session: 's1', daysAgo: 19),
      for (var i = 0; i < 8; i++)
        answer(
          'a',
          i == 6 ? forgot : knew,
          session: 'later$i',
          daysAgo: 12 - i.toDouble(),
        ),
    ];
    final words = findStrugglingWords(events, now: now);
    expect(words, isEmpty, reason: 'one failed session left in the window');
  });

  test('the rule is configurable', () {
    final events = [
      answer('a', forgot, session: 's1', daysAgo: 3),
      answer('a', knew, session: 's2', daysAgo: 2),
    ];
    expect(ids(events), isEmpty);
    expect(
      findStrugglingWords(
        events,
        now: now,
        rule: const MemoryCoachRule(minFailedSessions: 1),
      ).map((w) => w.entryId),
      ['a'],
    );
  });

  test('deleted words are ignored; order is most failures first, then the '
      'most recent failure, deterministically', () {
    final words = findStrugglingWords([
      answer('gone', forgot, session: 's1', deleted: true),
      answer('gone', forgot, session: 's2', deleted: true),
      for (final s in ['s1', 's2'])
        answer('two-old', forgot, session: s, daysAgo: s == 's1' ? 9 : 8),
      for (final s in ['s3', 's4'])
        answer('two-new', forgot, session: s, daysAgo: s == 's3' ? 3 : 2),
      for (final s in ['s1', 's2', 's3'])
        answer('three', forgot, session: s, daysAgo: 7),
    ], now: now);
    expect(words.map((w) => w.entryId), ['three', 'two-new', 'two-old']);
  });
}
