import 'package:flutter/foundation.dart';

/// What the learner does with a sentence.
///
/// Persisted by [name]; never rename existing values without a migration.
enum SentencePracticeDirection {
  /// A German sentence is shown; the learner writes what it means in
  /// Persian.
  understand,

  /// A Persian sentence is shown with the target word; the learner writes
  /// it in German.
  produce,
}

/// How hard the generated sentences are (CEFR-oriented).
///
/// Persisted by [name]; never rename existing values without a migration.
enum SentenceLevel {
  a2('A2'),
  b1('B1'),
  b2('B2');

  const SentenceLevel(this.cefr);

  final String cefr;
}

/// How one exercise ended. Only this is stored, never the learner's answer
/// or the AI's text.
///
/// Persisted by [name]; never rename existing values without a migration.
enum SentencePracticeOutcome {
  /// Correct, including the target word.
  correct,

  /// Correct, but phrased differently from the model answer.
  acceptable,

  /// Understandable with small mistakes.
  minorErrors,

  /// Wrong meaning, wrong or missing target word, or major grammar errors.
  incorrect,

  /// The model answer was shown without the answer being checked.
  revealed,

  /// Skipped without an answer.
  skipped,
}

/// One finished sentence exercise, as stored locally.
@immutable
class SentencePracticeEvent {
  const SentencePracticeEvent({
    required this.id,
    required this.entryId,
    required this.direction,
    required this.level,
    required this.outcome,
    required this.practicedAt,
  });

  final String id;
  final String entryId;
  final SentencePracticeDirection direction;
  final SentenceLevel level;
  final SentencePracticeOutcome outcome;

  /// UTC.
  final DateTime practicedAt;

  @override
  bool operator ==(Object other) =>
      other is SentencePracticeEvent &&
      other.id == id &&
      other.entryId == entryId &&
      other.direction == direction &&
      other.level == level &&
      other.outcome == outcome &&
      other.practicedAt == practicedAt;

  @override
  int get hashCode =>
      Object.hash(id, entryId, direction, level, outcome, practicedAt);
}

/// Local sentence-practice history. Writes only its own table: never
/// vocabulary content, `flashcards` or `review_events`.
abstract interface class SentencePracticeRepository {
  /// Records how an exercise for [entryId] ended, stamped with the current
  /// time.
  Future<SentencePracticeEvent> record({
    required String entryId,
    required SentencePracticeDirection direction,
    required SentenceLevel level,
    required SentencePracticeOutcome outcome,
  });

  /// The latest practice time (UTC) per entry that has any history.
  Future<Map<String, DateTime>> lastPracticedByEntry();

  /// Number of recorded exercises, updated on changes.
  Stream<int> watchCount();

  /// Deletes the whole sentence-practice history (and nothing else).
  /// Returns the number of records deleted.
  Future<int> clearHistory();
}
