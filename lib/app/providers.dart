import 'dart:io';
import 'dart:math';

import 'package:flutter/painting.dart' show FileImage, ImageProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/id/id_generator.dart';
import '../core/time/clock.dart';
import '../data/database/app_database.dart';
import '../features/backup/data/backup_file_source.dart';
import '../features/backup/data/backup_service.dart';
import '../features/backup/data/safety_backup_store.dart';
import '../features/card_appearance/data/drift_card_appearance_repository.dart';
import '../features/card_appearance/domain/card_appearance.dart';
import '../features/csv_import/data/csv_file_source.dart';
import '../features/decks/data/drift_deck_repository.dart';
import '../features/decks/domain/deck_repository.dart';
import '../features/enrichment/data/ai_local_store.dart';
import '../features/enrichment/data/ai_settings_store.dart';
import '../features/enrichment/data/enrichment_cache.dart';
import '../features/enrichment/data/free_model_catalog.dart';
import '../features/enrichment/data/openrouter_client.dart';
import '../features/enrichment/data/openrouter_enrichment_service.dart';
import '../features/enrichment/data/request_scheduler.dart';
import '../features/enrichment/domain/enrichment.dart';
import '../features/export/data/file_picker_export_sink.dart';
import '../features/export/domain/export_file_sink.dart';
import '../features/reminders/data/local_notification_reminder_scheduler.dart';
import '../features/reminders/domain/reminder.dart';
import '../features/review/data/drift_review_repository.dart';
import '../features/review/data/drift_study_repository.dart';
import '../features/review/domain/review_repository.dart';
import '../features/review/domain/study_repository.dart';
import '../features/scan/data/image_cropper.dart';
import '../features/scan/data/scan_image_source.dart';
import '../features/scan/data/text_recognition_engine.dart';
import '../features/sentence_practice/data/drift_sentence_practice_repository.dart';
import '../features/sentence_practice/domain/sentence_practice.dart';
import '../features/settings/data/settings_store.dart';
import '../features/speech/data/flutter_tts_speech_service.dart';
import '../features/speech/domain/speech_service.dart';
import '../features/tags/data/drift_tag_repository.dart';
import '../features/tags/domain/tag.dart';
import '../features/vocabulary/data/drift_vocabulary_repository.dart';
import '../features/vocabulary/domain/vocabulary_repository.dart';

/// The single app-wide database connection. Tests override this with an
/// in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidIdGenerator(),
);

final deckRepositoryProvider = Provider<DeckRepository>(
  (ref) => DriftDeckRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final vocabularyRepositoryProvider = Provider<VocabularyRepository>(
  (ref) => DriftVocabularyRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => DriftTagRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => DriftReviewRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// Scheduled (FSRS) review state and answers.
final studyRepositoryProvider = Provider<StudyRepository>(
  (ref) => DriftStudyRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// Sentence-practice history (never FSRS state or review history).
final sentencePracticeRepositoryProvider = Provider<SentencePracticeRepository>(
  (ref) => DriftSentencePracticeRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// Card appearance (colours, sizes, highlights, stickers) per word.
final cardAppearanceRepositoryProvider = Provider<CardAppearanceRepository>(
  (ref) => DriftCardAppearanceRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Safety copies made before a restore. Tests override this.
final safetyBackupStoreProvider = Provider<SafetyBackupStore>(
  (ref) => FileSafetyBackupStore(),
);

/// Choosing a backup file to restore. Tests override this.
final backupFileSourceProvider = Provider<BackupFileSource>(
  (ref) => const FilePickerBackupFileSource(),
);

/// Full backup and restore of the learning data.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
    safety: ref.watch(safetyBackupStoreProvider),
  ),
);

/// Local, non-secret settings (e.g. the study reminder).
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(appDatabaseProvider)),
);

/// Order of practice cards. Tests override this with a seeded generator.
final randomProvider = Provider<Random>((ref) => Random());

/// On-device text-to-speech. Tests override this with a fake.
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = FlutterTtsSpeechService();
  ref.onDispose(service.stop);
  return service;
});

