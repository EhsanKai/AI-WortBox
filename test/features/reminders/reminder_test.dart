import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/reminders/domain/reminder.dart';
import 'package:ai_wortbox/features/reminders/presentation/reminder_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/phase5_fakes.dart';
import '../../helpers/test_database.dart';

void main() {
  // Locations are looked up while tests are declared.
  tz_data.initializeTimeZones();

  group('nextReminderTime', () {
    final berlin = tz.getLocation('Europe/Berlin');
    final tehran = tz.getLocation('Asia/Tehran');

    test('later today, or tomorrow once the time has passed', () {
      final morning = tz.TZDateTime(berlin, 2026, 10, 19, 8);
      expect(
        nextReminderTime(morning, 19, 0),
        tz.TZDateTime(berlin, 2026, 10, 19, 19),
      );
      final evening = tz.TZDateTime(berlin, 2026, 10, 19, 19, 0);
      expect(
        nextReminderTime(evening, 19, 0),
        tz.TZDateTime(berlin, 2026, 10, 20, 19),
      );
    });

    test('same local time across the autumn DST change (25 hours later)', () {
      // Berlin leaves summer time on 25 October 2026.
      final before = tz.TZDateTime(berlin, 2026, 10, 24, 20);
      final next = nextReminderTime(before, 19, 0);
      expect(next, tz.TZDateTime(berlin, 2026, 10, 25, 19));
      expect(next.hour, 19);
      expect(next.timeZoneOffset, const Duration(hours: 1));
      expect(
        next.difference(tz.TZDateTime(berlin, 2026, 10, 24, 19)),
        const Duration(hours: 25),
      );
    });

    test('a time in the spring-forward gap is moved forward, not skipped', () {
      // 29 March 2026, 02:00–03:00 does not exist in Berlin.
      final now = tz.TZDateTime(berlin, 2026, 3, 28, 23);
      final next = nextReminderTime(now, 2, 30);
      expect(next.day, 29);
      expect(next.hour, 3);
      expect(next.minute, 30);
    });

    test('zones without daylight saving', () {
      final now = tz.TZDateTime(tehran, 2026, 10, 19, 23, 59);
      expect(nextReminderTime(now, 0, 0), tz.TZDateTime(tehran, 2026, 10, 20));
    });
  });

  group('ReminderSettings', () {
    test('defaults: off at 19:00; malformed values fall back', () {
      expect(ReminderSettings.fromStored(), const ReminderSettings());
      expect(
        ReminderSettings.fromStored(enabled: 'yes', time: '25:00'),
        const ReminderSettings(),
      );
      expect(
        ReminderSettings.fromStored(enabled: 'true', time: '07:05'),
        const ReminderSettings(enabled: true, hour: 7, minute: 5),
      );
      expect(const ReminderSettings(hour: 7, minute: 5).storedTime, '07:05');
    });
  });

  group('ReminderController', () {
    late AppDatabase db;
    late FakeReminderScheduler scheduler;
    late ProviderContainer container;

    ProviderContainer create() => ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
      retry: (_, _) => null,
    );

    setUp(() {
      db = openTestDatabase();
      scheduler = FakeReminderScheduler();
      container = create();
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    ReminderController controller() =>
        container.read(reminderControllerProvider.notifier);
    Future<ReminderSettings> current() =>
        container.read(reminderControllerProvider.future);

    test('starts off; nothing scheduled and no permission asked', () async {
      expect(await current(), const ReminderSettings());
      expect(scheduler.permissionRequests, 0);
      expect(scheduler.scheduled, isEmpty);
    });

    test('permission denied: stays off, nothing scheduled or saved', () async {
      await current();
      scheduler.grantPermission = false;
      await expectLater(
        controller().enable(),
        throwsA(
          isA<ReminderException>().having(
            (e) => e.error,
            'error',
            ReminderError.permissionDenied,
          ),
        ),
      );
      expect((await current()).enabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
      expect(await db.select(db.appSettings).get(), isEmpty);
    });

    test('enable schedules one reminder and persists across restarts; '
        'rescheduling replaces it; disable cancels it', () async {
      await current();
      await controller().enable();
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, {1: (19, 0, 'وقت مرور لغت‌هاست')});

      await controller().setTime(7, 30);
      expect(scheduler.scheduled.keys, [1]);
      expect(scheduler.scheduled[1]!.$1, 7);
      expect(scheduler.scheduled[1]!.$2, 30);

      // "Restart": a new container reads the stored settings.
      container.dispose();
      container = create();
      expect(
        await current(),
        const ReminderSettings(enabled: true, hour: 7, minute: 30),
      );
      await controller().syncOnStartup();
      expect(scheduler.scheduled.keys, [1]);
      expect(scheduler.permissionRequests, 1); // not asked again

      await controller().disable();
      expect(scheduler.scheduled, isEmpty);
      expect((await current()).enabled, isFalse);
      container.dispose();
      container = create();
      expect((await current()).enabled, isFalse);
    });

    test('changing the time while off only saves it', () async {
      await current();
      await controller().setTime(6, 0);
      expect(scheduler.scheduleCalls, 0);
      expect(await current(), const ReminderSettings(hour: 6, minute: 0));
    });

    test('scheduling failure: not saved as on', () async {
      await current();
      scheduler.failScheduling = true;
      await expectLater(
        controller().enable(),
        throwsA(isA<ReminderException>()),
      );
      expect((await current()).enabled, isFalse);
      expect(await db.select(db.appSettings).get(), isEmpty);
    });

    test('cancel failure: stays on (it may still fire)', () async {
      await current();
      await controller().enable();
      scheduler.failCancel = true;
      await expectLater(
        controller().disable(),
        throwsA(isA<ReminderException>()),
      );
      expect((await current()).enabled, isTrue);
    });

    test('startup sync does nothing when off and ignores failures', () async {
      await controller().syncOnStartup();
      expect(scheduler.scheduleCalls, 0);
      await controller().enable();
      scheduler.failScheduling = true;
      await controller().syncOnStartup();
      expect((await current()).enabled, isTrue);
    });
  });
}
