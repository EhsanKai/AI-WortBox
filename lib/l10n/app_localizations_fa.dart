// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'AI WortBox';

  @override
  String get appTagline => 'از صفحه کتاب تا یادگیری ماندگار';

  @override
  String get navToday => 'مرور امروز';

  @override
  String get navMyWords => 'لغات من';

  @override
  String get navAdd => 'افزودن لغت';

  @override
  String get navStatistics => 'آمار';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get dashboardDecks => 'دسته‌ها';

  @override
  String get dashboardWords => 'لغات';

  @override
  String get dashboardYourDecks => 'دسته‌های شما';

  @override
  String get emptyDecksTitle => 'هنوز دسته‌ای نساخته‌اید';

  @override
  String get emptyDecksBody =>
      'برای شروع، یک دستهٔ لغت بسازید. هر دسته زبان‌ها و محدودیت روزانهٔ خودش را دارد.';

  @override
  String get actionCreateDeck => 'ساخت دستهٔ جدید';

  @override
  String get actionCancel => 'انصراف';

  @override
  String get actionRetry => 'تلاش دوباره';

  @override
  String deckWordCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString لغت',
      zero: 'بدون لغت',
    );
    return '$_temp0';
  }

  @override
  String deckLanguagePair(String source, String definition) {
    return '$source ← $definition';
  }

  @override
  String deckDailyLimit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حداکثر $countString کارت جدید در روز',
      zero: 'بدون کارت جدید',
    );
    return '$_temp0';
  }

  @override
  String deckCreatedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'ساخته‌شده در $dateString';
  }

  @override
  String get deckNotFound => 'این دسته پیدا نشد.';

  @override
  String get createDeckTitle => 'دستهٔ جدید';

  @override
  String get createDeckNameLabel => 'نام دسته';

  @override
  String get createDeckNameHint => 'مثلاً Der Vorleser یا لغات A1';

  @override
  String get createDeckLanguagesLabel => 'زبان یادگیری و زبان معنی';

  @override
  String get createDeckDailyLimitLabel => 'تعداد کارت جدید در روز';

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

    return 'از $minString تا $maxString؛ صفر یعنی موقتاً کارت جدیدی نشان داده نشود.';
  }

  @override
  String get createDeckSubmit => 'ساختن';

  @override
  String deckCreatedMessage(String name) {
    return 'دستهٔ «$name» ساخته شد.';
  }

  @override
  String get errorDeckNameEmpty => 'نام دسته را وارد کنید.';

  @override
  String errorDeckNameTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'نام دسته حداکثر $maxString نویسه می‌تواند باشد.';
  }

  @override
  String get errorDeckNameDuplicate => 'دسته‌ای با همین نام وجود دارد.';

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

    return 'عددی بین $minString و $maxString وارد کنید.';
  }

  @override
  String get errorInvalidNumber => 'یک عدد صحیح وارد کنید.';

  @override
  String get errorUnsupportedLanguage => 'این زبان هنوز پشتیبانی نمی‌شود.';

  @override
  String get errorIdenticalLanguages =>
      'زبان یادگیری و زبان معنی باید متفاوت باشند.';

  @override
  String get errorStorage =>
      'ذخیره‌سازی روی دستگاه با خطا روبه‌رو شد. دوباره تلاش کنید.';

  @override
  String get errorGeneric => 'مشکلی پیش آمد. دوباره تلاش کنید.';

  @override
  String get addSubtitle => 'لغت‌ها را از کجا می‌آورید؟';

  @override
  String get addImportCsv => 'وارد کردن فایل CSV';

  @override
  String get addImportCsvDescription =>
      'فهرست لغت‌هایتان را از یک فایل CSV وارد کنید.';

  @override
  String get addManual => 'افزودن دستی';

  @override
  String get addManualDescription =>
      'یک لغت یا عبارت آلمانی و معنی آن را بنویسید.';

  @override
  String get addScan => 'اسکن صفحهٔ کتاب';

  @override
  String get addScanDescription =>
      'از صفحهٔ کتاب عکس بگیرید و لغت‌های دلخواه را انتخاب کنید.';

  @override
  String get comingSoon => 'به‌زودی';

  @override
  String get statisticsEmpty =>
      'آمار یادگیری پس از شروع مرورها نمایش داده می‌شود.';

  @override
  String get settingsLanguages => 'زبان‌های پیش‌فرض';

  @override
  String get settingsSourceLanguage => 'زبان یادگیری';

  @override
  String get settingsDefinitionLanguage => 'زبان معنی';

  @override
  String get settingsPrivacy => 'حریم خصوصی و ذخیره‌سازی';

  @override
  String get settingsPrivacyBody =>
      'همهٔ داده‌ها فقط روی همین دستگاه ذخیره می‌شوند و نیازی به ثبت‌نام نیست.';

  @override
  String get settingsAbout => 'درباره';

  @override
  String get deckAddWord => 'افزودن لغت';

  @override
  String get deckImportCsv => 'وارد کردن CSV';

  @override
  String get deckNoEntriesTitle => 'این دسته هنوز لغتی ندارد';

  @override
  String get deckNoEntriesBody =>
      'لغت‌ها را دستی اضافه کنید یا از یک فایل CSV وارد کنید.';

  @override
  String get searchHint => 'جستجو در لغت‌ها و معنی‌ها';

  @override
  String get searchNoResults => 'لغتی با این عبارت پیدا نشد.';

  @override
  String get entryNoMeaning => 'بدون معنی';

  @override
  String get entryMeanings => 'معنی‌ها';

  @override
  String get entryExample => 'مثال';

  @override
  String get entryGrammar => 'دستور زبان';

  @override
  String get entryLemma => 'شکل پایه';

  @override
  String get entryPartOfSpeech => 'نوع کلمه';

  @override
  String get entryNotes => 'یادداشت';

  @override
  String get entrySource => 'منبع';

  @override
  String get sourceManual => 'ورود دستی';

  @override
  String get sourceCsv => 'وارد شده از فایل (CSV یا Anki)';

  @override
  String get sourceImage => 'اسکن کتاب';

  @override
  String get entryStatus => 'وضعیت معنی';

  @override
  String get entryStatusMissing => 'منتظر معنی';

  @override
  String get entryStatusPending => 'در حال تکمیل';

  @override
  String get entryStatusReady => 'آماده';

  @override
  String get entryStatusFailed => 'تکمیل ناموفق بود';

  @override
  String entryUpdatedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'آخرین تغییر: $dateString';
  }

  @override
  String get entryNotFound => 'این لغت پیدا نشد.';

  @override
  String get actionEdit => 'ویرایش';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionSave => 'ذخیره';

  @override
  String get actionSaveAndAddAnother => 'ذخیره و لغت بعدی';

  @override
  String deleteEntryTitle(String word) {
    return '«$word» حذف شود؟';
  }

  @override
  String get deleteEntryBody =>
      'این لغت، معنی‌ها و سابقهٔ مرور آن برای همیشه حذف می‌شوند.';

  @override
  String get entryDeletedMessage => 'لغت حذف شد.';

  @override
  String get formNewEntryTitle => 'لغت جدید';

  @override
  String get formEditEntryTitle => 'ویرایش لغت';

  @override
  String get formDeckLabel => 'دسته';

  @override
  String get formWordLabel => 'لغت یا عبارت آلمانی';

  @override
  String get formWordHint => 'مثلاً sich Mühe geben';

  @override
  String formMeaningLabel(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return 'معنی $indexString';
  }

  @override
  String get formAddMeaning => 'افزودن معنی دیگر';

  @override
  String get formRemoveMeaning => 'حذف این معنی';

  @override
  String get formMeaningsHelper =>
      'اگر معنی را هنوز نمی‌دانید، خالی بگذارید؛ بعداً قابل تکمیل است.';

  @override
  String get formMoreDetails => 'جزئیات بیشتر';

  @override
  String get formExampleLabel => 'جملهٔ مثال آلمانی';

  @override
  String get formExampleTranslationLabel => 'ترجمهٔ فارسی مثال';

  @override
  String get formGrammarLabel => 'اطلاعات دستوری';

  @override
  String get formGrammarHint => 'مثلاً der Tisch, -e';

  @override
  String get formLemmaLabel => 'شکل پایه';

  @override
  String get formPartOfSpeechLabel => 'نوع کلمه';

  @override
  String get formPartOfSpeechHint => 'مثلاً Nomen یا Verb';

  @override
  String get formNotesLabel => 'یادداشت';

  @override
  String get formNoDecks => 'برای افزودن لغت ابتدا یک دسته بسازید.';

  @override
  String entrySavedMessage(String word) {
    return '«$word» ذخیره شد.';
  }

  @override
  String entryMergedMessage(String word) {
    return 'معنی‌های جدید به «$word» اضافه شد.';
  }

  @override
  String get errorWordEmpty => 'لغت آلمانی را وارد کنید.';

  @override
  String errorTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'حداکثر $maxString نویسه مجاز است.';
  }

  @override
  String errorTooManyMeanings(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'حداکثر $maxString معنی مجاز است.';
  }

  @override
  String get errorDeckNotFound => 'دستهٔ انتخاب‌شده دیگر وجود ندارد.';

  @override
  String get errorEntryNotFound => 'این لغت دیگر وجود ندارد.';

  @override
  String get duplicateRedundantTitle => 'این لغت قبلاً ذخیره شده';

  @override
  String duplicateRedundantBody(String word) {
    return '«$word» با همین معنی در این دسته وجود دارد.';
  }

  @override
  String get duplicateDifferentTitle => 'این لغت با معنی دیگری وجود دارد';

  @override
  String duplicateDifferentBody(String word) {
    return '«$word» در این دسته با این معنی‌ها ذخیره شده است:';
  }

  @override
  String get duplicateOpenExisting => 'نمایش لغت موجود';

  @override
  String get duplicateAddMeanings => 'افزودن معنی‌ها به لغت موجود';

  @override
  String get duplicateSaveSeparate => 'ذخیره به‌عنوان لغت جداگانه';

  @override
  String get duplicateSaveAnyway => 'در هر صورت ذخیره شود';

  @override
  String get csvIntro =>
      'فایلی با ستون‌هایی مانند word و meaning انتخاب کنید. پیش از ذخیره، همه‌چیز را بررسی می‌کنید.';

  @override
  String get csvSectionDeck => 'دستهٔ مقصد';

  @override
  String get csvSectionFile => 'فایل';

  @override
  String get csvSectionColumns => 'ستون‌ها';

  @override
  String get csvSectionLanguages => 'زبان‌ها';

  @override
  String get csvSectionDuplicates => 'لغت‌های تکراری';

  @override
  String get csvSectionPreview => 'پیش‌نمایش';

  @override
  String get csvChooseFile => 'انتخاب فایل CSV';

  @override
  String get csvChooseAnother => 'انتخاب فایل دیگر';

  @override
  String csvRecordCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ردیف',
    );
    return '$_temp0';
  }

  @override
  String csvEncoding(String name) {
    return 'کدگذاری: $name';
  }

  @override
  String get csvDelimiterLabel => 'جداکننده';

  @override
  String get csvDelimiterAuto => 'تشخیص خودکار';

  @override
  String get csvDelimiterComma => 'ویرگول ( , )';

  @override
  String get csvDelimiterSemicolon => 'نقطه‌ویرگول ( ; )';

  @override
  String get csvDelimiterTab => 'تب';

  @override
  String get csvDelimiterPipe => 'خط عمودی ( | )';

  @override
  String get csvHasHeader => 'ردیف اول شامل نام ستون‌هاست';

  @override
  String csvColumnLabel(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return 'ستون $indexString';
  }

  @override
  String get csvFieldIgnore => 'نادیده گرفته شود';

  @override
  String get csvFieldOriginal => 'لغت آلمانی';

  @override
  String get csvFieldMeaning => 'معنی فارسی';

  @override
  String get csvFieldLemma => 'شکل پایه';

  @override
  String get csvFieldPartOfSpeech => 'نوع کلمه';

  @override
  String get csvFieldExample => 'جملهٔ مثال';

  @override
  String get csvFieldExampleTranslation => 'ترجمهٔ مثال';

  @override
  String get csvFieldGrammar => 'اطلاعات دستوری';

  @override
  String get csvFieldNotes => 'یادداشت';

  @override
  String get csvMappingNeedsWord => 'یک ستون را به «لغت آلمانی» اختصاص دهید.';

  @override
  String get csvMeaningSplitHint =>
      'چند معنی در یک خانه را می‌توان با ؛ یا | جدا کرد.';

  @override
  String csvLanguagesConfirm(String source, String definition) {
    return 'تأیید می‌کنم که لغت‌ها به زبان $source و معنی‌ها به زبان $definition هستند.';
  }

  @override
  String get csvLanguagesSwapped =>
      'به نظر می‌رسد ستون لغت فارسی و ستون معنی آلمانی است.';

  @override
  String get csvSwapColumns => 'جابه‌جا کردن ستون‌ها';

  @override
  String get csvStrategySkip => 'رد کردن لغت‌های موجود';

  @override
  String get csvStrategySkipDescription =>
      'اگر لغت در دسته یا در ردیف‌های قبلی فایل باشد، وارد نمی‌شود.';

  @override
  String get csvStrategyMerge => 'افزودن معنی‌های تازه به لغت موجود';

  @override
  String get csvStrategyMergeDescription =>
      'فقط معنی‌ها و خانه‌های خالی اضافه می‌شوند؛ چیزی بازنویسی نمی‌شود.';

  @override
  String get csvStrategySeparate => 'لغت جداگانه برای معنی متفاوت';

  @override
  String get csvStrategySeparateDescription =>
      'اگر معنی متفاوت باشد، لغت جداگانه‌ای ساخته می‌شود.';

  @override
  String get csvStrategyNote =>
      'ردیف‌هایی که معنی تازه‌ای ندارند همیشه رد می‌شوند.';

  @override
  String csvCountNew(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString جدید';
  }

  @override
  String csvCountMerge(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ادغام';
  }

  @override
  String csvCountSkip(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString تکراری';
  }

  @override
  String csvCountError(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString خطا';
  }

  @override
  String csvRowLine(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'خط $lineString';
  }

  @override
  String get csvRowNew => 'جدید';

  @override
  String get csvRowMerge => 'افزودن معنی به لغت موجود';

  @override
  String csvRowMergeInFile(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'افزودن معنی به خط $lineString';
  }

  @override
  String get csvRowRedundant => 'تکراری — رد می‌شود';

  @override
  String csvRowRedundantInFile(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'تکرار خط $lineString — رد می‌شود';
  }

  @override
  String get csvRowExists => 'لغت موجود — رد می‌شود';

  @override
  String csvRowExistsInFile(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'لغت در خط $lineString آمده — رد می‌شود';
  }

  @override
  String get csvRowIssueMissingWord => 'لغت آلمانی خالی است';

  @override
  String get csvRowIssueWordTooLong => 'لغت بیش از حد طولانی است';

  @override
  String get csvRowIssueMeaningTooLong => 'معنی بیش از حد طولانی است';

  @override
  String get csvRowIssueTooManyMeanings => 'تعداد معنی‌ها بیش از حد است';

  @override
  String get csvRowIssueFieldTooLong => 'یکی از خانه‌ها بیش از حد طولانی است';

  @override
  String csvErrorsTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ردیف خطا دارد و وارد نمی‌شود',
    );
    return '$_temp0';
  }

  @override
  String csvMoreRows(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'و $countString ردیف دیگر';
  }

  @override
  String csvImportButton(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'وارد کردن $countString ردیف',
    );
    return '$_temp0';
  }

  @override
  String get csvNothingToImport => 'ردیفی برای وارد کردن وجود ندارد.';

  @override
  String get csvImportDone => 'وارد کردن انجام شد';

  @override
  String csvResultCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString لغت جدید ساخته شد';
  }

  @override
  String csvResultMerged(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ردیف به لغت‌های موجود اضافه شد';
  }

  @override
  String csvResultSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ردیف تکراری رد شد';
  }

  @override
  String csvResultErrors(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ردیف به دلیل خطا وارد نشد';
  }

  @override
  String get csvViewDeck => 'مشاهدهٔ دسته';

  @override
  String get csvImportAnother => 'وارد کردن فایل دیگر';

  @override
  String get csvImportFailed =>
      'وارد کردن انجام نشد و هیچ تغییری ذخیره نشد. دوباره تلاش کنید.';

  @override
  String get csvFormatEmpty => 'فایل خالی است.';

  @override
  String csvFormatTooLarge(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'فایل بزرگ‌تر از $maxString مگابایت است.';
  }

  @override
  String csvFormatTooManyRows(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'فایل بیش از $maxString ردیف دارد.';
  }

  @override
  String get csvFormatEncoding =>
      'کدگذاری فایل پشتیبانی نمی‌شود. فایل را با کدگذاری UTF-8 ذخیره کنید.';

  @override
  String csvFormatUnterminatedQuote(int line) {
    final intl.NumberFormat lineNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String lineString = lineNumberFormat.format(line);

    return 'علامت نقل‌قول در خط $lineString بسته نشده است.';
  }

  @override
  String get csvFormatNoDataRows => 'فایل هیچ ردیف داده‌ای ندارد.';

  @override
  String get csvFileReadFailed => 'فایل خوانده نشد. دوباره تلاش کنید.';

  @override
  String get scanTitle => 'اسکن صفحهٔ کتاب';

  @override
  String get scanIntro =>
      'از یک صفحهٔ آلمانی عکس بگیرید یا عکسی انتخاب کنید. متن روی همین دستگاه خوانده می‌شود و عکس جایی فرستاده نمی‌شود.';

  @override
  String get scanOcrWarning =>
      'تشخیص متن ممکن است اشتباه کند؛ پیش از ذخیره، لغت‌ها را بررسی و اصلاح کنید.';

  @override
  String get scanTakePhoto => 'گرفتن عکس';

  @override
  String get scanChoosePhoto => 'انتخاب از گالری';

  @override
  String get scanTypeText => 'تایپ یا چسباندن متن';

  @override
  String get scanRecognizing => 'در حال خواندن متن…';

  @override
  String get scanErrorCameraPermission =>
      'دسترسی به دوربین داده نشده است. در تنظیمات دستگاه اجازه دهید یا عکسی از گالری انتخاب کنید.';

  @override
  String get scanErrorPhotoPermission =>
      'دسترسی به عکس‌ها داده نشده است. در تنظیمات دستگاه اجازه دهید یا از دوربین استفاده کنید.';

  @override
  String get scanErrorCameraUnavailable => 'دوربین در دسترس نیست.';

  @override
  String get scanErrorUnsupportedFormat =>
      'این قالب تصویر پشتیبانی نمی‌شود. از JPG، PNG، HEIC یا WebP استفاده کنید.';

  @override
  String get scanErrorTooLarge => 'تصویر بیش از حد بزرگ است.';

  @override
  String get scanErrorUnreadable => 'تصویر خوانده نشد.';

  @override
  String get scanErrorOcrUnavailable =>
      'تشخیص متن روی این دستگاه در دسترس نیست. می‌توانید متن را تایپ کنید.';

  @override
  String get scanErrorOcrFailed =>
      'خواندن متن انجام نشد. دوباره تلاش کنید یا متن را تایپ کنید.';

  @override
  String get scanNoTextTitle => 'متنی پیدا نشد';

  @override
  String get scanNoTextBody => 'عکس واضح‌تری بگیرید یا متن را تایپ کنید.';

  @override
  String get scanTryAgain => 'عکس دیگر';

  @override
  String get scanTypedHint => 'متن آلمانی را اینجا تایپ یا جای‌گذاری کنید';

  @override
  String get scanUseText => 'استفاده از این متن';

  @override
  String get scanSelectHint =>
      'روی لغت‌ها بزنید تا انتخاب شوند. برای عبارت چندکلمه‌ای، حالت «عبارت» را بزنید و سپس روی اولین و آخرین لغت بزنید.';

  @override
  String get scanModeWord => 'لغت';

  @override
  String get scanModeExpression => 'عبارت';

  @override
  String get scanExpressionPickEnd => 'حالا روی آخرین لغت عبارت بزنید.';

  @override
  String scanExpressionTooLong(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'عبارت باید در یک پاراگراف و حداکثر $maxString لغت باشد.';
  }

  @override
  String scanSelectedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString مورد انتخاب شده',
      zero: 'هیچ لغتی انتخاب نشده',
    );
    return '$_temp0';
  }

  @override
  String get scanClearSelection => 'پاک کردن انتخاب‌ها';

  @override
  String get scanEditText => 'اصلاح متن';

  @override
  String get scanEditTextTitle => 'اصلاح متن تشخیص‌داده‌شده';

  @override
  String scanSelectionsDropped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString انتخاب به‌دلیل تغییر متن حذف شد.',
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
      other: 'بررسی $countString مورد',
    );
    return '$_temp0';
  }

  @override
  String get scanReviewTitle => 'بررسی پیش از ذخیره';

  @override
  String get scanReviewIntro =>
      'فقط موارد این فهرست ذخیره می‌شوند. اشتباه‌های تشخیص را اصلاح کنید.';

  @override
  String get scanItemWord => 'لغت یا عبارت آلمانی';

  @override
  String get scanItemContext => 'جملهٔ اصلی';

  @override
  String get scanItemLemma => 'شکل پایه (اختیاری)';

  @override
  String get scanItemMeaning => 'معنی فارسی (اختیاری)';

  @override
  String get scanItemRemove => 'حذف از فهرست';

  @override
  String scanLemmaHint(String base) {
    return 'پیشنهاد شکل پایه: $base';
  }

  @override
  String get scanLemmaHintNote =>
      'از فهرست داخلی افعال بی‌قاعده؛ لطفاً بررسی کنید.';

  @override
  String get scanUseHint => 'استفاده';

  @override
  String get scanStatusNew => 'جدید';

  @override
  String get scanStatusRedundant => 'در این دسته وجود دارد — ذخیره نمی‌شود';

  @override
  String get scanStatusRedundantInList =>
      'تکراری در همین فهرست — ذخیره نمی‌شود';

  @override
  String get scanStatusExists => 'لغت با معنی دیگری وجود دارد — ذخیره نمی‌شود';

  @override
  String get scanStatusMerge => 'معنی به لغت موجود اضافه می‌شود';

  @override
  String get scanStatusInvalid => 'لغت خالی است';

  @override
  String scanSaveButton(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ذخیرهٔ $countString مورد',
      zero: 'چیزی برای ذخیره نیست',
    );
    return '$_temp0';
  }

  @override
  String get scanSavedTitle => 'ذخیره شد';

  @override
  String get scanScanAnother => 'اسکن صفحهٔ دیگر';

  @override
  String get scanBackToText => 'بازگشت به متن';

  @override
  String get scanSaveFailed =>
      'ذخیره انجام نشد و هیچ تغییری اعمال نشد. دوباره تلاش کنید.';

  @override
  String scanResultCreated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString لغت جدید ذخیره شد';
  }

  @override
  String scanResultMerged(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'معنی $countString مورد به لغت‌های موجود اضافه شد';
  }

  @override
  String scanResultSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString مورد تکراری ذخیره نشد';
  }

  @override
  String get settingsLicenses => 'مجوزهای نرم‌افزار و فونت‌ها';

  @override
  String get scanWordTapToSelect => 'انتخاب لغت';

  @override
  String get scanWordTapToDeselect => 'لغو انتخاب';

  @override
  String get settingsAi => 'هوش مصنوعی';

  @override
  String get settingsAiConfigured => 'فعال — کلید OpenRouter شما ذخیره شده است';

  @override
  String get settingsAiNotConfigured => 'غیرفعال — کلید OpenRouter تنظیم نشده';

  @override
  String get aiSettingsTitle => 'هوش مصنوعی';

  @override
  String get aiIntroTitle => 'با حساب OpenRouter خودتان';

  @override
  String get aiIntroBody =>
      'برای پیشنهاد معنی، مثال و نکات دستوری، AI WortBox از حساب OpenRouter خود شما استفاده می‌کند. به‌طور پیش‌فرض فقط مدل‌های رایگان استفاده می‌شوند و هزینه‌ای کم نمی‌شود؛ مدل‌های رایگان سقف روزانه دارند. AI WortBox کلید یا حساب مشترکی ندارد و بدون کلید شما هیچ درخواستی نمی‌فرستد.';

  @override
  String get aiGetKey => 'دریافت کلید در openrouter.ai/keys';

  @override
  String get aiKeyLabel => 'کلید API';

  @override
  String get aiKeyNewLabel => 'کلید API جدید';

  @override
  String get aiKeyShow => 'نمایش کلید';

  @override
  String get aiKeyHide => 'پنهان کردن کلید';

  @override
  String get aiKeySave => 'ذخیره و بررسی';

  @override
  String aiKeySaved(String suffix) {
    return 'کلید ذخیره‌شده: ••••$suffix';
  }

  @override
  String get aiKeySavedNote => 'کلید کامل دیگر نمایش داده نمی‌شود.';

  @override
  String get aiKeyTest => 'بررسی کلید';

  @override
  String get aiKeyReplace => 'جایگزینی کلید';

  @override
  String get aiKeyRemove => 'حذف کلید';

  @override
  String get aiKeyRemoveTitle => 'کلید حذف شود؟';

  @override
  String get aiKeyRemoveBody =>
      'کلید از حافظهٔ امن این دستگاه حذف می‌شود. لغت‌ها و معنی‌های ذخیره‌شده دست نمی‌خورند. کلید در حساب OpenRouter شما همچنان فعال است؛ برای باطل کردن آن به openrouter.ai بروید.';

  @override
  String get aiKeyRemoved => 'کلید حذف شد.';

  @override
  String get aiKeySaveFailed =>
      'کلید در فضای امن این دستگاه ذخیره نشد. دوباره تلاش کنید.';

  @override
  String get aiKeyRemoveFailed =>
      'کلید از فضای امن این دستگاه حذف نشد. دوباره تلاش کنید.';

  @override
  String get aiModelSaveFailed => 'انتخاب مدل ذخیره نشد. دوباره تلاش کنید.';

  @override
  String get aiKeyProblemEmpty => 'کلید را وارد کنید.';

  @override
  String get aiKeyProblemWhitespace =>
      'کلید نباید فاصله یا خط جدید داشته باشد.';

  @override
  String get aiKeyProblemShort => 'این کلید خیلی کوتاه است.';

  @override
  String get aiKeyProblemLong => 'این کلید خیلی بلند است.';

  @override
  String get aiCheckRunning => 'در حال بررسی کلید…';

  @override
  String get aiCheckPassed => 'کلید معتبر است و هوش مصنوعی آماده است.';

  @override
  String aiCheckUsage(String amount) {
    return 'اعتبار مصرف‌شده با این کلید (گزارش OpenRouter): $amount دلار';
  }

  @override
  String aiCheckRemaining(String amount) {
    return 'باقی‌ماندهٔ سقف این کلید: $amount دلار';
  }

  @override
  String get aiCheckModelUnavailable =>
      'مدل انتخاب‌شده اکنون در OpenRouter با خروجی ساختاریافته در دسترس نیست. مدل دیگری انتخاب کنید.';

  @override
  String get aiCheckModelUnknown =>
      'فهرست مدل‌ها بارگیری نشد؛ در دسترس بودن مدل بررسی نشد.';

  @override
  String get aiModelLabel => 'مدل';

  @override
  String get aiModelHelper =>
      'فهرستی منتخب از مدل‌های کم‌هزینه با خروجی ساختاریافته که فقط وقتی «فقط مدل‌های رایگان» خاموش است استفاده می‌شود. قیمت‌ها در openrouter.ai آمده است.';

  @override
  String get aiPrivacyTitle => 'حریم خصوصی و اتصال';

  @override
  String get aiPrivacyBody =>
      'فقط وقتی شما درخواست کنید، لغت، جملهٔ آن و معنی‌های فعلی‌اش به OpenRouter و ارائه‌دهندهٔ مدل فرستاده می‌شود. این متن از دستگاه خارج می‌شود و سیاست‌های آن‌ها بر آن اعمال می‌شود. پیشنهاد هوش مصنوعی به اینترنت نیاز دارد؛ بقیهٔ برنامه بدون اینترنت کار می‌کند.';

  @override
  String get aiSecurityTitle => 'نگهداری کلید';

  @override
  String get aiSecurityBody =>
      'کلید در حافظهٔ امن سیستم (Keychain در iOS، Keystore در اندروید) نگه داشته می‌شود؛ هرگز نمایش داده نمی‌شود و در پایگاه داده، گزارش‌ها یا پشتیبان قرار نمی‌گیرد. این کار خطر را کم می‌کند، اما روی دستگاهی آلوده یا دستکاری‌شده، استخراج کلید ناممکن نیست. در OpenRouter برای این کلید سقف اعتبار تعیین کنید.';

  @override
  String get aiFreeTitle => 'استفادهٔ رایگان';

  @override
  String get aiFreeOnly => 'فقط مدل‌های رایگان';

  @override
  String get aiFreeOnlyOn =>
      'هیچ درخواستی هزینه ندارد: فقط مدل‌هایی که رایگان بودنشان تأیید شده استفاده می‌شوند و از OpenRouter خواسته می‌شود هر مورد پولی را رد کند.';

  @override
  String get aiFreeOnlyOff =>
      'خاموش: مدل زیر استفاده می‌شود و هزینه‌اش از اعتبار OpenRouter شما کم می‌شود.';

  @override
  String get aiPaidConfirmTitle => 'از مدل‌های پولی استفاده شود؟';

  @override
  String get aiPaidConfirmBody =>
      'در این صورت هزینهٔ هر درخواست از اعتبار OpenRouter شما کم می‌شود. مدل‌های رایگان معمولاً برای واژگان کافی‌اند.';

  @override
  String get aiPaidConfirm => 'استفاده از مدل‌های پولی';

  @override
  String get aiRoutingAuto => 'رایگان خودکار';

  @override
  String get aiRoutingQuality => 'رایگان باکیفیت';

  @override
  String get aiRoutingAutoHelp =>
      'مسیریاب رایگان OpenRouter یکی از مدل‌های رایگانِ در دسترس را انتخاب می‌کند.';

  @override
  String get aiRoutingQualityHelp =>
      'ابتدا مدل‌های رایگانِ با امتیاز بالاتر و سپس مسیریاب رایگان امتحان می‌شوند. فهرست مدل‌های رایگان پیش از استفاده در OpenRouter بررسی می‌شود.';

  @override
  String get aiQualityUnverified =>
      'فهرست مدل‌های رایگان هنوز تأیید نشده است، پس از مسیریاب رایگان استفاده می‌شود. برای بررسی، وضعیت را به‌روز کنید.';

  @override
  String aiFreeModelsVerified(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString مدل رایگان تأیید شد',
    );
    return '$_temp0';
  }

  @override
  String aiCurrentModel(String model) {
    return 'مدل فعلی: $model';
  }

  @override
  String aiLastModel(String model) {
    return 'آخرین پاسخ از: $model';
  }

  @override
  String get aiLastModelNone => 'هنوز درخواستی فرستاده نشده است.';

  @override
  String get aiBatchSize => 'تعداد لغت در هر درخواست';

  @override
  String get aiBatchSizeHelp =>
      'درخواست کمتر یعنی مصرف کمتر از سهمیهٔ رایگان روزانه؛ دسته‌های کوچک‌تر مطمئن‌ترند.';

  @override
  String aiQuotaRemaining(int remaining, int limit) {
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'حدود $remainingString از $limitString درخواست رایگان امروز باقی مانده است';
  }

  @override
  String aiQuotaRemainingNoLimit(int remaining) {
    final intl.NumberFormat remainingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String remainingString = remainingNumberFormat.format(remaining);

    return 'حدود $remainingString درخواست رایگان امروز باقی مانده است';
  }

  @override
  String get aiQuotaUnknown =>
      'درخواست‌های رایگان باقی‌ماندهٔ امروز: هنوز بررسی نشده است. کلید را آزمایش یا وضعیت را به‌روز کنید.';

  @override
  String aiQuotaSentToday(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'فرستاده‌شده از این برنامه در امروز: $countString';
  }

  @override
  String get aiRateReady => 'آماده';

  @override
  String aiRateCooling(String time) {
    return 'محدودیت تعداد درخواست — منتظر تا $time';
  }

  @override
  String aiRatePaused(String time) {
    return 'سهمیهٔ رایگان روزانه تمام شده — متوقف تا $time';
  }

  @override
  String aiRatePacing(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'هر بار یک درخواست، با دست‌کم $secondsString ثانیه فاصله.';
  }

  @override
  String aiCacheStats(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString نتیجهٔ ذخیره‌شدهٔ هوش مصنوعی',
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

    return '$hitsString بار استفادهٔ دوباره · $missesString بار درخواست';
  }

  @override
  String get aiCacheClear => 'پاک کردن نتایج ذخیره‌شده';

  @override
  String get aiCacheCleared => 'نتایج ذخیره‌شده پاک شد.';

  @override
  String get aiRefreshUsage => 'به‌روزرسانی وضعیت';

  @override
  String get aiUsageRefreshFailed => 'وضعیت از OpenRouter دریافت نشد.';

  @override
  String get aiPrefsSaveFailed => 'تنظیم ذخیره نشد. دوباره امتحان کنید.';

  @override
  String get enrichTitle => 'پیشنهادهای هوش مصنوعی';

  @override
  String get enrichAction => 'پیشنهاد هوش مصنوعی';

  @override
  String get enrichDeckAction => 'پیشنهاد برای لغت‌های بدون معنی';

  @override
  String get enrichNotConfiguredTitle => 'هوش مصنوعی تنظیم نشده است';

  @override
  String get enrichNotConfiguredBody =>
      'کلید API حساب OpenRouter خودتان را در تنظیمات وارد کنید. بدون کلید هیچ درخواستی فرستاده نمی‌شود.';

  @override
  String get enrichOpenSettings => 'تنظیمات هوش مصنوعی';

  @override
  String get enrichEmptyTitle => 'لغتی برای تکمیل نیست';

  @override
  String get enrichEmptyBody =>
      'فقط لغت‌های بدون معنی گروهی پیشنهاد می‌گیرند. برای لغتی که معنی دارد، از صفحهٔ همان لغت درخواست کنید.';

  @override
  String enrichReadyBatch(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString لغت بدون معنی به OpenRouter فرستاده می‌شود.',
    );
    return '$_temp0 پیش از ذخیره، همهٔ پیشنهادها را بررسی می‌کنید.';
  }

  @override
  String get enrichReadySingle =>
      'این لغت و جملهٔ آن به OpenRouter فرستاده می‌شود. معنی‌ها و اطلاعات فعلی بدون تأیید شما تغییر نمی‌کنند.';

  @override
  String enrichModel(String model) {
    return 'مدل: $model';
  }

  @override
  String get enrichStart => 'دریافت پیشنهادها';

  @override
  String enrichProgress(int done, int total) {
    final intl.NumberFormat doneNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$doneString از $totalString';
  }

  @override
  String get enrichCancel => 'توقف';

  @override
  String get enrichStatusQueued => 'در صف';

  @override
  String get enrichStatusRunning => 'در حال دریافت…';

  @override
  String get enrichStatusProposed => 'پیشنهاد هوش مصنوعی — بررسی کنید';

  @override
  String get enrichStatusFailed => 'ناموفق';

  @override
  String get enrichStatusSkipped => 'پیشنهاد تازه‌ای نبود';

  @override
  String get enrichNewMeanings => 'معنی‌های پیشنهادی';

  @override
  String get enrichExistingKept =>
      'معنی‌های فعلی دست نمی‌خورند؛ موارد انتخاب‌شده اضافه می‌شوند.';

  @override
  String get enrichDetails => 'جزئیات پیشنهادی';

  @override
  String enrichReplaces(String current) {
    return 'به جای: $current';
  }

  @override
  String get enrichAmbiguous =>
      'بدون جملهٔ کامل‌تر، معنی قطعی نیست؛ با دقت بررسی کنید.';

  @override
  String enrichSave(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ذخیرهٔ $countString لغت',
    );
    return '$_temp0';
  }

  @override
  String get enrichNothingSelected => 'چیزی برای ذخیره انتخاب نشده است.';

  @override
  String get enrichRetry => 'تلاش دوباره برای موارد ناموفق';

  @override
  String get enrichSavedTitle => 'پیشنهادها ذخیره شد';

  @override
  String enrichSavedCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString لغت به‌روز شد',
    );
    return '$_temp0';
  }

  @override
  String enrichCost(String amount) {
    return 'هزینهٔ گزارش‌شده توسط OpenRouter: $amount دلار';
  }

  @override
  String get enrichNoCost => 'مدل‌های رایگان — بدون هزینه';

  @override
  String get enrichFreeOnly => 'فقط مدل‌های رایگان — بدون هزینه.';

  @override
  String enrichResume(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'یک اجرای ناتمام پیدا شد: $countString لغت باقی مانده است. لغت‌های انجام‌شده حفظ شده‌اند.',
    );
    return '$_temp0';
  }

  @override
  String get enrichFromCache => 'نتیجهٔ ذخیره‌شده — چیزی فرستاده نشد';

  @override
  String get enrichConflict =>
      'برخی لغت‌ها در این فاصله تغییر کرده‌اند، پس چیزی ذخیره نشد. دوباره پیشنهاد بگیرید.';

  @override
  String get aiErrorNotConfigured => 'کلید OpenRouter تنظیم نشده است.';

  @override
  String get aiErrorInvalidKey =>
      'OpenRouter این کلید را نپذیرفت. کلید را بررسی یا جایگزین کنید.';

  @override
  String get aiErrorCredits =>
      'اعتبار حساب یا سقف این کلید در OpenRouter تمام شده است. در openrouter.ai اعتبار اضافه کنید.';

  @override
  String get aiErrorForbidden =>
      'OpenRouter یا ارائه‌دهندهٔ مدل این درخواست را رد کرد.';

  @override
  String get aiErrorRateLimited =>
      'تعداد درخواست‌ها زیاد است. کمی بعد دوباره امتحان کنید.';

  @override
  String get aiErrorTimeout =>
      'پاسخ به‌موقع نرسید. ممکن است OpenRouter درخواست را پردازش کرده و هزینه‌اش را حساب کرده باشد؛ فقط در صورت نیاز دوباره امتحان کنید.';

  @override
  String get aiErrorNetwork =>
      'اتصال به اینترنت برقرار نیست. پیشنهاد هوش مصنوعی به اینترنت نیاز دارد.';

  @override
  String get aiErrorModel =>
      'مدل انتخاب‌شده در دسترس نیست. مدل دیگری در تنظیمات انتخاب کنید.';

  @override
  String get aiErrorBadRequest =>
      'OpenRouter درخواست را نپذیرفت. مدل دیگری را امتحان کنید.';

  @override
  String get aiErrorServer => 'OpenRouter خطا داد. کمی بعد دوباره امتحان کنید.';

  @override
  String get aiErrorMalformed =>
      'پاسخ مدل قابل استفاده نبود. دوباره امتحان کنید یا مدل دیگری انتخاب کنید.';

  @override
  String get aiErrorCancelled => 'متوقف شد.';

  @override
  String get aiErrorDailyQuota =>
      'درخواست‌های رایگان امروزِ حساب OpenRouter شما تمام شده است. هوش مصنوعی تا بازنشانی روزانه (ساعت ۰۰:۰۰ UTC) متوقف می‌ماند و تا آن زمان چیزی فرستاده نمی‌شود.';

  @override
  String get aiErrorPaidBlocked =>
      'برای رایگان ماندن متوقف شد: OpenRouter با مدل یا هزینه‌ای پاسخ داد که رایگان بودنش تأیید نشد. درخواست دیگری فرستاده نشد.';

  @override
  String get actionBack => 'بازگشت';

  @override
  String get csvFieldTags => 'برچسب‌ها';

  @override
  String get deckImportFile => 'وارد کردن فایل (CSV یا Anki)';

  @override
  String get deckMoreActions => 'کارهای بیشتر';

  @override
  String get searchAllTitle => 'جستجو در همه لغت‌ها';

  @override
  String get searchClear => 'پاک کردن متن جستجو';

  @override
  String searchLimited(int count) {
    return 'فقط $count نتیجهٔ اول نمایش داده می‌شود؛ جستجو را دقیق‌تر کنید.';
  }

  @override
  String get filterDifficult => 'لغت‌های دشوار';

  @override
  String get filterTag => 'برچسب';

  @override
  String get filterAllTags => 'همه برچسب‌ها';

  @override
  String get filterClear => 'حذف فیلترها';

  @override
  String entryInDeck(String deck) {
    return 'در دستهٔ $deck';
  }

  @override
  String get entryDifficult => 'دشوار';

  @override
  String get entryMarkDifficult => 'علامت‌گذاری به‌عنوان دشوار';

  @override
  String get entryUnmarkDifficult => 'برداشتن علامت دشوار';

  @override
  String get tagsTitle => 'برچسب‌ها';

  @override
  String get tagsSettingsDescription => 'ساختن، تغییر نام و حذف برچسب‌ها';

  @override
  String get tagsEmptyTitle => 'هنوز برچسبی ندارید';

  @override
  String get tagsEmptyHint =>
      'با برچسب‌هایی مثل «B1» یا «سفر» لغت‌ها را دسته‌بندی کنید.';

  @override
  String get tagsAdd => 'افزودن برچسب';

  @override
  String get tagsEdit => 'ویرایش برچسب‌ها';

  @override
  String get tagsEditTitle => 'برچسب‌های این لغت';

  @override
  String get tagNewLabel => 'برچسب تازه';

  @override
  String get tagNameLabel => 'نام برچسب';

  @override
  String get tagCreate => 'برچسب تازه';

  @override
  String get tagRename => 'تغییر نام برچسب';

  @override
  String tagWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت',
    );
    return '$_temp0';
  }

  @override
  String tagDeleteTitle(String name) {
    return 'برچسب «$name» حذف شود؟';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'برچسب از $count لغت برداشته می‌شود. خود لغت‌ها حذف نمی‌شوند.',
      zero: 'این برچسب به هیچ لغتی داده نشده است.',
    );
    return '$_temp0';
  }

  @override
  String get tagErrorEmpty => 'نام برچسب را بنویسید.';

  @override
  String tagErrorTooLong(int max) {
    return 'نام برچسب حداکثر $max نویسه است.';
  }

  @override
  String get tagErrorDuplicate => 'برچسبی با همین نام وجود دارد.';

  @override
  String get exportCsv => 'خروجی CSV';

  @override
  String get exportAnki => 'خروجی برای Anki (‎.apkg‎)';

  @override
  String get exportSaved => 'فایل ذخیره شد.';

  @override
  String get exportCancelled => 'ذخیرهٔ فایل لغو شد.';

  @override
  String get exportEmpty => 'این دسته لغتی برای خروجی ندارد.';

  @override
  String get exportWriteFailed => 'فایل ذخیره نشد. جای دیگری را امتحان کنید.';

  @override
  String get ankiImportTitle => 'وارد کردن از Anki';

  @override
  String get ankiImportDescription => 'یک بستهٔ ‎.apkg‎ از Anki انتخاب کنید';

  @override
  String get ankiImportIntro =>
      'در Anki یک دسته را با قالب «Anki Deck Package (‎.apkg‎)» خروجی بگیرید و اینجا انتخاب کنید. فیلدهای یادداشت‌ها را به لغت و معنی وصل کنید.';

  @override
  String get ankiImportNote =>
      'فقط متن یادداشت‌ها و برچسب‌ها وارد می‌شود؛ تصویر، صدا و سابقهٔ مرور Anki وارد نمی‌شود.';

  @override
  String ankiNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count یادداشت Anki',
    );
    return '$_temp0';
  }

  @override
  String get ankiErrorNotPackage =>
      'این فایل بستهٔ Anki (‎.apkg‎) نیست یا آسیب دیده است.';

  @override
  String get ankiErrorUnsupported => 'قالب این بستهٔ Anki پشتیبانی نمی‌شود.';

  @override
  String get ankiErrorNoNotes => 'این بستهٔ Anki هیچ یادداشتی ندارد.';

  @override
  String ankiErrorTooLarge(int size) {
    return 'بستهٔ Anki بزرگ‌تر از $size مگابایت است.';
  }

  @override
  String get speakWord => 'تلفظ لغت';

  @override
  String get speakExample => 'خواندن جملهٔ مثال';

  @override
  String get speechVoiceUnavailable =>
      'صدای آلمانی روی این دستگاه نصب نیست. در تنظیمات «تبدیل متن به گفتار» دستگاه آن را نصب کنید.';

  @override
  String get speechFailed => 'پخش تلفظ ممکن نشد.';

  @override
  String get settingsStudy => 'مطالعه';

  @override
  String get reminderTitle => 'یادآور مطالعه';

  @override
  String get reminderIntro =>
      'هر روز در ساعتی که انتخاب می‌کنید یک اعلان روی همین دستگاه نمایش داده می‌شود. هیچ سروری استفاده نمی‌شود.';

  @override
  String get reminderEnabled => 'یادآور روزانه';

  @override
  String get reminderTime => 'ساعت یادآوری';

  @override
  String get reminderOff => 'خاموش';

  @override
  String reminderOnAt(String time) {
    return 'هر روز ساعت $time';
  }

  @override
  String get reminderNote =>
      'برای روشن کردن یادآور، اجازهٔ نمایش اعلان خواسته می‌شود. در اندروید ممکن است اعلان چند دقیقه دیرتر برسد و برخی گوشی‌ها برای صرفه‌جویی در باتری آن را متوقف کنند.';

  @override
  String get reminderPermissionDenied =>
      'اجازهٔ اعلان داده نشد. آن را در تنظیمات دستگاه برای AI WortBox فعال کنید.';

  @override
  String get reminderSchedulingFailed => 'یادآور تنظیم نشد. دوباره تلاش کنید.';

  @override
  String get reminderNotificationTitle => 'وقت مرور لغت‌هاست';

  @override
  String get reminderNotificationBody =>
      'چند دقیقه با لغت‌های آلمانی خود تمرین کنید.';

  @override
  String get practiceTitle => 'مرور لغت‌ها';

  @override
  String get practiceTileDescription =>
      'جهت مرور، دسته و تمرین آزاد را انتخاب کنید';

  @override
  String practiceTileStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیاپی تمرین',
    );
    return '$_temp0';
  }

  @override
  String get practiceIntro =>
      'در هر کارت فقط یک طرف نمایش داده می‌شود. پاسخ را به یاد بیاورید، سپس آن را ببینید و بگویید به یاد آوردید یا نه.';

  @override
  String get practiceNotSrs =>
      'این تمرین آزاد است و زمان‌بندی مرور (FSRS) را تغییر نمی‌دهد. فقط نتیجهٔ شما برای آمار ثبت می‌شود.';

  @override
  String get practiceWordsFrom => 'لغت‌ها از';

  @override
  String get practiceAllDecks => 'همه دسته‌ها';

  @override
  String get practiceDifficultOnly => 'فقط لغت‌های دشوار';

  @override
  String get practiceStart => 'شروع تمرین';

  @override
  String get practiceEnd => 'پایان تمرین';

  @override
  String practiceProgress(String current, String total) {
    return '$current از $total';
  }

  @override
  String get practicePrompt => 'لغت آلمانی این معنی چیست؟';

  @override
  String get practiceReveal => 'نمایش پاسخ';

  @override
  String get practiceAsk => 'آن را به یاد آوردید؟';

  @override
  String get practiceRemembered => 'به یاد آوردم';

  @override
  String get practiceForgotten => 'به یاد نیاوردم';

  @override
  String get practiceEmptyTitle => 'لغتی برای تمرین نیست';

  @override
  String get practiceEmptyBody =>
      'برای این تمرین لغت‌هایی لازم است که معنی فارسی دارند.';

  @override
  String get practiceEmptyDifficult =>
      'هیچ لغت دشواری با معنی فارسی پیدا نشد. در صفحهٔ هر لغت می‌توانید آن را دشوار علامت بزنید.';

  @override
  String get practiceDoneTitle => 'تمرین تمام شد';

  @override
  String practiceRememberedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت را به یاد آوردید',
    );
    return '$_temp0';
  }

  @override
  String practiceForgottenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لغت را به یاد نیاوردید',
    );
    return '$_temp0';
  }

  @override
  String get practiceFinish => 'بازگشت به امروز';

  @override
  String get practiceSeeStatistics => 'دیدن آمار';

  @override
  String get statsWords => 'لغت‌ها';

  @override
  String get statsDifficult => 'لغت‌های دشوار';

  @override
  String get statsReviews => 'پاسخ‌های ثبت‌شده';

  @override
  String get statsRemembered => 'به یاد آورده';

  @override
  String get statsSessions => 'جلسه‌های تمرین';

  @override
  String get statsStudyDays => 'روزهای تمرین';

  @override
  String get statsCurrentStreak => 'روزهای پیاپی فعلی';

  @override
  String get statsLongestStreak => 'طولانی‌ترین زنجیره';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز',
    );
    return '$_temp0';
  }

  @override
  String get statsRecentDays => 'پاسخ‌ها در ۱۴ روز اخیر';

  @override
  String get statsEmptyBody =>
      'آمار تمرین از پاسخ‌هایی ساخته می‌شود که در تمرین ثبت می‌کنید. هنوز پاسخی ثبت نشده است.';

  @override
  String get statsPolicy =>
      'فقط پاسخ‌هایی شمرده می‌شوند که پس از نمایش پاسخ ثبت کرده‌اید؛ باز کردن برنامه یا یک لغت شمرده نمی‌شود. هر روز طبق ساعت همین دستگاه از نیمه‌شب تا نیمه‌شب است. زنجیره تا وقتی ادامه دارد که دیروز یا امروز تمرین کرده باشید. این آمار به معنای به‌خاطرسپاری همیشگی نیست.';

  @override
  String get practiceScheduledNote =>
      'مرور زمان‌بندی‌شده: فقط کارت‌هایی که موعدشان رسیده نمایش داده می‌شوند و هر پاسخ، زمان مرور بعدی را با الگوریتم FSRS تعیین می‌کند. لغت‌های جدید طبق سقف روزانهٔ هر دسته اضافه می‌شوند.';

  @override
  String get practiceFreeMode => 'تمرین آزاد (زمان‌بندی تغییر نمی‌کند)';

  @override
  String get practicePromptMeaning => 'معنی این لغت آلمانی چیست؟';

  @override
  String get practiceEmptyDueTitle => 'فعلاً کارتی برای مرور نیست';

  @override
  String get practiceEmptyDueBody =>
      'همهٔ کارت‌های موعددار مرور شده‌اند و کارت‌های بعدی در زمان خودشان برمی‌گردند. می‌توانید بدون تغییر زمان‌بندی، تمرین آزاد کنید.';

  @override
  String get practiceFreeInstead => 'تمرین آزاد';

  @override
  String get practiceScheduledDone => 'زمان مرور بعدی هر کارت ذخیره شد.';

  @override
  String get reviewDirectionTitle => 'جهت مرور';

  @override
  String get reviewDirectionGermanToPersian => 'آلمانی ← فارسی';

  @override
  String get reviewDirectionPersianToGerman => 'فارسی ← آلمانی';

  @override
  String get reviewDirectionBoth => 'هر دو جهت';

  @override
  String get reviewDirectionBothNote =>
      'هر لغت دو کارت جدا با زمان‌بندی مستقل دارد. هر لغت در هر روز فقط در یک جهت پرسیده می‌شود؛ اول جهتی که موعدش زودتر است (در کارت‌های جدید، آلمانی ← فارسی).';

  @override
  String get reviewStart => 'شروع مرور';

  @override
  String reviewDueCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString کارت برای مرور',
      zero: 'فعلاً کارتی برای مرور نیست',
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
      other: '$countString کارت',
    );
    return '$_temp0';
  }

  @override
  String get deckShowMeanings => 'نمایش معنی‌ها';

  @override
  String get deckHideMeanings => 'پنهان کردن معنی‌ها';

  @override
  String selectionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString انتخاب‌شده',
    );
    return '$_temp0';
  }

  @override
  String get selectionSelectAll => 'انتخاب همه';

  @override
  String get selectionClear => 'لغو همهٔ انتخاب‌ها';

  @override
  String get selectionExit => 'خروج از حالت انتخاب';

  @override
  String get selectionDelete => 'حذف انتخاب‌شده‌ها';

  @override
  String bulkDeleteTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString لغت حذف شود؟',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteBody =>
      'معنی‌ها، برچسب‌ها و زمان‌بندی مرور این لغت‌ها هم حذف می‌شوند. پاسخ‌های ثبت‌شده برای آمار باقی می‌مانند. این کار برگشت‌پذیر نیست.';

  @override
  String bulkDeleted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString لغت حذف شد',
    );
    return '$_temp0';
  }

  @override
  String get scanViewImage => 'انتخاب روی عکس';

  @override
  String get scanViewText => 'نمایش متن';

  @override
  String get scanImageHint =>
      'روی لغت بزنید تا انتخاب شود. برای چند لغت پشت سر هم، روی اولی نگه دارید و تا آخری بکشید. با دو انگشت بزرگ‌نمایی کنید.';

  @override
  String get scanPageImageLabel => 'عکس صفحه';

  @override
  String get scanRegionMode => 'انتخاب ناحیه';

  @override
  String get scanRegionHint =>
      'دور متنی که درست خوانده نشده یک کادر بکشید تا دوباره خوانده شود.';

  @override
  String get scanRegionTitle => 'متن ناحیهٔ انتخاب‌شده';

  @override
  String get scanRegionHelper =>
      'در صورت نیاز اصلاح کنید؛ فقط همین متن اضافه می‌شود.';

  @override
  String get scanRegionAdd => 'افزودن';

  @override
  String get scanRegionEmpty =>
      'در این ناحیه متنی پیدا نشد. کادر بزرگ‌تری بکشید.';

  @override
  String get scanRegionFailed => 'خواندن این ناحیه ممکن نشد. دوباره تلاش کنید.';

  @override
  String get scanSplitWords => 'جدا کردن به لغت‌های تکی';

  @override
  String get scanRemoveSelection => 'حذف از انتخاب';
}