/// Local notifications for the study reminder. Tests override this.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationReminderScheduler(),
);

/// The platform save dialog for exports. Tests override this.
final exportFileSinkProvider = Provider<ExportFileSink>(
  (ref) => const FilePickerExportSink(),
);

final csvFileSourceProvider = Provider<CsvFileSource>(
  (ref) => const FilePickerCsvFileSource(),
);

final scanImageSourceProvider = Provider<ScanImageSource>(
  (ref) => ImagePickerScanImageSource(),
);

/// Cuts a region out of a page photo for a second OCR pass. Tests override
/// this.
final imageCropperProvider = Provider<ImageCropper>(
  (ref) => const DartUiImageCropper(),
);

/// How a page photo is loaded for display. Tests override this with an
/// in-memory image.
final scanPageImageProvider = Provider<ImageProvider Function(PickedImage)>(
  (ref) =>
      (image) => FileImage(File(image.path)),
);

/// On-device OCR. Released when no longer used.
final textRecognitionEngineProvider = Provider<TextRecognitionEngine>((ref) {
  final engine = MlKitTextRecognitionEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

/// The user's own OpenRouter key and model choice, in OS secure storage.
/// Tests override this with an in-memory store.
final aiSettingsStoreProvider = Provider<AiSettingsStore>(
  (ref) => SecureAiSettingsStore(),
);

/// HTTP client for AI requests. Tests override this with a mock client.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Non-secret AI state (preferences, free usage, result cache, unfinished
/// jobs) in the local database.
final aiKeyValueStoreProvider = Provider<AiKeyValueStore>(
  (ref) => DatabaseAiKeyValueStore(ref.watch(appDatabaseProvider)),
);

final aiLocalStateProvider = Provider<AiLocalState>(
  (ref) => AiLocalState(
    ref.watch(aiKeyValueStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

final enrichmentCacheProvider = Provider<EnrichmentCache>(
  (ref) => EnrichmentCache(
    ref.watch(aiKeyValueStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Waiting between AI requests. Tests override this to not wait.
final aiSleepProvider = Provider<Future<void> Function(Duration)>(
  (ref) => Future<void>.delayed,
);

/// Paces all OpenRouter requests app-wide (one at a time, spaced out).
final requestSchedulerProvider = Provider<RequestScheduler>(
  (ref) => RequestScheduler(
    clock: ref.watch(clockProvider),
    sleep: ref.watch(aiSleepProvider),
    localState: ref.watch(aiLocalStateProvider),
  ),
);

final openRouterClientProvider = Provider<OpenRouterClient>(
  (ref) => OpenRouterClient(
    ref.watch(httpClientProvider),
    scheduler: ref.watch(requestSchedulerProvider),
    clock: ref.watch(clockProvider),
    random: ref.watch(randomProvider),
    sleep: ref.watch(aiSleepProvider),
  ),
);

/// Verified free models from OpenRouter's public list (cached briefly).
final freeModelCatalogProvider = Provider<FreeModelCatalog>(
  (ref) => FreeModelCatalog(
    ref.watch(openRouterClientProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Provider-neutral enrichment. Currently OpenRouter with the user's key,
/// free models only unless the user turns free-only mode off.
final enrichmentServiceProvider = Provider<VocabularyEnrichmentService>(
  (ref) => OpenRouterEnrichmentService(
    client: ref.watch(openRouterClientProvider),
    settings: ref.watch(aiSettingsStoreProvider),
    clock: ref.watch(clockProvider),
    localState: ref.watch(aiLocalStateProvider),
    cache: ref.watch(enrichmentCacheProvider),
    catalog: ref.watch(freeModelCatalogProvider),
  ),
);

/// Opens a web page in the browser. Tests override this.
final urlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
