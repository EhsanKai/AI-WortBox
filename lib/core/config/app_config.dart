import '../language/language.dart';

/// Centralized product identity and default configuration.
///
/// Change product-level defaults here only; feature code must not hard-code
/// the product name or language pair.
abstract final class AppConfig {
  static const String productName = 'AI WortBox';
  static const String tagline = 'From Book Pages to Lasting Memory.';

  /// Language being learned (vocabulary is written in this language).
  static const Language defaultSourceLanguage = Language.german;

  /// Language used for meanings and translations.
  static const Language defaultDefinitionLanguage = Language.persian;

  /// Default number of new cards introduced per day for a new deck.
  static const int defaultDailyNewCardLimit = 20;

  /// Inclusive bounds for a deck's daily new-card limit. `0` pauses new cards.
  static const int minDailyNewCardLimit = 0;
  static const int maxDailyNewCardLimit = 1000;

  static const int maxDeckNameLength = 80;

  // Vocabulary entry limits (characters).
  static const int maxOriginalLength = 200;
  static const int maxMeaningLength = 300;
  static const int maxMeaningsPerEntry = 20;
  static const int maxTextFieldLength = 2000;

  // CSV import limits.
  static const int maxCsvBytes = 5 * 1024 * 1024;
  static const int maxCsvRows = 10000;

  // Page scanning limits.
  /// Largest image file accepted for OCR (after the picker's downscaling).
  static const int maxScanImageBytes = 20 * 1024 * 1024;

  /// Images are downscaled by the picker to at most this many pixels per side.
  static const double maxScanImageDimension = 3000;

  /// Longest multi-word expression that can be selected, in words.
  static const int maxExpressionWords = 10;

  /// Longest sentence context stored with an entry, in characters.
  static const int maxContextLength = 400;

  // AI enrichment (OpenRouter, bring your own key).
  /// Base URL of the OpenRouter API. Requests go only here, authenticated
  /// with the user's own key.
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// Where users create their own OpenRouter API key.
  static const String openRouterKeysUrl = 'https://openrouter.ai/keys';

  /// Time limit for one enrichment request (including model generation).
  static const Duration aiRequestTimeout = Duration(seconds: 45);

  /// Time limit for the key check and the model-list check.
  static const Duration aiCheckTimeout = Duration(seconds: 15);

  /// Automatic retries after the first attempt, only for requests OpenRouter
  /// rejected before any model ran (429, 503, 402 with `Retry-After`).
  /// Timeouts and other ambiguous failures are retried only by the user.
  static const int aiMaxRetries = 2;

  /// Longest wait honoured from a `Retry-After` header.
  static const Duration aiMaxRetryDelay = Duration(seconds: 20);

  /// Most meanings accepted from one AI response.
  static const int aiMaxMeanings = 5;

  /// Most entries enriched in one batch run.
  static const int aiMaxBatchSize = 50;

  /// File name (without extension) of the local SQLite database.
  static const String databaseName = 'ai_wortbox';
}
