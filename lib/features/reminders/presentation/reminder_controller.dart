import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app.dart';
import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/reminder.dart';

/// The daily study reminder. State changes only after the system call and
/// the settings write both succeeded, so the screen never shows a reminder
/// that is not scheduled (or one that was not cancelled).
class ReminderController extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async {
    final store = ref.watch(settingsStoreProvider);
    return ReminderSettings.fromStored(
      enabled: await store.read(ReminderSettings.enabledKey),
      time: await store.read(ReminderSettings.timeKey),
    );
  }

  ReminderSettings get _current => state.requireValue;

  /// Asks for notification permission, schedules and saves. Throws
  /// [ReminderException] (nothing is saved).
  Future<void> enable() async {
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!await scheduler.requestPermission()) {
      throw const ReminderException(ReminderError.permissionDenied);
    }
    await _schedule(_current);
    await _save(_current.copyWith(enabled: true));
  }

  /// Cancels and saves. Throws [ReminderException] when cancelling fails
  /// (the reminder stays on).
  Future<void> disable() async {
    await ref.read(reminderSchedulerProvider).cancel();
    await _save(_current.copyWith(enabled: false));
  }

  /// Changes the time; an active reminder is rescheduled (replacing the old
  /// one, never adding a second).
  Future<void> setTime(int hour, int minute) async {
    final updated = _current.copyWith(hour: hour, minute: minute);
    if (updated.enabled) await _schedule(updated);
    await _save(updated);
  }

  /// Re-creates an enabled reminder at app start (e.g. after an update or a
  /// time-zone change). Never asks for permission; failures are ignored
  /// because the user did not just ask for anything.
  Future<void> syncOnStartup() async {
    try {
      final settings = await future;
      if (settings.enabled) await _schedule(settings);
    } on Object {
      // Shown again when the user opens the reminder settings.
    }
  }

  Future<void> _schedule(ReminderSettings settings) {
    final l10n = lookupAppLocalizations(appLocale);
    return ref
        .read(reminderSchedulerProvider)
        .scheduleDaily(
          hour: settings.hour,
          minute: settings.minute,
          title: l10n.reminderNotificationTitle,
          body: l10n.reminderNotificationBody,
        );
  }

  Future<void> _save(ReminderSettings settings) async {
    await ref.read(settingsStoreProvider).writeAll(settings.toStored());
    state = AsyncData(settings);
  }
}

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderSettings>(
      ReminderController.new,
    );
