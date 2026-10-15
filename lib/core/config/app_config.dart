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

  /// File name (without extension) of the local SQLite database.
  static const String databaseName = 'ai_wortbox';
}
