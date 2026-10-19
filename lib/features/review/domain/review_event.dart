import 'package:flutter/foundation.dart';

import 'flashcard.dart';

/// What the learner reported after the answer was revealed.
///
/// Persisted by [name]; never rename existing values without a migration.
enum ReviewOutcome { remembered, forgotten }

/// One explicitly recorded review: the learner revealed the answer and chose
/// an outcome. Nothing else (opening the app or a word) creates an event.
///
/// Events are history: they are kept when the word is deleted ([entryId]
/// becomes null), so statistics do not change retroactively.
@immutable
class ReviewEvent {
  const ReviewEvent({
    required this.id,
    required this.entryId,
    required this.sessionId,
    required this.direction,
    required this.outcome,
    required this.reviewedAt,
    required this.localDay,
  });

  final String id;
  final String? entryId;

  /// Groups the events of one review session.
  final String sessionId;
  final CardDirection direction;
  final ReviewOutcome outcome;

  /// UTC.
  final DateTime reviewedAt;

  /// The device's local calendar day when the review happened, fixed at
  /// recording time (see [LocalDay]).
  final LocalDay localDay;

  @override
  bool operator ==(Object other) =>
      other is ReviewEvent &&
      other.id == id &&
      other.entryId == entryId &&
      other.sessionId == sessionId &&
      other.direction == direction &&
      other.outcome == outcome &&
      other.reviewedAt == reviewedAt &&
      other.localDay == localDay;

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    sessionId,
    direction,
    outcome,
    reviewedAt,
    localDay,
  );
}

/// A calendar day without time or zone, e.g. 2026-10-17.
///
/// Day-boundary policy: a review belongs to the local calendar day (midnight
/// to midnight) of the device at the moment it is recorded, and that day is
/// stored with the event. Changing the device time zone later does not move
/// past reviews to another day.
@immutable
class LocalDay implements Comparable<LocalDay> {
  const LocalDay(this.year, this.month, this.day);

  /// The calendar day of [local], which must already be in local time.
  factory LocalDay.of(DateTime local) =>
      LocalDay(local.year, local.month, local.day);

  /// Parses `YYYY-MM-DD`.
  factory LocalDay.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Invalid day', value);
    return LocalDay(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  final int year;
  final int month;
  final int day;

  // UTC arithmetic avoids daylight-saving gaps when stepping days.
  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDay addDays(int days) => LocalDay.of(_utc.add(Duration(days: days)));

  /// Whole days from [other] to this day.
  int differenceInDays(LocalDay other) => _utc.difference(other._utc).inDays;

  @override
  int compareTo(LocalDay other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
