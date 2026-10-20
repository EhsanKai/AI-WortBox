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

  @override
  String get deckAddWord => 'Add word';

  @override
  String get deckImportCsv => 'Import CSV';

  @override
  String get deckNoEntriesTitle => 'This deck has no words yet';

  @override
  String get deckNoEntriesBody =>
      'Add words manually or import them from a CSV file.';

  @override
  String get searchHint => 'Search words and meanings';

  @override
  String get searchNoResults => 'No words match your search.';

  @override
  String get entryNoMeaning => 'No meaning yet';

  @override
  String get entryMeanings => 'Meanings';

  @override
  String get entryExample => 'Example';

  @override
  String get entryGrammar => 'Grammar';

  @override
  String get entryLemma => 'Base form';

  @override
  String get entryPartOfSpeech => 'Part of speech';

  @override
  String get entryNotes => 'Notes';

  @override
  String get entrySource => 'Source';

  @override
  String get sourceManual => 'Manual entry';

  @override
  String get sourceCsv => 'File import (CSV or Anki)';

  @override
  String get sourceImage => 'Book scan';

  @override
  String get entryStatus => 'Meaning status';

  @override
  String get entryStatusMissing => 'Waiting for a meaning';

  @override
  String get entryStatusPending => 'Being completed';

  @override
  String get entryStatusReady => 'Ready';

  @override
  String get entryStatusFailed => 'Completion failed';

  @override
  String entryUpdatedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Last changed: $dateString';
  }

  @override
  String get entryNotFound => 'This word could not be found.';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaveAndAddAnother => 'Save & add next';

  @override
  String deleteEntryTitle(String word) {
    return 'Delete “$word”?';
  }

  @override
  String get deleteEntryBody =>
      'The word, its meanings and its review history will be deleted permanently.';

  @override
  String get entryDeletedMessage => 'Word deleted.';

  @override
  String get formNewEntryTitle => 'New word';

  @override
  String get formEditEntryTitle => 'Edit word';

  @override
  String get formDeckLabel => 'Deck';

  @override
  String get formWordLabel => 'German word or expression';

  @override
  String get formWordHint => 'e.g. sich Mühe geben';

  @override
  String formMeaningLabel(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return 'Meaning $indexString';
  }

  @override
  String get formAddMeaning => 'Add another meaning';

  @override
  String get formRemoveMeaning => 'Remove this meaning';

  @override
  String get formMeaningsHelper =>
      'Leave empty if you don\'t know it yet; it can be completed later.';

  @override
  String get formMoreDetails => 'More details';

  @override
  String get formExampleLabel => 'German example sentence';

  @override
  String get formExampleTranslationLabel =>
      'Persian translation of the example';

  @override
  String get formGrammarLabel => 'Grammar';

  @override
  String get formGrammarHint => 'e.g. der Tisch, -e';

  @override
  String get formLemmaLabel => 'Base form';

  @override
  String get formPartOfSpeechLabel => 'Part of speech';

  @override
  String get formPartOfSpeechHint => 'e.g. Nomen or Verb';

  @override
  String get formNotesLabel => 'Notes';

  @override
  String get formNoDecks => 'Create a deck before adding words.';

  @override
  String entrySavedMessage(String word) {
    return '“$word” saved.';
  }

  @override
  String entryMergedMessage(String word) {
    return 'New meanings added to “$word”.';
  }

  @override
  String get errorWordEmpty => 'Enter the German word.';

  @override
  String errorTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'At most $maxString characters are allowed.';
  }

  @override
  String errorTooManyMeanings(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'At most $maxString meanings are allowed.';
  }

  @override
  String get errorDeckNotFound => 'The selected deck no longer exists.';

  @override
  String get errorEntryNotFound => 'This word no longer exists.';

  @override
  String get duplicateRedundantTitle => 'This word is already saved';

  @override
  String duplicateRedundantBody(String word) {
    return '“$word” already exists in this deck with the same meaning.';
  }

  @override
  String get duplicateDifferentTitle => 'This word exists with another meaning';

  @override
  String duplicateDifferentBody(String word) {
    return '“$word” is already in this deck with these meanings:';
  }

  @override
  String get duplicateOpenExisting => 'Open existing word';

  @override
  String get duplicateAddMeanings => 'Add meanings to the existing word';

  @override
  String get duplicateSaveSeparate => 'Save as a separate word';

  @override
  String get duplicateSaveAnyway => 'Save anyway';

  @override
  String get csvIntro =>
      'Choose a file with columns such as word and meaning. You review everything before anything is saved.';

  @override
  String get csvSectionDeck => 'Target deck';

  @override
  String get csvSectionFile => 'File';

  @override
  String get csvSectionColumns => 'Columns';

  @override
  String get csvSectionLanguages => 'Languages';

  @override
  String get csvSectionDuplicates => 'Duplicates';

  @override
  String get csvSectionPreview => 'Preview';

  @override
  String get csvChooseFile => 'Choose CSV file';

  @override
  String get csvChooseAnother => 'Choose another file';

  @override
  String csvRecordCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String csvEncoding(String name) {
    return 'Encoding: $name';
  }

  @override
  String get csvDelimiterLabel => 'Delimiter';

  @override
  String get csvDelimiterAuto => 'Detect automatically';

  @override
  String get csvDelimiterComma => 'Comma ( , )';

  @override
  String get csvDelimiterSemicolon => 'Semicolon ( ; )';

  @override
  String get csvDelimiterTab => 'Tab';

  @override
  String get csvDelimiterPipe => 'Vertical bar ( | )';

  @override
  String get csvHasHeader => 'First row contains column names';

  @override
  String csvColumnLabel(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return 'Column $indexString';
  }

  @override
  String get csvFieldIgnore => 'Ignore';

  @override
  String get csvFieldOriginal => 'German word';

  @override
  String get csvFieldMeaning => 'Persian meaning';

  @override
  String get csvFieldLemma => 'Base form';

  @override
  String get csvFieldPartOfSpeech => 'Part of speech';

  @override
  String get csvFieldExample => 'Example sentence';

  @override
  String get csvFieldExampleTranslation => 'Example translation';

  @override
  String get csvFieldGrammar => 'Grammar';

  @override
  String get csvFieldNotes => 'Notes';

  @override
  String get csvMappingNeedsWord => 'Assign one column to “German word”.';

  @override
  String get csvMeaningSplitHint =>
      'Several meanings in one cell can be separated with ; or |.';

  @override
  String csvLanguagesConfirm(String source, String definition) {
    return 'I confirm the words are in $source and the meanings in $definition.';
  }

  @override
  String get csvLanguagesSwapped =>
      'The word column looks Persian and the meaning column German.';

  @override
  String get csvSwapColumns => 'Swap columns';

  @override
  String get csvStrategySkip => 'Skip existing words';

  @override
  String get csvStrategySkipDescription =>
      'Rows whose word is already in the deck or earlier in the file are not imported.';

  @override
  String get csvStrategyMerge => 'Add new meanings to the existing word';

  @override
  String get csvStrategyMergeDescription =>
      'Only new meanings and empty fields are added; nothing is overwritten.';

  @override
  String get csvStrategySeparate => 'Separate word for a different meaning';

  @override
  String get csvStrategySeparateDescription =>
      'A separate word is created when the meaning differs.';

  @override
  String get csvStrategyNote =>
      'Rows that add no new meaning are always skipped.';

  @override
  String csvCountNew(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString new';
  }

  @override
  String csvCountMerge(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString merged';
  }

  @override
  String csvCountSkip(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString duplicates';
  }

  @override
  String csvCountError(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString errors';
  }

  @override
  String csvRowLine(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'Line $lineString';
  }

  @override
  String get csvRowNew => 'New';

  @override
  String get csvRowMerge => 'Adds meanings to an existing word';

  @override
  String csvRowMergeInFile(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'Adds meanings to line $lineString';
  }

  @override
  String get csvRowRedundant => 'Duplicate — skipped';

  @override
  String csvRowRedundantInFile(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'Repeats line $lineString — skipped';
  }

  @override
  String get csvRowExists => 'Word exists — skipped';

  @override
  String csvRowExistsInFile(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'Word already on line $lineString — skipped';
  }

  @override
  String get csvRowIssueMissingWord => 'German word is empty';

  @override
  String get csvRowIssueWordTooLong => 'Word is too long';

  @override
  String get csvRowIssueMeaningTooLong => 'A meaning is too long';

  @override
  String get csvRowIssueTooManyMeanings => 'Too many meanings';

  @override
  String get csvRowIssueFieldTooLong => 'A cell is too long';

  @override
  String csvErrorsTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString rows have errors and will not be imported',
      one: '1 row has errors and will not be imported',
    );
    return '$_temp0';
  }

  @override
  String csvMoreRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'and $countString more rows';
  }

  @override
  String csvImportButton(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $countString rows',
      one: 'Import 1 row',
    );
    return '$_temp0';
  }

  @override
  String get csvNothingToImport => 'There is nothing to import.';

  @override
  String get csvImportDone => 'Import complete';

  @override
  String csvResultCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString new words created';
  }

  @override
  String csvResultMerged(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString rows added to existing words';
  }

  @override
  String csvResultSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString duplicate rows skipped';
  }

  @override
  String csvResultErrors(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString rows not imported because of errors';
  }

  @override
  String get csvViewDeck => 'View deck';

  @override
  String get csvImportAnother => 'Import another file';

  @override
  String get csvImportFailed =>
      'The import failed and nothing was saved. Please try again.';

  @override
  String get csvFormatEmpty => 'The file is empty.';

  @override
  String csvFormatTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'The file is larger than $maxString MB.';
  }

  @override
  String csvFormatTooManyRows(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'The file has more than $maxString rows.';
  }

  @override
  String get csvFormatEncoding =>
      'The file encoding is not supported. Save the file as UTF-8.';

  @override
  String csvFormatUnterminatedQuote(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'A quotation mark on line $lineString is never closed.';
  }

  @override
  String get csvFormatNoDataRows => 'The file has no data rows.';

  @override
  String get csvFileReadFailed =>
      'The file could not be read. Please try again.';

  @override
  String get scanTitle => 'Scan a book page';

  @override
  String get scanIntro =>
      'Take or choose a photo of a German page. The text is read on this device and the photo is not sent anywhere.';

  @override
  String get scanOcrWarning =>
      'Text recognition can make mistakes; check and correct the words before saving.';

  @override
  String get scanTakePhoto => 'Take photo';

  @override
  String get scanChoosePhoto => 'Choose from gallery';

  @override
  String get scanTypeText => 'Type or paste text';

  @override
  String get scanRecognizing => 'Reading the text…';

  @override
  String get scanErrorCameraPermission =>
      'Camera access is not allowed. Allow it in the device settings or choose a photo from the gallery.';

  @override
  String get scanErrorPhotoPermission =>
      'Photo access is not allowed. Allow it in the device settings or use the camera.';

  @override
  String get scanErrorCameraUnavailable => 'No camera is available.';

  @override
  String get scanErrorUnsupportedFormat =>
      'This image format is not supported. Use JPG, PNG, HEIC or WebP.';

  @override
  String get scanErrorTooLarge => 'The image is too large.';

  @override
  String get scanErrorUnreadable => 'The image could not be read.';

  @override
  String get scanErrorOcrUnavailable =>
      'Text recognition is not available on this device. You can type the text instead.';

  @override
  String get scanErrorOcrFailed =>
      'Reading the text failed. Try again or type the text.';

  @override
  String get scanNoTextTitle => 'No text found';

  @override
  String get scanNoTextBody => 'Take a clearer photo or type the text.';

  @override
  String get scanTryAgain => 'Another photo';

  @override
  String get scanTypedHint => 'Type or paste the German text here';

  @override
  String get scanUseText => 'Use this text';

  @override
  String get scanSelectHint =>
      'Tap words to select them. For a multi-word expression, switch to “Expression” and tap the first and last word.';

  @override
  String get scanModeWord => 'Word';

  @override
  String get scanModeExpression => 'Expression';

  @override
  String get scanExpressionPickEnd =>
      'Now tap the last word of the expression.';

  @override
  String scanExpressionTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'An expression must be within one paragraph and at most $maxString words.';
  }

  @override
  String scanSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items selected',
      one: '1 item selected',
      zero: 'Nothing selected',
    );
    return '$_temp0';
  }

  @override
  String get scanClearSelection => 'Clear selection';

  @override
  String get scanEditText => 'Correct text';

  @override
  String get scanEditTextTitle => 'Correct the recognized text';

  @override
  String scanSelectionsDropped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selections were removed because their text changed.',
      one: '1 selection was removed because its text changed.',
    );
    return '$_temp0';
  }

  @override
  String scanReviewButton(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review $countString items',
      one: 'Review 1 item',
    );
    return '$_temp0';
  }

  @override
  String get scanReviewTitle => 'Review before saving';

  @override
  String get scanReviewIntro =>
      'Only the items in this list will be saved. Correct any recognition mistakes.';

  @override
  String get scanItemWord => 'German word or expression';

  @override
  String get scanItemContext => 'Original sentence';

  @override
  String get scanItemLemma => 'Base form (optional)';

  @override
  String get scanItemMeaning => 'Persian meaning (optional)';

  @override
  String get scanItemRemove => 'Remove from list';

  @override
  String scanLemmaHint(String base) {
    return 'Suggested base form: $base';
  }

  @override
  String get scanLemmaHintNote =>
      'From a built-in list of irregular verbs; please check.';

  @override
  String get scanUseHint => 'Use';

  @override
  String get scanStatusNew => 'New';

  @override
  String get scanStatusRedundant => 'Already in this deck — not saved';

  @override
  String get scanStatusRedundantInList => 'Duplicate in this list — not saved';

  @override
  String get scanStatusExists => 'Word exists with another meaning — not saved';

  @override
  String get scanStatusMerge => 'Meaning is added to the existing word';

  @override
  String get scanStatusInvalid => 'The word is empty';

  @override
  String scanSaveButton(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $countString items',
      one: 'Save 1 item',
      zero: 'Nothing to save',
    );
    return '$_temp0';
  }

  @override
  String get scanSavedTitle => 'Saved';

  @override
  String get scanScanAnother => 'Scan another page';

  @override
  String get scanBackToText => 'Back to text';

  @override
  String get scanSaveFailed =>
      'Saving failed and nothing was changed. Please try again.';

  @override
  String scanResultCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString new words saved';
  }

  @override
  String scanResultMerged(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Meanings of $countString items added to existing words';
  }

  @override
  String scanResultSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString duplicates not saved';
  }

  @override
  String get settingsLicenses => 'Software and font licenses';

  @override
  String get scanWordTapToSelect => 'select word';

  @override
  String get scanWordTapToDeselect => 'deselect word';

  @override
  String get settingsAi => 'AI';

  @override
  String get settingsAiConfigured => 'On — your OpenRouter key is saved';

  @override
  String get settingsAiNotConfigured => 'Off — no OpenRouter key set';

  @override
  String get aiSettingsTitle => 'AI';

  @override
  String get aiIntroTitle => 'With your own OpenRouter account';

  @override
  String get aiIntroBody =>
      'To suggest meanings, examples and grammar notes, AI WortBox uses your own OpenRouter account. By default only free models are used, so nothing is charged; free models have daily limits. AI WortBox has no shared key or account and sends nothing without your key.';

  @override
  String get aiGetKey => 'Get a key at openrouter.ai/keys';

  @override
  String get aiKeyLabel => 'API key';

  @override
  String get aiKeyNewLabel => 'New API key';

  @override
  String get aiKeyShow => 'Show key';

  @override
  String get aiKeyHide => 'Hide key';

  @override
  String get aiKeySave => 'Save and test';

  @override
  String aiKeySaved(String suffix) {
    return 'Saved key: ••••$suffix';
  }

  @override
  String get aiKeySavedNote => 'The full key is never shown again.';

  @override
  String get aiKeyTest => 'Test key';

  @override
  String get aiKeyReplace => 'Replace key';

  @override
  String get aiKeyRemove => 'Remove key';

  @override
  String get aiKeyRemoveTitle => 'Remove the key?';

  @override
  String get aiKeyRemoveBody =>
      'The key is deleted from this device’s secure storage. Saved words and meanings are not affected. The key stays active in your OpenRouter account; revoke it at openrouter.ai.';

  @override
  String get aiKeyRemoved => 'Key removed.';

  @override
  String get aiKeySaveFailed =>
      'The key could not be saved in this device\'s secure storage. Please try again.';

  @override
  String get aiKeyRemoveFailed =>
      'The key could not be removed from this device\'s secure storage. Please try again.';

  @override
  String get aiModelSaveFailed =>
      'The model choice could not be saved. Please try again.';

  @override
  String get aiKeyProblemEmpty => 'Enter the key.';

  @override
  String get aiKeyProblemWhitespace =>
      'The key must not contain spaces or line breaks.';

  @override
  String get aiKeyProblemShort => 'This key is too short.';

  @override
  String get aiKeyProblemLong => 'This key is too long.';

  @override
  String get aiCheckRunning => 'Testing the key…';

  @override
  String get aiCheckPassed => 'The key works; AI is ready.';

  @override
  String aiCheckUsage(String amount) {
    return 'Credits used with this key (reported by OpenRouter): \$$amount';
  }

  @override
  String aiCheckRemaining(String amount) {
    return 'Remaining limit of this key: \$$amount';
  }

  @override
  String get aiCheckModelUnavailable =>
      'The selected model is not currently available on OpenRouter with structured output. Choose another model.';

  @override
  String get aiCheckModelUnknown =>
      'The model list could not be loaded; the model was not checked.';

  @override
  String get aiModelLabel => 'Model';

  @override
  String get aiModelHelper =>
      'A curated list of low-cost models with structured output, used only when free-only mode is off. Prices are listed on openrouter.ai.';

  @override
  String get aiPrivacyTitle => 'Privacy and connection';

  @override
  String get aiPrivacyBody =>
      'Only when you ask, the word, its sentence and its current meanings are sent to OpenRouter and the model provider. This text leaves the device and is subject to their policies. AI suggestions need the internet; the rest of the app works offline.';

  @override
  String get aiSecurityTitle => 'How the key is kept';

  @override
  String get aiSecurityBody =>
      'The key is kept in the system’s secure storage (Keychain on iOS, Keystore on Android). It is never shown, and never stored in the database, logs or backups. This reduces exposure, but a compromised or instrumented device can still extract it. Set a credit limit for this key on OpenRouter.';

  @override
  String get aiFreeTitle => 'Free usage';

  @override
  String get aiFreeOnly => 'Free models only';

  @override
  String get aiFreeOnlyOn =>
      'No request can cost money: only models verified as free are used, and OpenRouter is told to refuse anything priced.';

  @override
  String get aiFreeOnlyOff =>
      'Off: the model below is used and billed to your OpenRouter credits.';

  @override
  String get aiPaidConfirmTitle => 'Use paid models?';

  @override
  String get aiPaidConfirmBody =>
      'Each request will then be charged to your OpenRouter credits. Free models are often enough for vocabulary.';

  @override
  String get aiPaidConfirm => 'Use paid models';

  @override
  String get aiRoutingAuto => 'Auto Free';

  @override
  String get aiRoutingQuality => 'Quality Free';

  @override
  String get aiRoutingAutoHelp =>
      'OpenRouter\'s free router picks an available free model.';

  @override
  String get aiRoutingQualityHelp =>
      'The best-rated free models are tried first, then the free router. The free list is checked on OpenRouter before use.';

  @override
  String get aiQualityUnverified =>
      'The free model list has not been verified yet, so the free router is used. Refresh to check it.';

  @override
  String aiFreeModelsVerified(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString free models verified',
      one: '1 free model verified',
    );
    return '$_temp0';
  }

  @override
  String aiCurrentModel(String model) {
    return 'Current model: $model';
  }

  @override
  String aiLastModel(String model) {
    return 'Last answer from: $model';
  }

  @override
  String get aiLastModelNone => 'No request sent yet.';

  @override
  String get aiBatchSize => 'Words per request';

  @override
  String get aiBatchSizeHelp =>
      'Fewer requests use less of the free daily quota; smaller batches are more reliable.';

  @override
  String aiQuotaRemaining(int remaining, int limit) {
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'About $remainingString of $limitString free requests left today';
  }

  @override
  String aiQuotaRemainingNoLimit(int remaining) {
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return 'About $remainingString free requests left today';
  }

  @override
  String get aiQuotaUnknown =>
      'Free requests left today: not checked yet. Test the key or refresh.';

  @override
  String aiQuotaSentToday(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Sent by this app today: $countString';
  }

  @override
  String get aiRateReady => 'Ready';

  @override
  String aiRateCooling(String time) {
    return 'Rate limited — waiting until $time';
  }

  @override
  String aiRatePaused(String time) {
    return 'Daily free quota used up — paused until $time';
  }

  @override
  String aiRatePacing(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'One request at a time, at least $secondsString seconds apart.';
  }

  @override
  String aiCacheStats(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString saved AI results',
      one: '1 saved AI result',
    );
    return '$_temp0';
  }

  @override
  String aiCacheUsage(int hits, int misses) {
    final intl.NumberFormat hitsNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String hitsString = hitsNumberFormat.format(hits);
    final intl.NumberFormat missesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String missesString = missesNumberFormat.format(misses);

    return 'Reused $hitsString times · requested $missesString times';
  }

  @override
  String get aiCacheClear => 'Clear saved results';

  @override
  String get aiCacheCleared => 'Saved results cleared.';

  @override
  String get aiRefreshUsage => 'Refresh status';

  @override
  String get aiUsageRefreshFailed =>
      'The status could not be loaded from OpenRouter.';

  @override
  String get aiPrefsSaveFailed =>
      'The setting could not be saved. Please try again.';

  @override
  String get enrichTitle => 'AI suggestions';

  @override
  String get enrichAction => 'AI suggestions';

  @override
  String get enrichDeckAction => 'Suggest for words without meanings';

  @override
  String get enrichNotConfiguredTitle => 'AI is not set up';

  @override
  String get enrichNotConfiguredBody =>
      'Enter your own OpenRouter API key in settings. Without a key, nothing is sent.';

  @override
  String get enrichOpenSettings => 'AI settings';

  @override
  String get enrichEmptyTitle => 'Nothing to complete';

  @override
  String get enrichEmptyBody =>
      'Only words without meanings are completed in a batch. For a word that has meanings, ask from its own page.';

  @override
  String enrichReadyBatch(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString words without meanings will be sent to OpenRouter.',
      one: '1 word without meanings will be sent to OpenRouter.',
    );
    return '$_temp0 You review every suggestion before anything is saved.';
  }

  @override
  String get enrichReadySingle =>
      'This word and its sentence will be sent to OpenRouter. Existing meanings and details do not change without your approval.';

  @override
  String enrichModel(String model) {
    return 'Model: $model';
  }

  @override
  String get enrichStart => 'Get suggestions';

  @override
  String enrichProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString of $totalString';
  }

  @override
  String get enrichCancel => 'Stop';

  @override
  String get enrichStatusQueued => 'Queued';

  @override
  String get enrichStatusRunning => 'Requesting…';

  @override
  String get enrichStatusProposed => 'AI suggestion — please review';

  @override
  String get enrichStatusFailed => 'Failed';

  @override
  String get enrichStatusSkipped => 'No new suggestions';

  @override
  String get enrichNewMeanings => 'Suggested meanings';

  @override
  String get enrichExistingKept =>
      'Existing meanings are kept; selected ones are added.';

  @override
  String get enrichDetails => 'Suggested details';

  @override
  String enrichReplaces(String current) {
    return 'Replaces: $current';
  }

  @override
  String get enrichAmbiguous =>
      'The sense is unclear without more context; review carefully.';

  @override
  String enrichSave(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $countString words',
      one: 'Save 1 word',
    );
    return '$_temp0';
  }

  @override
  String get enrichNothingSelected => 'Nothing is selected to save.';

  @override
  String get enrichRetry => 'Retry failed items';

  @override
  String get enrichSavedTitle => 'Suggestions saved';

  @override
  String enrichSavedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString words updated',
      one: '1 word updated',
    );
    return '$_temp0';
  }

  @override
  String enrichCost(String amount) {
    return 'Cost reported by OpenRouter: \$$amount';
  }

  @override
  String get enrichNoCost => 'Free models — no cost';

  @override
  String get enrichFreeOnly => 'Free models only — no cost.';

  @override
  String enrichResume(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'An unfinished run was found: $countString words left. Completed words are kept.',
      one:
          'An unfinished run was found: 1 word left. Completed words are kept.',
    );
    return '$_temp0';
  }

  @override
  String get enrichFromCache => 'Saved result — nothing was sent';

  @override
  String get enrichConflict =>
      'Some words changed in the meantime, so nothing was saved. Get suggestions again.';

  @override
  String get aiErrorNotConfigured => 'No OpenRouter key is set.';

  @override
  String get aiErrorInvalidKey =>
      'OpenRouter rejected this key. Check or replace it.';

  @override
  String get aiErrorCredits =>
      'Your OpenRouter credits or this key’s limit are used up. Add credits at openrouter.ai.';

  @override
  String get aiErrorForbidden =>
      'OpenRouter or the model provider refused this request.';

  @override
  String get aiErrorRateLimited => 'Too many requests. Try again in a moment.';

  @override
  String get aiErrorTimeout =>
      'No answer arrived in time. OpenRouter may still have processed (and charged) the request; retry only if needed.';

  @override
  String get aiErrorNetwork =>
      'No internet connection. AI suggestions need the internet.';

  @override
  String get aiErrorModel =>
      'The selected model is unavailable. Choose another model in settings.';

  @override
  String get aiErrorBadRequest =>
      'OpenRouter did not accept the request. Try another model.';

  @override
  String get aiErrorServer => 'OpenRouter reported an error. Try again later.';

  @override
  String get aiErrorMalformed =>
      'The model’s answer was not usable. Try again or choose another model.';

  @override
  String get aiErrorCancelled => 'Stopped.';

  @override
  String get aiErrorDailyQuota =>
      'Today\'s free requests on your OpenRouter account are used up. AI pauses until the daily reset (00:00 UTC); nothing is sent until then.';

  @override
  String get aiErrorPaidBlocked =>
      'Stopped to keep AI free: OpenRouter answered with a model or cost that could not be verified as free. Nothing more was sent.';

  @override
  String get actionBack => 'Back';

  @override
  String get csvFieldTags => 'Tags';

  @override
  String get deckImportFile => 'Import a file (CSV or Anki)';

  @override
  String get deckMoreActions => 'More actions';

  @override
  String get searchAllTitle => 'Search all words';

  @override
  String get searchClear => 'Clear search text';

  @override
  String searchLimited(int count) {
    return 'Only the first $count results are shown; narrow your search.';
  }

  @override
  String get filterDifficult => 'Difficult words';

  @override
  String get filterTag => 'Tag';

  @override
  String get filterAllTags => 'All tags';

  @override
  String get filterClear => 'Clear filters';

  @override
  String entryInDeck(String deck) {
    return 'In deck $deck';
  }

  @override
  String get entryDifficult => 'Difficult';

  @override
  String get entryMarkDifficult => 'Mark as difficult';

  @override
  String get entryUnmarkDifficult => 'Unmark as difficult';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get tagsSettingsDescription => 'Create, rename and delete tags';

  @override
  String get tagsEmptyTitle => 'No tags yet';

  @override
  String get tagsEmptyHint => 'Group words with tags such as “B1” or “travel”.';

  @override
  String get tagsAdd => 'Add tags';

  @override
  String get tagsEdit => 'Edit tags';

  @override
  String get tagsEditTitle => 'Tags of this word';

  @override
  String get tagNewLabel => 'New tag';

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get tagCreate => 'New tag';

  @override
  String get tagRename => 'Rename tag';

  @override
  String tagWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteTitle(String name) {
    return 'Delete the tag “$name”?';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The tag is removed from $count words. The words themselves are kept.',
      one: 'The tag is removed from 1 word. The word itself is kept.',
      zero: 'No word has this tag.',
    );
    return '$_temp0';
  }

  @override
  String get tagErrorEmpty => 'Enter a tag name.';

  @override
  String tagErrorTooLong(int max) {
    return 'A tag name can have at most $max characters.';
  }

  @override
  String get tagErrorDuplicate => 'A tag with this name already exists.';

  @override
  String get exportCsv => 'Export as CSV';

  @override
  String get exportAnki => 'Export for Anki (.apkg)';

  @override
  String get exportSaved => 'File saved.';

  @override
  String get exportCancelled => 'Saving was cancelled.';

  @override
  String get exportEmpty => 'This deck has no words to export.';

  @override
  String get exportWriteFailed =>
      'The file could not be saved. Try another location.';

  @override
  String get ankiImportTitle => 'Import from Anki';

  @override
  String get ankiImportDescription =>
      'Choose an .apkg package exported from Anki';

  @override
  String get ankiImportIntro =>
      'In Anki, export a deck as “Anki Deck Package (.apkg)” and choose it here. Then map the note fields to word and meaning.';

  @override
  String get ankiImportNote =>
      'Only note text and tags are imported; images, audio and Anki review history are not.';

  @override
  String ankiNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anki notes',
      one: '1 Anki note',
    );
    return '$_temp0';
  }

  @override
  String get ankiErrorNotPackage =>
      'This is not an Anki package (.apkg), or it is damaged.';

  @override
  String get ankiErrorUnsupported =>
      'This Anki package format is not supported.';

  @override
  String get ankiErrorNoNotes => 'This Anki package contains no notes.';

  @override
  String ankiErrorTooLarge(int size) {
    return 'The Anki package is larger than $size MB.';
  }

  @override
  String get speakWord => 'Pronounce the word';

  @override
  String get speakExample => 'Read the example aloud';

  @override
  String get speechVoiceUnavailable =>
      'No German voice is installed on this device. Install one in the device\'s text-to-speech settings.';

  @override
  String get speechFailed => 'The pronunciation could not be played.';

  @override
  String get settingsStudy => 'Study';

  @override
  String get reminderTitle => 'Study reminder';

  @override
  String get reminderIntro =>
      'A notification is shown on this device every day at the time you choose. No server is involved.';

  @override
  String get reminderEnabled => 'Daily reminder';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get reminderOff => 'Off';

  @override
  String reminderOnAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get reminderNote =>
      'Turning the reminder on asks for permission to show notifications. On Android it may arrive a few minutes late, and some phones stop it to save battery.';

  @override
  String get reminderPermissionDenied =>
      'Notifications are not allowed. Enable them for AI WortBox in the device settings.';

  @override
  String get reminderSchedulingFailed =>
      'The reminder could not be set. Please try again.';

  @override
  String get reminderNotificationTitle => 'Time to practise your words';

  @override
  String get reminderNotificationBody =>
      'Spend a few minutes with your German words.';

  @override
  String get practiceTitle => 'Review';

  @override
  String get practiceTileDescription =>
      'Choose the direction, deck or free practice';

  @override
  String practiceTileStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in a row',
      one: '1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get practiceIntro =>
      'Each card shows one side only. Recall the answer, reveal it and say whether you remembered it.';

  @override
  String get practiceNotSrs =>
      'This is free practice and does not change review scheduling (FSRS). Only your answers are recorded for statistics.';

  @override
  String get practiceWordsFrom => 'Words from';

  @override
  String get practiceAllDecks => 'All decks';

  @override
  String get practiceDifficultOnly => 'Difficult words only';

  @override
  String get practiceStart => 'Start practice';

  @override
  String get practiceEnd => 'End practice';

  @override
  String practiceProgress(String current, String total) {
    return '$current of $total';
  }

  @override
  String get practicePrompt => 'What is the German word for this?';

  @override
  String get practiceReveal => 'Show answer';

  @override
  String get practiceAsk => 'Did you remember it?';

  @override
  String get practiceRemembered => 'Remembered';

  @override
  String get practiceForgotten => 'Not remembered';

  @override
  String get practiceEmptyTitle => 'No words to practise';

  @override
  String get practiceEmptyBody =>
      'This practice needs words that have a Persian meaning.';

  @override
  String get practiceEmptyDifficult =>
      'No difficult word with a Persian meaning was found. You can mark words as difficult on their page.';

  @override
  String get practiceDoneTitle => 'Practice complete';

  @override
  String practiceRememberedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remembered $count words',
      one: 'Remembered 1 word',
    );
    return '$_temp0';
  }

  @override
  String practiceForgottenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Did not remember $count words',
      one: 'Did not remember 1 word',
    );
    return '$_temp0';
  }

  @override
  String get practiceFinish => 'Back to Today';

  @override
  String get practiceSeeStatistics => 'See statistics';

  @override
  String get statsWords => 'Words';

  @override
  String get statsDifficult => 'Difficult words';

  @override
  String get statsReviews => 'Recorded answers';

  @override
  String get statsRemembered => 'Remembered';

  @override
  String get statsSessions => 'Practice sessions';

  @override
  String get statsStudyDays => 'Days practised';

  @override
  String get statsCurrentStreak => 'Current streak';

  @override
  String get statsLongestStreak => 'Longest streak';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get statsRecentDays => 'Answers in the last 14 days';

  @override
  String get statsEmptyBody =>
      'Practice statistics come from the answers you record in practice. None have been recorded yet.';

  @override
  String get statsPolicy =>
      'Only answers you recorded after revealing a word are counted; opening the app or a word is not. A day runs from midnight to midnight on this device\'s clock. A streak continues while you practised yesterday or today. These numbers do not mean a word is learned for good.';

  @override
  String get practiceScheduledNote =>
      'Scheduled review: only cards that are due are shown, and each answer sets the next review with the FSRS algorithm. New words are added up to each deck\'s daily limit.';

  @override
  String get practiceFreeMode => 'Free practice (does not change the schedule)';

  @override
  String get practicePromptMeaning => 'What does this German word mean?';

  @override
  String get practiceEmptyDueTitle => 'Nothing to review right now';

  @override
  String get practiceEmptyDueBody =>
      'All due cards have been reviewed; the next ones come back when they are due. You can practise freely without changing the schedule.';

  @override
  String get practiceFreeInstead => 'Free practice';

  @override
  String get practiceScheduledDone => 'The next review of each card was saved.';

  @override
  String get reviewDirectionTitle => 'Review direction';

  @override
  String get reviewDirectionGermanToPersian => 'German → Persian';

  @override
  String get reviewDirectionPersianToGerman => 'Persian → German';

  @override
  String get reviewDirectionBoth => 'Both directions';

  @override
  String get reviewDirectionBothNote =>
      'Each word has two separately scheduled cards. A word is asked in only one direction per day: the one due first (for new words, German → Persian).';

  @override
  String get reviewStart => 'Start review';

  @override
  String reviewDueCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cards to review',
      one: '1 card to review',
      zero: 'Nothing to review right now',
    );
    return '$_temp0';
  }

  @override
  String reviewDueShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get deckShowMeanings => 'Show meanings';

  @override
  String get deckHideMeanings => 'Hide meanings';

  @override
  String selectionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString selected',
    );
    return '$_temp0';
  }

  @override
  String get selectionSelectAll => 'Select all';

  @override
  String get selectionClear => 'Clear selection';

  @override
  String get selectionExit => 'Exit selection';

  @override
  String get selectionDelete => 'Delete selected';

  @override
  String bulkDeleteTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $countString words?',
      one: 'Delete 1 word?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteBody =>
      'Their meanings, tags and review schedule are deleted too. Recorded answers are kept for statistics. This cannot be undone.';

  @override
  String bulkDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString words deleted',
      one: '1 word deleted',
    );
    return '$_temp0';
  }

  @override
  String get scanPageImageLabel => 'Page photo';

  @override
  String get scanRemoveSelection => 'Remove from selection';

  @override
  String get scanModeHighlight => 'Highlight: draw over words';

  @override
  String get scanModeMove => 'Move and zoom';

  @override
  String get scanHighlightHint =>
      'Highlight mode: draw over a word or phrase with one finger, or tap a word. Pinch with two fingers to zoom.';

  @override
  String get scanMoveHint =>
      'Move mode: drag with one finger to move the page, pinch to zoom. Nothing is drawn.';

  @override
  String get scanUndoStroke => 'Undo last highlight';

  @override
  String get scanClearHighlights => 'Clear all highlights';

  @override
  String get scanMoreActions => 'More options';

  @override
  String get scanReadWholePage => 'Read the whole page as text';

  @override
  String scanHighlightCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString highlights',
      one: '1 highlight',
      zero: 'Nothing highlighted yet',
    );
    return '$_temp0';
  }

  @override
  String get scanReadHighlights => 'Read highlighted text';

  @override
  String scanHighlightLabel(String number) {
    return 'Highlight $number';
  }

  @override
  String get scanHighlightsEmpty =>
      'No text was recognized in the highlighted parts. Zoom in and draw over the whole word again.';

  @override
  String get scanHighlightsFailed => 'The text could not be read. Try again.';

  @override
  String get scanPhotoUnavailable =>
      'The photo could not be shown, so the whole page was read as text.';

  @override
  String scanFailedHighlights(String numbers) {
    return 'No text was recognized in highlight $numbers. You can go back to the photo and draw it again.';
  }

  @override
  String get scanBackToPhoto => 'Back to the photo';

  @override
  String get scanAddWord => 'Add a word';

  @override
  String get scanSplitItem => 'Split into single words';

  @override
  String get scanCombineNext => 'Combine with the next item';

  @override
  String scanSummaryTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items will be added:',
      one: '1 item will be added:',
      zero: 'Nothing to add',
    );
    return '$_temp0';
  }

  @override
  String get practiceEditWord => 'Edit word';

  @override
  String get practiceAnswerDetails => 'Answer and details';

  @override
  String get scanModeRectangle => 'Rectangle: select an area';

  @override
  String get scanRectangleHint =>
      'Rectangle mode: drag one finger to draw a box around the text; everything inside it is read. Use two fingers to zoom.';

  @override
  String scanRegionLabel(String number) {
    return 'Area $number';
  }

  @override
  String get scanRegionsEmpty =>
      'No text was recognized in the selected areas. Draw the rectangle around the text again, or zoom in.';

  @override
  String get coachTitle => 'Needs practice';

  @override
  String coachTileDescription(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString words need more practice',
      one: '1 word needs more practice',
      zero: 'Words you keep forgetting will gather here',
    );
    return '$_temp0';
  }

  @override
  String coachIntro(int days, int sessions, int window, int streak) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);
    final intl.NumberFormat sessionsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sessionsString = sessionsNumberFormat.format(sessions);
    final intl.NumberFormat windowNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String windowString = windowNumberFormat.format(window);
    final intl.NumberFormat streakNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String streakString = streakNumberFormat.format(streak);

    return 'This list comes from a simple rule over your review history: words you answered “not remembered” in at least $sessionsString separate sessions during the last $daysString days (within the word\'s last $windowString answers). A word leaves the list after $streakString correct answers in a row.';
  }

  @override
  String coachFailures(int failures, int attempts) {
    final intl.NumberFormat failuresNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failuresString = failuresNumberFormat.format(failures);
    final intl.NumberFormat attemptsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptsString = attemptsNumberFormat.format(attempts);

    String _temp0 = intl.Intl.pluralLogic(
      failures,
      locale: localeName,
      other: 'Not remembered $failuresString times',
      one: 'Not remembered once',
    );
    return '$_temp0 (in the last $attemptsString answers)';
  }

  @override
  String get coachStart => 'Start focused practice';

  @override
  String get coachPracticeNote =>
      'This is extra practice: FSRS scheduling and due dates do not change. Your answers are only kept in your history and statistics.';

  @override
  String get coachEmptyTitle => 'No word needs extra practice yet';

  @override
  String get coachEmptyBody =>
      'Keep doing your normal reviews. Words you fail to remember in several review sessions will appear here.';

  @override
  String get coachGoToReview => 'Go to review';

  @override
  String get practiceEmptyCoach =>
      'No word with a Persian meaning is on the “needs practice” list.';

  @override
  String get practiceRepeat => 'Again in this session (learning step)';

  @override
  String get filterMissingMeaning => 'Missing meaning';

  @override
  String get selectionEnrich => 'AI meanings for selected';

  @override
  String enrichReadySelection(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString selected words without a meaning will be sent to OpenRouter: only each word and its sentence.',
      one: '1 selected word without a meaning will be sent to OpenRouter: only the word and its sentence.',
    );
    return '$_temp0 Only Persian meanings are requested, and you review every suggestion before anything is saved.';
  }

  @override
  String enrichSelectionExcluded(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString selected words already have a meaning; they are not sent and their meanings do not change.',
      one: '1 selected word already has a meaning; it is not sent and its meaning does not change.',
    );
    return '$_temp0';
  }

  @override
  String enrichSelectionOverflow(int max, int count) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'At most $maxString words are sent per run; $countString more can be completed in a next run.';
  }

  @override
  String get enrichSelectionEmptyBody =>
      'None of the selected words is missing a meaning. Existing meanings are not changed here.';

  @override
  String enrichProgressDetail(int ok, int failed) {
    final intl.NumberFormat okNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String okString = okNumberFormat.format(ok);
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);

    return '$okString answered · $failedString failed';
  }

  @override
  String get enrichEditMeaning => 'Edit meaning';

  @override
  String get enrichEdited => 'Edited by you';

  @override
  String get enrichBackToWords => 'Back to words';

  @override
  String get aiErrorBusy =>
      'This word is already being requested in another run. Try again when it has finished.';
}
