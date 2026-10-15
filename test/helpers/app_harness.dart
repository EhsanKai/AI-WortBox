import 'package:ai_wortbox/app/app.dart';
import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/csv_import/data/csv_file_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a fixed file, or null to simulate cancelling the picker.
class FakeCsvFileSource implements CsvFileSource {
  FakeCsvFileSource(this.file);

  PickedCsvFile? file;

  @override
  Future<PickedCsvFile?> pick() async => file;
}

/// Pumps the full app on a phone-sized viewport with an in-memory database.
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  String initialLocation = '/today',
  CsvFileSource? fileSource,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2026, 10, 15, 8)),
        ),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        if (fileSource != null)
          csvFileSourceProvider.overrideWithValue(fileSource),
      ],
      retry: (_, _) => null,
      child: AiWortBoxApp(initialLocation: initialLocation),
    ),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so Drift streams are cancelled before the database closes.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

/// The scrollable of the topmost visible screen (routes below stay mounted).
Finder visibleScrollable() => find.byType(Scrollable).hitTestable().first;

/// Scrolls the visible list (down, then up) until [finder] is built and
/// visible, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls the visible list until [finder] is built, in either direction.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    try {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: visibleScrollable(),
        maxScrolls: 30,
      );
    } on StateError {
      await tester.scrollUntilVisible(
        finder,
        -200,
        scrollable: visibleScrollable(),
        maxScrolls: 30,
      );
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
