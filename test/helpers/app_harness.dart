import 'dart:math';
import 'dart:typed_data';

import 'package:ai_wortbox/app/app.dart';
import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/about/data/app_info_source.dart';
import 'package:ai_wortbox/features/about/domain/release_notes.dart';
import 'package:ai_wortbox/features/about/presentation/about_providers.dart';
import 'package:ai_wortbox/features/csv_import/data/csv_file_source.dart';
import 'package:ai_wortbox/features/enrichment/data/ai_settings_store.dart';
import 'package:ai_wortbox/features/enrichment/presentation/enrichment_controller.dart';
import 'package:ai_wortbox/features/scan/data/image_cropper.dart';
import 'package:ai_wortbox/features/scan/data/scan_image_source.dart';
import 'package:ai_wortbox/features/scan/data/text_recognition_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'ai_fakes.dart';
import 'phase5_fakes.dart';
import 'scan_fakes.dart';

/// A valid 1×1 transparent PNG.
final onePixelPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Returns a fixed file, or null to simulate cancelling the picker.
class FakeCsvFileSource implements CsvFileSource {
  FakeCsvFileSource(this.file);

  PickedCsvFile? file;

  @override
  Future<PickedCsvFile?> pick() async => file;
}

/// A fixed installed version instead of the platform's package info.
class FakeAppInfoSource implements AppInfoSource {
  FakeAppInfoSource({this.version = '1.0.0', this.buildNumber = '3'});

  final String version;
  final String buildNumber;

  @override
  Future<InstalledVersion> installedVersion() async =>
      InstalledVersion(version: version, buildNumber: buildNumber);
}

/// Pumps the full app on a phone-sized viewport with an in-memory database.
///
/// [size] is the logical viewport (default 390×844), [textScale] the system
/// text scale and [brightness] the system theme.
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  String initialLocation = '/today',
  CsvFileSource? fileSource,
  ScanImageSource? imageSource,
  TextRecognitionEngine? recognitionEngine,
  ImageCropper? imageCropper,
  AiSettingsStore? aiSettings,
  http.Client? httpClient,
  List<Uri>? launchedUrls,
  FakeSpeechService? speech,
  FakeReminderScheduler? reminders,
  FakeExportSink? exportSink,
  Clock? clock,
  EnrichmentJobRegistry? enrichmentJobs,
  AppInfoSource? appInfo,
  Locale locale = const Locale('fa'),
  List<Override> extraOverrides = const [],
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  // Unmount even when the test fails, so Drift streams are cancelled before
  // the database is closed (otherwise closing it waits forever).
  addTearDown(() => tester.pumpWidget(const SizedBox()));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(
          clock ?? FixedClock(DateTime.utc(2026, 10, 15, 8)),
        ),
        // Never the real TTS engine, notifications or save dialog in tests;
        // practice order is deterministic.
        speechServiceProvider.overrideWithValue(speech ?? FakeSpeechService()),
        reminderSchedulerProvider.overrideWithValue(
          reminders ?? FakeReminderScheduler(),
        ),
        exportFileSinkProvider.overrideWithValue(
          exportSink ?? FakeExportSink(),
        ),
        randomProvider.overrideWithValue(Random(1)),
        idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        if (fileSource != null)
          csvFileSourceProvider.overrideWithValue(fileSource),
        if (imageSource != null)
          scanImageSourceProvider.overrideWithValue(imageSource),
        if (recognitionEngine != null)
          textRecognitionEngineProvider.overrideWithValue(recognitionEngine),
        // Photos are never decoded or cropped for real in tests.
        imageCropperProvider.overrideWithValue(
          imageCropper ?? FakeImageCropper(),
        ),
        // Page photos are never read from disk in tests.
        scanPageImageProvider.overrideWithValue(
          (_) => MemoryImage(onePixelPng),
        ),
        // Never the real Keychain/Keystore or the network in tests.
        aiSettingsStoreProvider.overrideWithValue(
          aiSettings ?? InMemoryAiSettingsStore(),
        ),
        httpClientProvider.overrideWithValue(httpClient ?? noNetworkClient),
        if (enrichmentJobs != null)
          enrichmentJobRegistryProvider.overrideWithValue(enrichmentJobs),
        // Request spacing and backoff do not wait in tests.
        aiSleepProvider.overrideWithValue((_) async {}),
        urlLauncherProvider.overrideWithValue((uri) async {
          launchedUrls?.add(uri);
          return true;
        }),
        // The platform's package info is not available on the host.
        appInfoSourceProvider.overrideWithValue(appInfo ?? FakeAppInfoSource()),
        ...extraOverrides,
      ],
      retry: (_, _) => null,
      child: AiWortBoxApp(initialLocation: initialLocation, locale: locale),
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

/// On the photo screen, reads the whole page as text (the explicit menu
/// action; photos are otherwise only read where the user highlights).
Future<void> readWholePageAsText(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('scan.more')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('scan.wholePage')));
  await tester.pumpAndSettle();
}
