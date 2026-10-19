import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../review/domain/review_event.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../domain/study_statistics.dart';

final _dailyActivityProvider = StreamProvider<List<DayActivity>>(
  (ref) => ref.watch(reviewRepositoryProvider).watchDailyActivity(),
);

final _sessionCountProvider = StreamProvider<int>(
  (ref) => ref.watch(reviewRepositoryProvider).watchSessionCount(),
);

/// Statistics from the stored vocabulary and review events, for today's
/// local day.
final studyStatisticsProvider = Provider<AsyncValue<StudyStatistics>>((ref) {
  final counts = ref.watch(vocabularyCountsProvider);
  final activity = ref.watch(_dailyActivityProvider);
  final sessions = ref.watch(_sessionCountProvider);
  final clock = ref.watch(clockProvider);
  for (final value in [counts, activity, sessions]) {
    if (value case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  if (!counts.hasValue || !activity.hasValue || !sessions.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(
    StudyStatistics.compute(
      totalWords: counts.requireValue.total,
      difficultWords: counts.requireValue.difficult,
      sessions: sessions.requireValue,
      activity: activity.requireValue,
      today: LocalDay.of(clock.toLocal(clock.nowUtc())),
    ),
  );
});
