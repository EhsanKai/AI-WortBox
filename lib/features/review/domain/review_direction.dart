import 'flashcard.dart';

/// Which side of a word is asked in review, chosen by the learner.
///
/// Persisted by [name] in `app_settings` ([settingsKey]); never rename
/// existing values.
enum ReviewDirection {
  /// The German word is shown; the Persian meaning is recalled. The default.
  germanToPersian,

  /// The Persian meaning is shown; the German word is recalled.
  persianToGerman,

  /// Both, as two independently scheduled cards per word. A word is asked
  /// in only one direction per day (see `StudyRepository.dueQueue`).
  both;

  static const settingsKey = 'review.direction';

  static const fallback = ReviewDirection.germanToPersian;

  /// [ReviewDirection.fallback] for missing or unknown stored values.
  static ReviewDirection parse(String? value) => ReviewDirection.values
      .firstWhere((d) => d.name == value, orElse: () => fallback);

  /// The card directions reviewed with this setting.
  Set<CardDirection> get cardDirections => switch (this) {
    germanToPersian => const {CardDirection.forward},
    persianToGerman => const {CardDirection.reverse},
    both => const {CardDirection.forward, CardDirection.reverse},
  };

  /// Direction of the [index]th word in unscheduled practice: alternates
  /// German → Persian and Persian → German when [both] is chosen.
  CardDirection directionAt(int index) => switch (this) {
    germanToPersian => CardDirection.forward,
    persianToGerman => CardDirection.reverse,
    both => index.isEven ? CardDirection.forward : CardDirection.reverse,
  };
}
