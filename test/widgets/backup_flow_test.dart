import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/backup/data/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/backup_fakes.dart';
import '../helpers/learning_data.dart';
import '../helpers/phase5_fakes.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late MemorySafetyStore safety;
  late FakeBackupFileSource files;

  setUp(() {
    db = openTestDatabase();
    safety = MemorySafetyStore();
    files = FakeBackupFileSource();
  });
  tearDown(() => db.close());

  /// A backup made from separately seeded learning data.
  Future<Uint8List> otherDeviceBackup() async {
    final other = openTestDatabase();
    addTearDown(other.close);
    await seedLearningData(other, idPrefix: 'other');
    return BackupService(
      other,
      clock: FixedClock(DateTime.utc(2026, 10, 19, 18)),
      ids: SequentialIdGenerator('x'),
      safety: MemorySafetyStore(),
    ).createBackup();
  }

  Future<void> open(
    WidgetTester tester, {
    FakeExportSink? sink,
    Locale locale = const Locale('fa'),
  }) => pumpApp(
    tester,
    db,
    initialLocation: '/settings/backup',
    exportSink: sink,
    locale: locale,
    extraOverrides: [
      safetyBackupStoreProvider.overrideWithValue(safety),
      backupFileSourceProvider.overrideWithValue(files),
    ],
  );

  testWidgets('Settings has a Data section that opens backup and restore', (
    tester,
  ) async {
    await pumpApp(tester, db, initialLocation: '/settings');
    await scrollAndTap(tester, find.byKey(const Key('settings.backup')));
    expect(find.byKey(const Key('backup.save')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('backup.pick')));
    expect(find.byKey(const Key('backup.pick')), findsOneWidget);
  });

  testWidgets('saving a backup writes a complete, valid JSON file', (
    tester,
  ) async {
    await seedLearningData(db);
    final sink = FakeExportSink();
    await open(tester, sink: sink);

    await scrollAndTap(tester, find.byKey(const Key('backup.save')));

    expect(find.text('فایل پشتیبان ذخیره شد.'), findsOneWidget);
    final (name, bytes, mime) = sink.saved.single;
    expect(name, endsWith('.json'));
    expect(mime, 'application/json');
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(json['format'], 'ai-wortbox-backup');
    expect((json['app'] as Map)['build'], '3');
    expect((json['counts'] as Map)['entries'], 3);
  });

  testWidgets('merge: preview, then add the missing data without changing '
      'or deleting anything', (tester) async {
    files.bytes = await otherDeviceBackup();
    await seedLearningData(db, idPrefix: 'local');
    final before = await dumpLearningData(db);
    await open(tester);

    await scrollAndTap(tester, find.byKey(const Key('backup.pick')));
    expect(find.byKey(const Key('backup.preview')), findsOneWidget);
    // Nothing is written by choosing and previewing a file.
    expect(await dumpLearningData(db), before);

    await scrollAndTap(tester, find.byKey(const Key('backup.merge')));
    expect(find.byKey(const Key('backup.result')), findsOneWidget);

    final after = await dumpLearningData(db);
    for (final table in before.keys) {
      for (final row in before[table]!) {
        expect(after[table], contains(equals(row)), reason: '$table $row');
      }
    }
    // Same deck names: the words were already there (no new meanings).
    expect(after['vocabulary_entries'], hasLength(3));
    expect(safety.saved, hasLength(1));
  });

  testWidgets('replace needs an explicit confirmation; cancelling changes '
      'nothing; confirming replaces everything after a safety copy', (
    tester,
  ) async {
    final backup = await otherDeviceBackup();
    files.bytes = backup;
    await seedLearningData(db, idPrefix: 'local');
    final before = await dumpLearningData(db);
    await open(tester);

    await scrollAndTap(tester, find.byKey(const Key('backup.pick')));
    await scrollAndTap(tester, find.byKey(const Key('backup.replace')));
    expect(find.text('همهٔ داده‌ها جایگزین شود؟'), findsOneWidget);
    expect(find.textContaining('نسخهٔ ایمنی'), findsWidgets);

    await tester.tap(find.byKey(const Key('backup.replaceCancel')));
    await tester.pumpAndSettle();
    expect(await dumpLearningData(db), before);
    expect(safety.saved, isEmpty);

    await scrollAndTap(tester, find.byKey(const Key('backup.replace')));
    await tester.tap(find.byKey(const Key('backup.replaceConfirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backup.result')), findsOneWidget);

    final restored = await dumpLearningData(db);
    expect(
      restored['vocabulary_entries']!.map((r) => r['id']),
      everyElement(startsWith('other-')),
    );
    expect(safety.saved, hasLength(1));

    // The safety copy is offered afterwards and holds the old data.
    await scrollAndTap(tester, find.byKey(const Key('backup.done')));
    await scrollTo(tester, find.byKey(const Key('backup.safetyCopy')));
    expect(find.byKey(const Key('backup.safetyCopy')), findsOneWidget);
  });

  testWidgets('an invalid file shows a localized error and changes nothing', (
    tester,
  ) async {
    await seedLearningData(db);
    final before = await dumpLearningData(db);
    files.bytes = Uint8List.fromList(utf8.encode('Haus;خانه\n'));
    await open(tester);

    await scrollAndTap(tester, find.byKey(const Key('backup.pick')));

    expect(find.byKey(const Key('backup.error')), findsOneWidget);
    expect(
      find.text('این فایل، فایل پشتیبان AI WortBox نیست یا ناقص است.'),
      findsOneWidget,
    );
    expect(find.textContaining('هیچ داده‌ای تغییر نکرد.'), findsOneWidget);
    expect(await dumpLearningData(db), before);
  });

  testWidgets('a failed safety copy stops the restore with a clear message', (
    tester,
  ) async {
    files.bytes = await otherDeviceBackup();
    await seedLearningData(db, idPrefix: 'local');
    final before = await dumpLearningData(db);
    safety.failing = true;
    await open(tester);

    await scrollAndTap(tester, find.byKey(const Key('backup.pick')));
    await scrollAndTap(tester, find.byKey(const Key('backup.merge')));

    expect(find.byKey(const Key('backup.error')), findsOneWidget);
    expect(
      find.textContaining('نسخهٔ ایمنی داده‌های فعلی ذخیره نشد'),
      findsOneWidget,
    );
    expect(await dumpLearningData(db), before);
  });

  testWidgets('English: left-to-right with English messages', (tester) async {
    files.bytes = await otherDeviceBackup();
    await open(tester, locale: const Locale('en'));
    expect(find.text('Backup and restore'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('backup.save')))),
      TextDirection.ltr,
    );
    await scrollAndTap(tester, find.byKey(const Key('backup.pick')));
    expect(find.text('What the backup contains'), findsOneWidget);
    expect(find.text('Add to my current data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
