import 'flashcard.dart';
import 'review_event.dart';
import 'review_queue.dart';

/// Scheduled (FSRS) review: which cards are due and recording answers.
///
/// Only explicit answers write anything. Vocabulary content and the manual
/// difficult mark are never changed.
abstract interface class StudyRepository {
  /// Cards due now in [deckId] (every deck when null) for [directions], in
  /// review order, at most [limit] (see [buildDueQueue]). Words without a
  /// meaning are never included.
  Future<List<DueCard>> dueQueue({
    String? deckId,
    required Set<CardDirection> directions,
    int? limit,
  });

  /// Number of cards [dueQueue] would return without a limit, updated when
  /// words, decks or scheduling state change.
  Stream<int> watchDueCount({
    String? deckId,
    required Set<CardDirection> directions,
  });

  /// Records [outcome] for the card ([entryId], [direction]) in one
  /// transaction: the FSRS state in `flashcards` is advanced (the row is
  /// created on the first answer) and a review event is stored.
  Future<(ReviewState, ReviewEvent)> recordAnswer({
    required String entryId,
    required CardDirection direction,
    required String sessionId,
    required ReviewOutcome outcome,
  });

  /// The stored state of a card, or null if it was never answered in
  /// scheduled review.
  Future<ReviewState?> cardState(String entryId, CardDirection direction);
}
