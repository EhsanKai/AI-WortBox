import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/statistics/domain/study_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = LocalDay(2026, 10, 19);

  DayActivity day(int offset, [int reviews = 3, int remembered = 2]) =>
      DayActivity(
        day: today.addDays(offset),
        reviews: reviews,
        remembered: remembered,
      );

  StudyStatistics compute(List<DayActivity> activity) =>
      StudyStatistics.compute(
        totalWords: 10,
        difficultWords: 2,
        sessions: 4,
        activity: activity,
        today: today,
      );

  group('LocalDay', () {
    test('parse, format, arithmetic across month and DST boundaries', () {
      expect(LocalDay.parse('2026-03-29').toString(), '2026-03-29');
      expect(
        const LocalDay(2026, 3, 29).addDays(1),
        const LocalDay(2026, 3, 30),
      );
      expect(
        const LocalDay(2026, 10, 31).addDays(1),
        const LocalDay(2026, 11, 1),
      );
      expect(
        const LocalDay(2028, 2, 28).addDays(1),
        const LocalDay(2028, 2, 29),
      );
      expect(
        const LocalDay(
          2027,
          1,
          1,
        ).differenceInDays(const LocalDay(2026, 12, 31)),
        1,
      );
      expect(() => LocalDay.parse('2026-1-1'), throwsFormatException);
    });
  });

  test('empty: zeros, no streak, 14 empty days ending today', () {
    final stats = compute(const []);
    expect(stats.hasReviews, isFalse);
    expect(stats.totalReviews, 0);
    expect(stats.currentStreak, 0);
    expect(stats.longestStreak, 0);
    expect(stats.studyDays, 0);
    expect(stats.recentDays, hasLength(14));
    expect(stats.recentDays.last.day, today);
    expect(stats.recentDays.first.day, today.addDays(-13));
    expect(stats.recentDays.every((d) => d.reviews == 0), isTrue);
    expect(stats.totalWords, 10);
    expect(stats.difficultWords, 2);
  });

  test('several reviews on one day count as one study day', () {
    final stats = compute([day(0, 7, 5)]);
    expect(stats.studyDays, 1);
    expect(stats.currentStreak, 1);
    expect(stats.totalReviews, 7);
    expect(stats.rememberedReviews, 5);
  });

  test('consecutive days ending today', () {
    expect(compute([day(-2), day(-1), day(0)]).currentStreak, 3);
  });

  test('no review yet today: the streak ending yesterday still counts', () {
    final stats = compute([day(-3), day(-2), day(-1)]);
    expect(stats.currentStreak, 3);
  });

  test('a missed day breaks the current streak; longest is kept', () {
    final stats = compute([
      day(-10),
      day(-9),
      day(-8),
      day(-7),
      day(-3),
      day(-2),
    ]);
    // Yesterday (-1) and today are missing.
    expect(stats.currentStreak, 0);
    expect(stats.longestStreak, 4);
    expect(stats.studyDays, 6);
  });

  test('order of activity does not matter; zero-review days are ignored', () {
    final stats = compute([day(0), day(-2), day(-1, 0, 0), day(-1)]);
    expect(stats.currentStreak, 3);
  });
}
