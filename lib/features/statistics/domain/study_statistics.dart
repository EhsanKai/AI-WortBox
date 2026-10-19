import 'package:flutter/foundation.dart';

import '../../review/domain/review_event.dart';

/// Reviews recorded on one local day.
@immutable
class DayActivity {
  const DayActivity({
    required this.day,
    required this.reviews,
    required this.remembered,
  });

  final LocalDay day;
  final int reviews;
  final int remembered;

  @override
  bool operator ==(Object other) =>
      other is DayActivity &&
      other.day == day &&
      other.reviews == reviews &&
      other.remembered == remembered;

  @override
  int get hashCode => Object.hash(day, reviews, remembered);

  @override
  String toString() => 'DayActivity($day, $reviews, $remembered)';
}

/// Statistics derived only from stored data: the vocabulary tables and
/// explicitly recorded review events. Nothing is estimated.
///
/// Streak policy:
/// - a *study day* is a local day (see [LocalDay]) with at least one
///   recorded review; several reviews on one day count once;
/// - the *current streak* is the number of consecutive study days ending
///   today, or ending yesterday when there is no review yet today (the day
///   is not over); otherwise it is 0;
/// - the *longest streak* is the longest run of consecutive study days.
@immutable
class StudyStatistics {
  const StudyStatistics({
    required this.totalWords,
    required this.difficultWords,
    required this.totalReviews,
    required this.rememberedReviews,
    required this.sessions,
    required this.studyDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.recentDays,
  });

  /// Computes the statistics. [activity] may be in any order; [today] is
  /// the current local day.
  factory StudyStatistics.compute({
    required int totalWords,
    required int difficultWords,
    required int sessions,
    required List<DayActivity> activity,
    required LocalDay today,
    int recentDayCount = 14,
  }) {
    final byDay = <LocalDay, DayActivity>{
      for (final a in activity)
        if (a.reviews > 0) a.day: a,
    };
    final days = byDay.keys.toList()..sort();

    var longest = 0;
    var run = 0;
    LocalDay? previous;
    for (final day in days) {
      run = previous != null && day.differenceInDays(previous) == 1
          ? run + 1
          : 1;
      if (run > longest) longest = run;
      previous = day;
    }

    var current = 0;
    var cursor = byDay.containsKey(today) ? today : today.addDays(-1);
    while (byDay.containsKey(cursor)) {
      current++;
      cursor = cursor.addDays(-1);
    }

    return StudyStatistics(
      totalWords: totalWords,
      difficultWords: difficultWords,
      totalReviews: activity.fold(0, (sum, a) => sum + a.reviews),
      rememberedReviews: activity.fold(0, (sum, a) => sum + a.remembered),
      sessions: sessions,
      studyDays: days.length,
      currentStreak: current,
      longestStreak: longest,
      recentDays: [
        for (var i = recentDayCount - 1; i >= 0; i--)
          byDay[today.addDays(-i)] ??
              DayActivity(day: today.addDays(-i), reviews: 0, remembered: 0),
      ],
    );
  }

  final int totalWords;
  final int difficultWords;
  final int totalReviews;
  final int rememberedReviews;

  /// Review sessions with at least one recorded review.
  final int sessions;
  final int studyDays;
  final int currentStreak;
  final int longestStreak;

  /// The last days up to today, oldest first, including days without
  /// reviews.
  final List<DayActivity> recentDays;

  bool get hasReviews => totalReviews > 0;
}
