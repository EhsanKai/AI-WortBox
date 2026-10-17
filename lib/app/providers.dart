import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/id/id_generator.dart';
import '../core/time/clock.dart';
import '../data/database/app_database.dart';
import '../features/csv_import/data/csv_file_source.dart';
import '../features/decks/data/drift_deck_repository.dart';
import '../features/decks/domain/deck_repository.dart';
import '../features/enrichment/data/ai_settings_store.dart';
import '../features/enrichment/data/openrouter_client.dart';
import '../features/enrichment/data/openrouter_enrichment_service.dart';
import '../features/enrichment/domain/enrichment.dart';
import '../features/scan/data/scan_image_source.dart';
import '../features/scan/data/text_recognition_engine.dart';
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

final csvFileSourceProvider = Provider<CsvFileSource>(
  (ref) => const FilePickerCsvFileSource(),
);

final scanImageSourceProvider = Provider<ScanImageSource>(
  (ref) => ImagePickerScanImageSource(),
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

final openRouterClientProvider = Provider<OpenRouterClient>(
  (ref) => OpenRouterClient(ref.watch(httpClientProvider)),
);

/// Provider-neutral enrichment. Currently OpenRouter with the user's key.
final enrichmentServiceProvider = Provider<VocabularyEnrichmentService>(
  (ref) => OpenRouterEnrichmentService(
    client: ref.watch(openRouterClientProvider),
    settings: ref.watch(aiSettingsStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Opens a web page in the browser. Tests override this.
final urlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
