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
  String get sourceCsv => 'CSV import';

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
}
