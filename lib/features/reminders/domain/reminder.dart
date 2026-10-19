import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

/// A daily local study reminder. Off by default.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
  }) : assert(hour >= 0 && hour < 24),
       assert(minute >= 0 && minute < 60);

  /// Reads persisted values; anything malformed falls back to the default
  /// (off at 19:00).
  factory ReminderSettings.fromStored({String? enabled, String? time}) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(time ?? '');
    final hour = int.tryParse(match?[1] ?? '');
    final minute = int.tryParse(match?[2] ?? '');
    final valid = hour != null && minute != null && hour < 24 && minute < 60;
    return ReminderSettings(
      enabled: enabled == 'true',
      hour: valid ? hour : 19,
      minute: valid ? minute : 0,
    );
  }

  static const enabledKey = 'reminder.enabled';
  static const timeKey = 'reminder.time';

  final bool enabled;

  /// Local wall-clock time of day.
  final int hour;
  final int minute;

  String get storedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, String> toStored() => {
    enabledKey: enabled.toString(),
    timeKey: storedTime,
  };

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);

  @override
  String toString() => 'ReminderSettings($enabled, $storedTime)';
}

/// The next time [hour]:[minute] occurs on the wall clock of [now]'s
/// location, strictly after [now].
///
/// Built from calendar fields in that location, so it stays at the same
/// local time across daylight-saving changes. A time that does not exist on
/// a spring-forward day (e.g. 02:30) is moved forward by the gap, as the
/// `timezone` package resolves it.
tz.TZDateTime nextReminderTime(tz.TZDateTime now, int hour, int minute) {
  var candidate = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  var day = 1;
  while (!candidate.isAfter(now)) {
    candidate = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + day++,
      hour,
      minute,
    );
  }
  return candidate;
}

/// Schedules the one daily reminder notification. Implementations use a
/// single fixed notification id, so scheduling again replaces the previous
/// reminder instead of adding another.
abstract interface class ReminderScheduler {
  /// Asks the user for permission to show notifications (only when they
  /// turn the reminder on). Returns whether it is granted.
  Future<bool> requestPermission();

  /// Schedules (or replaces) the daily reminder at [hour]:[minute] local
  /// time. Throws `ReminderException(schedulingFailed)`.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// Cancels the reminder. Throws `ReminderException(schedulingFailed)`.
  Future<void> cancel();
}
