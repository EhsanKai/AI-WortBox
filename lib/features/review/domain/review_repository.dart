import '../../statistics/domain/study_statistics.dart';
import 'flashcard.dart';
import 'review_event.dart';

/// Stores explicitly recorded reviews. Never writes vocabulary content or
/// the scheduling state in `flashcards`.
abstract interface class ReviewRepository {
  /// Records one outcome for [entryId] in [sessionId], stamped with the
  /// current time and the device's local day.
  Future<ReviewEvent> record({
    required String entryId,
    required String sessionId,
    required CardDirection direction,
    required ReviewOutcome outcome,
  });

  /// Review counts per local day (days without reviews are absent).
  Stream<List<DayActivity>> watchDailyActivity();

  /// Number of distinct sessions with at least one review.
  Stream<int> watchSessionCount();
}
