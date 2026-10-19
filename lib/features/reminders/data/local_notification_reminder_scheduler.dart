import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/error/app_exception.dart';
import '../domain/reminder.dart';

/// [ReminderScheduler] using on-device notifications
/// (`flutter_local_notifications`). Nothing is sent to a server.
///
/// - One notification id ([_id]); scheduling replaces it.
/// - Repeats daily at the local wall-clock time
///   (`DateTimeComponents.time`), in the device's IANA time zone.
/// - Android: inexact delivery (`inexactAllowWhileIdle`), so no exact-alarm
///   permission is needed; the system may deliver it some minutes late.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _ready;

  static const _id = 1001;
  static const _channelId = 'study_reminder';

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Never ask at startup; only when the user turns the reminder on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    try {
      await _init();
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      }
      return false;
    } on Object {
      _ready = null;
      throw const ReminderException(ReminderError.schedulingFailed);
    }
  }

  @override
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      await _init();
      await _plugin.cancel(id: _id);
      await _plugin.zonedSchedule(
        id: _id,
        title: title,
        body: body,
        scheduledDate: nextReminderTime(
          tz.TZDateTime.now(tz.local),
          hour,
          minute,
        ),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            title,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on Object {
      throw const ReminderException(ReminderError.schedulingFailed);
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _init();
      await _plugin.cancel(id: _id);
    } on Object {
      throw const ReminderException(ReminderError.schedulingFailed);
    }
  }
}
