import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fa, this message translates to:
  /// **'AI WortBox'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In fa, this message translates to:
  /// **'از صفحهٔ کتاب تا حافظهٔ ماندگار'**
  String get appTagline;

  /// No description provided for @navToday.
  ///
  /// In fa, this message translates to:
  /// **'مرور امروز'**
  String get navToday;

  /// No description provided for @navMyWords.
  ///
  /// In fa, this message translates to:
  /// **'لغات من'**
  String get navMyWords;

  /// No description provided for @navAdd.
  ///
  /// In fa, this message translates to:
  /// **'افزودن لغت'**
  String get navAdd;

  /// No description provided for @navStatistics.
  ///
  /// In fa, this message translates to:
  /// **'آمار'**
  String get navStatistics;

  /// No description provided for @navSettings.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get navSettings;

  /// No description provided for @dashboardDecks.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌ها'**
  String get dashboardDecks;

  /// No description provided for @dashboardWords.
  ///
  /// In fa, this message translates to:
  /// **'لغات'**
  String get dashboardWords;

  /// No description provided for @dashboardReviewPending.
  ///
  /// In fa, this message translates to:
  /// **'مرور روزانه با الگوریتم FSRS در نسخه‌های بعدی فعال می‌شود.'**
  String get dashboardReviewPending;

  /// No description provided for @dashboardYourDecks.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌های شما'**
  String get dashboardYourDecks;

  /// No description provided for @emptyDecksTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز دسته‌ای نساخته‌اید'**
  String get emptyDecksTitle;

  /// No description provided for @emptyDecksBody.
  ///
  /// In fa, this message translates to:
  /// **'برای شروع، یک دستهٔ لغت بسازید. هر دسته زبان‌ها و محدودیت روزانهٔ خودش را دارد.'**
  String get emptyDecksBody;

  /// No description provided for @actionCreateDeck.
  ///
  /// In fa, this message translates to:
  /// **'ساخت دستهٔ جدید'**
  String get actionCreateDeck;

  /// No description provided for @actionCancel.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره'**
  String get actionRetry;

  /// No description provided for @deckWordCount.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, =0{بدون لغت} other{{count} لغت}}'**
  String deckWordCount(int count);

  /// No description provided for @deckLanguagePair.
  ///
  /// In fa, this message translates to:
  /// **'{source} ← {definition}'**
  String deckLanguagePair(String source, String definition);

  /// No description provided for @deckDailyLimit.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, =0{بدون کارت جدید} other{حداکثر {count} کارت جدید در روز}}'**
  String deckDailyLimit(int count);

  /// No description provided for @deckCreatedOn.
  ///
  /// In fa, this message translates to:
  /// **'ساخته‌شده در {date}'**
  String deckCreatedOn(DateTime date);

  /// No description provided for @deckNotFound.
  ///
  /// In fa, this message translates to:
  /// **'این دسته پیدا نشد.'**
  String get deckNotFound;

  /// No description provided for @deckEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'این دسته هنوز لغتی ندارد. افزودن لغت در مرحلهٔ بعد فعال می‌شود.'**
  String get deckEmptyBody;

  /// No description provided for @createDeckTitle.
  ///
  /// In fa, this message translates to:
  /// **'دستهٔ جدید'**
  String get createDeckTitle;

  /// No description provided for @createDeckNameLabel.
  ///
  /// In fa, this message translates to:
  /// **'نام دسته'**
  String get createDeckNameLabel;

  /// No description provided for @createDeckNameHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً Der Vorleser یا لغات A1'**
  String get createDeckNameHint;

  /// No description provided for @createDeckLanguagesLabel.
  ///
  /// In fa, this message translates to:
  /// **'زبان یادگیری و زبان معنی'**
  String get createDeckLanguagesLabel;

  /// No description provided for @createDeckDailyLimitLabel.
  ///
  /// In fa, this message translates to:
  /// **'تعداد کارت جدید در روز'**
  String get createDeckDailyLimitLabel;

  /// No description provided for @createDeckDailyLimitHelper.
  ///
  /// In fa, this message translates to:
  /// **'از {min} تا {max}؛ صفر یعنی موقتاً کارت جدیدی نشان داده نشود.'**
  String createDeckDailyLimitHelper(int min, int max);

  /// No description provided for @createDeckSubmit.
  ///
  /// In fa, this message translates to:
  /// **'ساختن'**
  String get createDeckSubmit;

  /// No description provided for @deckCreatedMessage.
  ///
  /// In fa, this message translates to:
  /// **'دستهٔ «{name}» ساخته شد.'**
  String deckCreatedMessage(String name);

  /// No description provided for @errorDeckNameEmpty.
  ///
  /// In fa, this message translates to:
  /// **'نام دسته را وارد کنید.'**
  String get errorDeckNameEmpty;

  /// No description provided for @errorDeckNameTooLong.
  ///
  /// In fa, this message translates to:
  /// **'نام دسته حداکثر {max} نویسه می‌تواند باشد.'**
  String errorDeckNameTooLong(int max);

  /// No description provided for @errorDeckNameDuplicate.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌ای با همین نام وجود دارد.'**
  String get errorDeckNameDuplicate;

  /// No description provided for @errorDailyLimitRange.
  ///
  /// In fa, this message translates to:
  /// **'عددی بین {min} و {max} وارد کنید.'**
  String errorDailyLimitRange(int min, int max);

  /// No description provided for @errorInvalidNumber.
  ///
  /// In fa, this message translates to:
  /// **'یک عدد صحیح وارد کنید.'**
  String get errorInvalidNumber;

  /// No description provided for @errorUnsupportedLanguage.
  ///
  /// In fa, this message translates to:
  /// **'این زبان هنوز پشتیبانی نمی‌شود.'**
  String get errorUnsupportedLanguage;

  /// No description provided for @errorIdenticalLanguages.
  ///
  /// In fa, this message translates to:
  /// **'زبان یادگیری و زبان معنی باید متفاوت باشند.'**
  String get errorIdenticalLanguages;

  /// No description provided for @errorStorage.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره‌سازی روی دستگاه با خطا روبه‌رو شد. دوباره تلاش کنید.'**
  String get errorStorage;

  /// No description provided for @errorGeneric.
  ///
  /// In fa, this message translates to:
  /// **'مشکلی پیش آمد. دوباره تلاش کنید.'**
  String get errorGeneric;

  /// No description provided for @addSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'لغت‌ها را از کجا می‌آورید؟'**
  String get addSubtitle;

  /// No description provided for @addImportCsv.
  ///
  /// In fa, this message translates to:
  /// **'وارد کردن فایل CSV'**
  String get addImportCsv;

  /// No description provided for @addImportCsvDescription.
  ///
  /// In fa, this message translates to:
  /// **'فهرست لغت‌هایتان را از یک فایل CSV وارد کنید.'**
  String get addImportCsvDescription;

  /// No description provided for @addManual.
  ///
  /// In fa, this message translates to:
  /// **'افزودن دستی'**
  String get addManual;

  /// No description provided for @addManualDescription.
  ///
  /// In fa, this message translates to:
  /// **'یک لغت یا عبارت آلمانی و معنی آن را بنویسید.'**
  String get addManualDescription;

  /// No description provided for @addScan.
  ///
  /// In fa, this message translates to:
  /// **'اسکن صفحهٔ کتاب'**
  String get addScan;

  /// No description provided for @addScanDescription.
  ///
  /// In fa, this message translates to:
  /// **'از صفحهٔ کتاب عکس بگیرید و لغت‌های دلخواه را انتخاب کنید.'**
  String get addScanDescription;

  /// No description provided for @comingSoon.
  ///
  /// In fa, this message translates to:
  /// **'به‌زودی'**
  String get comingSoon;

  /// No description provided for @statisticsEmpty.
  ///
  /// In fa, this message translates to:
  /// **'آمار یادگیری پس از شروع مرورها نمایش داده می‌شود.'**
  String get statisticsEmpty;

  /// No description provided for @settingsLanguages.
  ///
  /// In fa, this message translates to:
  /// **'زبان‌های پیش‌فرض'**
  String get settingsLanguages;

  /// No description provided for @settingsSourceLanguage.
  ///
  /// In fa, this message translates to:
  /// **'زبان یادگیری'**
  String get settingsSourceLanguage;

  /// No description provided for @settingsDefinitionLanguage.
  ///
  /// In fa, this message translates to:
  /// **'زبان معنی'**
  String get settingsDefinitionLanguage;

  /// No description provided for @settingsPrivacy.
  ///
  /// In fa, this message translates to:
  /// **'حریم خصوصی و ذخیره‌سازی'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In fa, this message translates to:
  /// **'همهٔ داده‌ها فقط روی همین دستگاه ذخیره می‌شوند و نیازی به ثبت‌نام نیست.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsAbout.
  ///
  /// In fa, this message translates to:
  /// **'درباره'**
  String get settingsAbout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
