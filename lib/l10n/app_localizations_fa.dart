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
  String get appTagline => 'از صفحهٔ کتاب تا حافظهٔ ماندگار';

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
  String get dashboardReviewPending =>
      'مرور روزانه با الگوریتم FSRS در نسخه‌های بعدی فعال می‌شود.';

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
  String get sourceCsv => 'فایل CSV';

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
}
