// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI WortBox';

  @override
  String get appTagline => 'From Book Pages to Lasting Memory.';

  @override
  String get navToday => 'Today';

  @override
  String get navMyWords => 'My Words';

  @override
  String get navAdd => 'Add Vocabulary';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardDecks => 'Decks';

  @override
  String get dashboardWords => 'Words';

  @override
  String get dashboardReviewPending =>
      'Daily FSRS review will be enabled in a later version.';

  @override
  String get dashboardYourDecks => 'Your decks';

  @override
  String get emptyDecksTitle => 'You have no decks yet';

  @override
  String get emptyDecksBody =>
      'Create a vocabulary deck to get started. Each deck has its own languages and daily limit.';

  @override
  String get actionCreateDeck => 'Create deck';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String deckWordCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString words',
      one: '1 word',
      zero: 'No words',
    );
    return '$_temp0';
  }

  @override
  String deckLanguagePair(String source, String definition) {
    return '$source → $definition';
  }

  @override
  String deckDailyLimit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $countString new cards per day',
      one: 'Up to 1 new card per day',
      zero: 'No new cards',
    );
    return '$_temp0';
  }

  @override
  String deckCreatedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Created on $dateString';
  }

  @override
  String get deckNotFound => 'This deck could not be found.';

  @override
  String get deckEmptyBody =>
      'This deck has no words yet. Adding words arrives in the next phase.';

  @override
  String get createDeckTitle => 'New deck';

  @override
  String get createDeckNameLabel => 'Deck name';

  @override
  String get createDeckNameHint => 'e.g. Der Vorleser or A1 words';

  @override
  String get createDeckLanguagesLabel => 'Learning and definition language';

  @override
  String get createDeckDailyLimitLabel => 'New cards per day';

  @override
  String createDeckDailyLimitHelper(int min, int max) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'From $minString to $maxString; 0 pauses new cards.';
  }

  @override
  String get createDeckSubmit => 'Create';

  @override
  String deckCreatedMessage(String name) {
    return 'Deck “$name” created.';
  }

  @override
  String get errorDeckNameEmpty => 'Enter a deck name.';

  @override
  String errorDeckNameTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Deck names can be at most $maxString characters.';
  }

  @override
  String get errorDeckNameDuplicate => 'A deck with this name already exists.';

  @override
  String errorDailyLimitRange(int min, int max) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter a number from $minString to $maxString.';
  }

  @override
  String get errorInvalidNumber => 'Enter a whole number.';

  @override
  String get errorUnsupportedLanguage => 'This language is not supported yet.';

  @override
  String get errorIdenticalLanguages =>
      'Learning and definition languages must differ.';

  @override
  String get errorStorage => 'Saving on this device failed. Please try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get addSubtitle => 'Where are your words coming from?';

  @override
  String get addImportCsv => 'Import CSV';

  @override
  String get addImportCsvDescription =>
      'Import your word list from a CSV file.';

  @override
  String get addManual => 'Add manually';

  @override
  String get addManualDescription =>
      'Type a German word or expression and its meaning.';

  @override
  String get addScan => 'Scan a book page';

  @override
  String get addScanDescription =>
      'Photograph a book page and pick the words you want.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get statisticsEmpty =>
      'Learning statistics appear once you start reviewing.';

  @override
  String get settingsLanguages => 'Default languages';

  @override
  String get settingsSourceLanguage => 'Learning language';

  @override
  String get settingsDefinitionLanguage => 'Definition language';

  @override
  String get settingsPrivacy => 'Privacy & storage';

  @override
  String get settingsPrivacyBody =>
      'All data stays on this device. No account is required.';

  @override
  String get settingsAbout => 'About';
}
