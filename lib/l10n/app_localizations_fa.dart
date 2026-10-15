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
  String get deckEmptyBody =>
      'این دسته هنوز لغتی ندارد. افزودن لغت در مرحلهٔ بعد فعال می‌شود.';

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
}
