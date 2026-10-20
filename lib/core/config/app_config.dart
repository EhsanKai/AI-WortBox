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

  /// Longest tag name, in characters.
  static const int maxTagNameLength = 40;

  /// Most entries shown for one search or filter; the user narrows the
  /// query to see others.
  static const int maxSearchResults = 300;

  /// Most words in one unscheduled practice session.
  static const int practiceSessionSize = 20;

  /// Most cards in one scheduled (FSRS) review session; the rest stay due
  /// for the next session.
  static const int reviewSessionSize = 50;

  /// A card in a (re)learning step is shown when it is due within this time,
  /// so a forgotten word can come back in the same session.
  static const Duration reviewLearnAhead = Duration(minutes: 20);

  // CSV import limits.
  static const int maxCsvBytes = 5 * 1024 * 1024;
  static const int maxCsvRows = 10000;

  /// Largest Anki package accepted for import (media inside counts, even
  /// though media is not imported).
  static const int maxAnkiPackageBytes = 50 * 1024 * 1024;

  // Full backup (docs/decisions.md, D54).
  /// Largest backup file accepted for restore.
  static const int maxBackupBytes = 100 * 1024 * 1024;

  /// Safety copies of the data kept before restores (newest first).
  static const int safetyBackupsKept = 3;

  // Sentence practice (D55).
  /// Target words per session: the choices and the default.
  static const List<int> sentencePracticeSizes = [3, 5, 8];
  static const int sentencePracticeDefaultSize = 5;

  /// A word practised more recently than this is chosen only when fewer
  /// other words are available.
  static const Duration sentencePracticeRecent = Duration(days: 3);

  /// Time limits for generating a session and for checking one answer
  /// (longer than enrichment: several sentences, and free models reason
  /// before answering).
  static const Duration sentenceGenerationTimeout = Duration(seconds: 90);
  static const Duration sentenceCheckTimeout = Duration(seconds: 60);

  /// Longest answer the learner can submit, in characters.
  static const int sentenceAnswerMaxLength = 400;

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

  // Free-only OpenRouter usage (see docs/decisions.md, D41).
  /// OpenRouter's free router: picks one of the currently free models that
  /// supports the request's features. The default model in free-only mode.
  static const String aiFreeRouterModel = 'openrouter/free';

  /// Words sent together in one request, by default and at most.
  static const int aiDefaultWordsPerRequest = 5;
  static const int aiMaxWordsPerRequest = 10;

  /// Most characters of words, sentences and existing meanings in one
  /// request. A batch that would exceed it is split, so a few long
  /// sentences never make one request (and its answer) too large.
  static const int aiMaxBatchInputChars = 4000;

  /// Requests to OpenRouter running at the same time.
  static const int aiMaxConcurrentRequests = 1;

  /// Shortest gap between the start of two requests (the free tier allows
  /// 20 requests per minute; this stays well below it).
  static const Duration aiMinRequestSpacing = Duration(seconds: 4);

  /// First backoff step; doubled per retry, plus up to 50 % random jitter.
  static const Duration aiBackoffBase = Duration(seconds: 1);

  /// How long a fetched and verified list of free models is reused.
  static const Duration aiFreeCatalogTtl = Duration(hours: 1);

  /// Validated AI results are reused for this long, up to this many words.
  static const Duration aiCacheTtl = Duration(days: 90);
  static const int aiMaxCacheEntries = 2000;

  /// File name (without extension) of the local SQLite database.
  static const String databaseName = 'ai_wortbox';
}
