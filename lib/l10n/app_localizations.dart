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
  /// **'از صفحه کتاب تا یادگیری ماندگار'**
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

  /// No description provided for @deckAddWord.
  ///
  /// In fa, this message translates to:
  /// **'افزودن لغت'**
  String get deckAddWord;

  /// No description provided for @deckImportCsv.
  ///
  /// In fa, this message translates to:
  /// **'وارد کردن CSV'**
  String get deckImportCsv;

  /// No description provided for @deckNoEntriesTitle.
  ///
  /// In fa, this message translates to:
  /// **'این دسته هنوز لغتی ندارد'**
  String get deckNoEntriesTitle;

  /// No description provided for @deckNoEntriesBody.
  ///
  /// In fa, this message translates to:
  /// **'لغت‌ها را دستی اضافه کنید یا از یک فایل CSV وارد کنید.'**
  String get deckNoEntriesBody;

  /// No description provided for @searchHint.
  ///
  /// In fa, this message translates to:
  /// **'جستجو در لغت‌ها و معنی‌ها'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In fa, this message translates to:
  /// **'لغتی با این عبارت پیدا نشد.'**
  String get searchNoResults;

  /// No description provided for @entryNoMeaning.
  ///
  /// In fa, this message translates to:
  /// **'بدون معنی'**
  String get entryNoMeaning;

  /// No description provided for @entryMeanings.
  ///
  /// In fa, this message translates to:
  /// **'معنی‌ها'**
  String get entryMeanings;

  /// No description provided for @entryExample.
  ///
  /// In fa, this message translates to:
  /// **'مثال'**
  String get entryExample;

  /// No description provided for @entryGrammar.
  ///
  /// In fa, this message translates to:
  /// **'دستور زبان'**
  String get entryGrammar;

  /// No description provided for @entryLemma.
  ///
  /// In fa, this message translates to:
  /// **'شکل پایه'**
  String get entryLemma;

  /// No description provided for @entryPartOfSpeech.
  ///
  /// In fa, this message translates to:
  /// **'نوع کلمه'**
  String get entryPartOfSpeech;

  /// No description provided for @entryNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get entryNotes;

  /// No description provided for @entrySource.
  ///
  /// In fa, this message translates to:
  /// **'منبع'**
  String get entrySource;

  /// No description provided for @sourceManual.
  ///
  /// In fa, this message translates to:
  /// **'ورود دستی'**
  String get sourceManual;

  /// No description provided for @sourceCsv.
  ///
  /// In fa, this message translates to:
  /// **'فایل CSV'**
  String get sourceCsv;

  /// No description provided for @sourceImage.
  ///
  /// In fa, this message translates to:
  /// **'اسکن کتاب'**
  String get sourceImage;

  /// No description provided for @entryStatus.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت معنی'**
  String get entryStatus;

  /// No description provided for @entryStatusMissing.
  ///
  /// In fa, this message translates to:
  /// **'منتظر معنی'**
  String get entryStatusMissing;

  /// No description provided for @entryStatusPending.
  ///
  /// In fa, this message translates to:
  /// **'در حال تکمیل'**
  String get entryStatusPending;

  /// No description provided for @entryStatusReady.
  ///
  /// In fa, this message translates to:
  /// **'آماده'**
  String get entryStatusReady;

  /// No description provided for @entryStatusFailed.
  ///
  /// In fa, this message translates to:
  /// **'تکمیل ناموفق بود'**
  String get entryStatusFailed;

  /// No description provided for @entryUpdatedOn.
  ///
  /// In fa, this message translates to:
  /// **'آخرین تغییر: {date}'**
  String entryUpdatedOn(DateTime date);

  /// No description provided for @entryNotFound.
  ///
  /// In fa, this message translates to:
  /// **'این لغت پیدا نشد.'**
  String get entryNotFound;

  /// No description provided for @actionEdit.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In fa, this message translates to:
  /// **'حذف'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get actionSave;

  /// No description provided for @actionSaveAndAddAnother.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره و لغت بعدی'**
  String get actionSaveAndAddAnother;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In fa, this message translates to:
  /// **'«{word}» حذف شود؟'**
  String deleteEntryTitle(String word);

  /// No description provided for @deleteEntryBody.
  ///
  /// In fa, this message translates to:
  /// **'این لغت، معنی‌ها و سابقهٔ مرور آن برای همیشه حذف می‌شوند.'**
  String get deleteEntryBody;

  /// No description provided for @entryDeletedMessage.
  ///
  /// In fa, this message translates to:
  /// **'لغت حذف شد.'**
  String get entryDeletedMessage;

  /// No description provided for @formNewEntryTitle.
  ///
  /// In fa, this message translates to:
  /// **'لغت جدید'**
  String get formNewEntryTitle;

  /// No description provided for @formEditEntryTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش لغت'**
  String get formEditEntryTitle;

  /// No description provided for @formDeckLabel.
  ///
  /// In fa, this message translates to:
  /// **'دسته'**
  String get formDeckLabel;

  /// No description provided for @formWordLabel.
  ///
  /// In fa, this message translates to:
  /// **'لغت یا عبارت آلمانی'**
  String get formWordLabel;

  /// No description provided for @formWordHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً sich Mühe geben'**
  String get formWordHint;

  /// No description provided for @formMeaningLabel.
  ///
  /// In fa, this message translates to:
  /// **'معنی {index}'**
  String formMeaningLabel(int index);

  /// No description provided for @formAddMeaning.
  ///
  /// In fa, this message translates to:
  /// **'افزودن معنی دیگر'**
  String get formAddMeaning;

  /// No description provided for @formRemoveMeaning.
  ///
  /// In fa, this message translates to:
  /// **'حذف این معنی'**
  String get formRemoveMeaning;

  /// No description provided for @formMeaningsHelper.
  ///
  /// In fa, this message translates to:
  /// **'اگر معنی را هنوز نمی‌دانید، خالی بگذارید؛ بعداً قابل تکمیل است.'**
  String get formMeaningsHelper;

  /// No description provided for @formMoreDetails.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات بیشتر'**
  String get formMoreDetails;

  /// No description provided for @formExampleLabel.
  ///
  /// In fa, this message translates to:
  /// **'جملهٔ مثال آلمانی'**
  String get formExampleLabel;

  /// No description provided for @formExampleTranslationLabel.
  ///
  /// In fa, this message translates to:
  /// **'ترجمهٔ فارسی مثال'**
  String get formExampleTranslationLabel;

  /// No description provided for @formGrammarLabel.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات دستوری'**
  String get formGrammarLabel;

  /// No description provided for @formGrammarHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً der Tisch, -e'**
  String get formGrammarHint;

  /// No description provided for @formLemmaLabel.
  ///
  /// In fa, this message translates to:
  /// **'شکل پایه'**
  String get formLemmaLabel;

  /// No description provided for @formPartOfSpeechLabel.
  ///
  /// In fa, this message translates to:
  /// **'نوع کلمه'**
  String get formPartOfSpeechLabel;

  /// No description provided for @formPartOfSpeechHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً Nomen یا Verb'**
  String get formPartOfSpeechHint;

  /// No description provided for @formNotesLabel.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get formNotesLabel;

  /// No description provided for @formNoDecks.
  ///
  /// In fa, this message translates to:
  /// **'برای افزودن لغت ابتدا یک دسته بسازید.'**
  String get formNoDecks;

  /// No description provided for @entrySavedMessage.
  ///
  /// In fa, this message translates to:
  /// **'«{word}» ذخیره شد.'**
  String entrySavedMessage(String word);

  /// No description provided for @entryMergedMessage.
  ///
  /// In fa, this message translates to:
  /// **'معنی‌های جدید به «{word}» اضافه شد.'**
  String entryMergedMessage(String word);

  /// No description provided for @errorWordEmpty.
  ///
  /// In fa, this message translates to:
  /// **'لغت آلمانی را وارد کنید.'**
  String get errorWordEmpty;

  /// No description provided for @errorTooLong.
  ///
  /// In fa, this message translates to:
  /// **'حداکثر {max} نویسه مجاز است.'**
  String errorTooLong(int max);

  /// No description provided for @errorTooManyMeanings.
  ///
  /// In fa, this message translates to:
  /// **'حداکثر {max} معنی مجاز است.'**
  String errorTooManyMeanings(int max);

  /// No description provided for @errorDeckNotFound.
  ///
  /// In fa, this message translates to:
  /// **'دستهٔ انتخاب‌شده دیگر وجود ندارد.'**
  String get errorDeckNotFound;

  /// No description provided for @errorEntryNotFound.
  ///
  /// In fa, this message translates to:
  /// **'این لغت دیگر وجود ندارد.'**
  String get errorEntryNotFound;

  /// No description provided for @duplicateRedundantTitle.
  ///
  /// In fa, this message translates to:
  /// **'این لغت قبلاً ذخیره شده'**
  String get duplicateRedundantTitle;

  /// No description provided for @duplicateRedundantBody.
  ///
  /// In fa, this message translates to:
  /// **'«{word}» با همین معنی در این دسته وجود دارد.'**
  String duplicateRedundantBody(String word);

  /// No description provided for @duplicateDifferentTitle.
  ///
  /// In fa, this message translates to:
  /// **'این لغت با معنی دیگری وجود دارد'**
  String get duplicateDifferentTitle;

  /// No description provided for @duplicateDifferentBody.
  ///
  /// In fa, this message translates to:
  /// **'«{word}» در این دسته با این معنی‌ها ذخیره شده است:'**
  String duplicateDifferentBody(String word);

  /// No description provided for @duplicateOpenExisting.
  ///
  /// In fa, this message translates to:
  /// **'نمایش لغت موجود'**
  String get duplicateOpenExisting;

  /// No description provided for @duplicateAddMeanings.
  ///
  /// In fa, this message translates to:
  /// **'افزودن معنی‌ها به لغت موجود'**
  String get duplicateAddMeanings;

  /// No description provided for @duplicateSaveSeparate.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره به‌عنوان لغت جداگانه'**
  String get duplicateSaveSeparate;

  /// No description provided for @duplicateSaveAnyway.
  ///
  /// In fa, this message translates to:
  /// **'در هر صورت ذخیره شود'**
  String get duplicateSaveAnyway;

  /// No description provided for @csvIntro.
  ///
  /// In fa, this message translates to:
  /// **'فایلی با ستون‌هایی مانند word و meaning انتخاب کنید. پیش از ذخیره، همه‌چیز را بررسی می‌کنید.'**
  String get csvIntro;

  /// No description provided for @csvSectionDeck.
  ///
  /// In fa, this message translates to:
  /// **'دستهٔ مقصد'**
  String get csvSectionDeck;

  /// No description provided for @csvSectionFile.
  ///
  /// In fa, this message translates to:
  /// **'فایل'**
  String get csvSectionFile;

  /// No description provided for @csvSectionColumns.
  ///
  /// In fa, this message translates to:
  /// **'ستون‌ها'**
  String get csvSectionColumns;

  /// No description provided for @csvSectionLanguages.
  ///
  /// In fa, this message translates to:
  /// **'زبان‌ها'**
  String get csvSectionLanguages;

  /// No description provided for @csvSectionDuplicates.
  ///
  /// In fa, this message translates to:
  /// **'لغت‌های تکراری'**
  String get csvSectionDuplicates;

  /// No description provided for @csvSectionPreview.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نمایش'**
  String get csvSectionPreview;

  /// No description provided for @csvChooseFile.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب فایل CSV'**
  String get csvChooseFile;

  /// No description provided for @csvChooseAnother.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب فایل دیگر'**
  String get csvChooseAnother;

  /// No description provided for @csvRecordCount.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{{count} ردیف}}'**
  String csvRecordCount(int count);

  /// No description provided for @csvEncoding.
  ///
  /// In fa, this message translates to:
  /// **'کدگذاری: {name}'**
  String csvEncoding(String name);

  /// No description provided for @csvDelimiterLabel.
  ///
  /// In fa, this message translates to:
  /// **'جداکننده'**
  String get csvDelimiterLabel;

  /// No description provided for @csvDelimiterAuto.
  ///
  /// In fa, this message translates to:
  /// **'تشخیص خودکار'**
  String get csvDelimiterAuto;

  /// No description provided for @csvDelimiterComma.
  ///
  /// In fa, this message translates to:
  /// **'ویرگول ( , )'**
  String get csvDelimiterComma;

  /// No description provided for @csvDelimiterSemicolon.
  ///
  /// In fa, this message translates to:
  /// **'نقطه‌ویرگول ( ; )'**
  String get csvDelimiterSemicolon;

  /// No description provided for @csvDelimiterTab.
  ///
  /// In fa, this message translates to:
  /// **'تب'**
  String get csvDelimiterTab;

  /// No description provided for @csvDelimiterPipe.
  ///
  /// In fa, this message translates to:
  /// **'خط عمودی ( | )'**
  String get csvDelimiterPipe;

  /// No description provided for @csvHasHeader.
  ///
  /// In fa, this message translates to:
  /// **'ردیف اول شامل نام ستون‌هاست'**
  String get csvHasHeader;

  /// No description provided for @csvColumnLabel.
  ///
  /// In fa, this message translates to:
  /// **'ستون {index}'**
  String csvColumnLabel(int index);

  /// No description provided for @csvFieldIgnore.
  ///
  /// In fa, this message translates to:
  /// **'نادیده گرفته شود'**
  String get csvFieldIgnore;

  /// No description provided for @csvFieldOriginal.
  ///
  /// In fa, this message translates to:
  /// **'لغت آلمانی'**
  String get csvFieldOriginal;

  /// No description provided for @csvFieldMeaning.
  ///
  /// In fa, this message translates to:
  /// **'معنی فارسی'**
  String get csvFieldMeaning;

  /// No description provided for @csvFieldLemma.
  ///
  /// In fa, this message translates to:
  /// **'شکل پایه'**
  String get csvFieldLemma;

  /// No description provided for @csvFieldPartOfSpeech.
  ///
  /// In fa, this message translates to:
  /// **'نوع کلمه'**
  String get csvFieldPartOfSpeech;

  /// No description provided for @csvFieldExample.
  ///
  /// In fa, this message translates to:
  /// **'جملهٔ مثال'**
  String get csvFieldExample;

  /// No description provided for @csvFieldExampleTranslation.
  ///
  /// In fa, this message translates to:
  /// **'ترجمهٔ مثال'**
  String get csvFieldExampleTranslation;

  /// No description provided for @csvFieldGrammar.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات دستوری'**
  String get csvFieldGrammar;

  /// No description provided for @csvFieldNotes.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get csvFieldNotes;

  /// No description provided for @csvMappingNeedsWord.
  ///
  /// In fa, this message translates to:
  /// **'یک ستون را به «لغت آلمانی» اختصاص دهید.'**
  String get csvMappingNeedsWord;

  /// No description provided for @csvMeaningSplitHint.
  ///
  /// In fa, this message translates to:
  /// **'چند معنی در یک خانه را می‌توان با ؛ یا | جدا کرد.'**
  String get csvMeaningSplitHint;

  /// No description provided for @csvLanguagesConfirm.
  ///
  /// In fa, this message translates to:
  /// **'تأیید می‌کنم که لغت‌ها به زبان {source} و معنی‌ها به زبان {definition} هستند.'**
  String csvLanguagesConfirm(String source, String definition);

  /// No description provided for @csvLanguagesSwapped.
  ///
  /// In fa, this message translates to:
  /// **'به نظر می‌رسد ستون لغت فارسی و ستون معنی آلمانی است.'**
  String get csvLanguagesSwapped;

  /// No description provided for @csvSwapColumns.
  ///
  /// In fa, this message translates to:
  /// **'جابه‌جا کردن ستون‌ها'**
  String get csvSwapColumns;

  /// No description provided for @csvStrategySkip.
  ///
  /// In fa, this message translates to:
  /// **'رد کردن لغت‌های موجود'**
  String get csvStrategySkip;

  /// No description provided for @csvStrategySkipDescription.
  ///
  /// In fa, this message translates to:
  /// **'اگر لغت در دسته یا در ردیف‌های قبلی فایل باشد، وارد نمی‌شود.'**
  String get csvStrategySkipDescription;

  /// No description provided for @csvStrategyMerge.
  ///
  /// In fa, this message translates to:
  /// **'افزودن معنی‌های تازه به لغت موجود'**
  String get csvStrategyMerge;

  /// No description provided for @csvStrategyMergeDescription.
  ///
  /// In fa, this message translates to:
  /// **'فقط معنی‌ها و خانه‌های خالی اضافه می‌شوند؛ چیزی بازنویسی نمی‌شود.'**
  String get csvStrategyMergeDescription;

  /// No description provided for @csvStrategySeparate.
  ///
  /// In fa, this message translates to:
  /// **'لغت جداگانه برای معنی متفاوت'**
  String get csvStrategySeparate;

  /// No description provided for @csvStrategySeparateDescription.
  ///
  /// In fa, this message translates to:
  /// **'اگر معنی متفاوت باشد، لغت جداگانه‌ای ساخته می‌شود.'**
  String get csvStrategySeparateDescription;

  /// No description provided for @csvStrategyNote.
  ///
  /// In fa, this message translates to:
  /// **'ردیف‌هایی که معنی تازه‌ای ندارند همیشه رد می‌شوند.'**
  String get csvStrategyNote;

  /// No description provided for @csvCountNew.
  ///
  /// In fa, this message translates to:
  /// **'{count} جدید'**
  String csvCountNew(int count);

  /// No description provided for @csvCountMerge.
  ///
  /// In fa, this message translates to:
  /// **'{count} ادغام'**
  String csvCountMerge(int count);

  /// No description provided for @csvCountSkip.
  ///
  /// In fa, this message translates to:
  /// **'{count} تکراری'**
  String csvCountSkip(int count);

  /// No description provided for @csvCountError.
  ///
  /// In fa, this message translates to:
  /// **'{count} خطا'**
  String csvCountError(int count);

  /// No description provided for @csvRowLine.
  ///
  /// In fa, this message translates to:
  /// **'خط {line}'**
  String csvRowLine(int line);

  /// No description provided for @csvRowNew.
  ///
  /// In fa, this message translates to:
  /// **'جدید'**
  String get csvRowNew;

  /// No description provided for @csvRowMerge.
  ///
  /// In fa, this message translates to:
  /// **'افزودن معنی به لغت موجود'**
  String get csvRowMerge;

  /// No description provided for @csvRowMergeInFile.
  ///
  /// In fa, this message translates to:
  /// **'افزودن معنی به خط {line}'**
  String csvRowMergeInFile(int line);

  /// No description provided for @csvRowRedundant.
  ///
  /// In fa, this message translates to:
  /// **'تکراری — رد می‌شود'**
  String get csvRowRedundant;

  /// No description provided for @csvRowRedundantInFile.
  ///
  /// In fa, this message translates to:
  /// **'تکرار خط {line} — رد می‌شود'**
  String csvRowRedundantInFile(int line);

  /// No description provided for @csvRowExists.
  ///
  /// In fa, this message translates to:
  /// **'لغت موجود — رد می‌شود'**
  String get csvRowExists;

  /// No description provided for @csvRowExistsInFile.
  ///
  /// In fa, this message translates to:
  /// **'لغت در خط {line} آمده — رد می‌شود'**
  String csvRowExistsInFile(int line);

  /// No description provided for @csvRowIssueMissingWord.
  ///
  /// In fa, this message translates to:
  /// **'لغت آلمانی خالی است'**
  String get csvRowIssueMissingWord;

  /// No description provided for @csvRowIssueWordTooLong.
  ///
  /// In fa, this message translates to:
  /// **'لغت بیش از حد طولانی است'**
  String get csvRowIssueWordTooLong;

  /// No description provided for @csvRowIssueMeaningTooLong.
  ///
  /// In fa, this message translates to:
  /// **'معنی بیش از حد طولانی است'**
  String get csvRowIssueMeaningTooLong;

  /// No description provided for @csvRowIssueTooManyMeanings.
  ///
  /// In fa, this message translates to:
  /// **'تعداد معنی‌ها بیش از حد است'**
  String get csvRowIssueTooManyMeanings;

  /// No description provided for @csvRowIssueFieldTooLong.
  ///
  /// In fa, this message translates to:
  /// **'یکی از خانه‌ها بیش از حد طولانی است'**
  String get csvRowIssueFieldTooLong;

  /// No description provided for @csvErrorsTitle.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{{count} ردیف خطا دارد و وارد نمی‌شود}}'**
  String csvErrorsTitle(int count);

  /// No description provided for @csvMoreRows.
  ///
  /// In fa, this message translates to:
  /// **'و {count} ردیف دیگر'**
  String csvMoreRows(int count);

  /// No description provided for @csvImportButton.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{وارد کردن {count} ردیف}}'**
  String csvImportButton(int count);

  /// No description provided for @csvNothingToImport.
  ///
  /// In fa, this message translates to:
  /// **'ردیفی برای وارد کردن وجود ندارد.'**
  String get csvNothingToImport;

  /// No description provided for @csvImportDone.
  ///
  /// In fa, this message translates to:
  /// **'وارد کردن انجام شد'**
  String get csvImportDone;

  /// No description provided for @csvResultCreated.
  ///
  /// In fa, this message translates to:
  /// **'{count} لغت جدید ساخته شد'**
  String csvResultCreated(int count);

  /// No description provided for @csvResultMerged.
  ///
  /// In fa, this message translates to:
  /// **'{count} ردیف به لغت‌های موجود اضافه شد'**
  String csvResultMerged(int count);

  /// No description provided for @csvResultSkipped.
  ///
  /// In fa, this message translates to:
  /// **'{count} ردیف تکراری رد شد'**
  String csvResultSkipped(int count);

  /// No description provided for @csvResultErrors.
  ///
  /// In fa, this message translates to:
  /// **'{count} ردیف به دلیل خطا وارد نشد'**
  String csvResultErrors(int count);

  /// No description provided for @csvViewDeck.
  ///
  /// In fa, this message translates to:
  /// **'مشاهدهٔ دسته'**
  String get csvViewDeck;

  /// No description provided for @csvImportAnother.
  ///
  /// In fa, this message translates to:
  /// **'وارد کردن فایل دیگر'**
  String get csvImportAnother;

  /// No description provided for @csvImportFailed.
  ///
  /// In fa, this message translates to:
  /// **'وارد کردن انجام نشد و هیچ تغییری ذخیره نشد. دوباره تلاش کنید.'**
  String get csvImportFailed;

  /// No description provided for @csvFormatEmpty.
  ///
  /// In fa, this message translates to:
  /// **'فایل خالی است.'**
  String get csvFormatEmpty;

  /// No description provided for @csvFormatTooLarge.
  ///
  /// In fa, this message translates to:
  /// **'فایل بزرگ‌تر از {max} مگابایت است.'**
  String csvFormatTooLarge(int max);

  /// No description provided for @csvFormatTooManyRows.
  ///
  /// In fa, this message translates to:
  /// **'فایل بیش از {max} ردیف دارد.'**
  String csvFormatTooManyRows(int max);

  /// No description provided for @csvFormatEncoding.
  ///
  /// In fa, this message translates to:
  /// **'کدگذاری فایل پشتیبانی نمی‌شود. فایل را با کدگذاری UTF-8 ذخیره کنید.'**
  String get csvFormatEncoding;

  /// No description provided for @csvFormatUnterminatedQuote.
  ///
  /// In fa, this message translates to:
  /// **'علامت نقل‌قول در خط {line} بسته نشده است.'**
  String csvFormatUnterminatedQuote(int line);

  /// No description provided for @csvFormatNoDataRows.
  ///
  /// In fa, this message translates to:
  /// **'فایل هیچ ردیف داده‌ای ندارد.'**
  String get csvFormatNoDataRows;

  /// No description provided for @csvFileReadFailed.
  ///
  /// In fa, this message translates to:
  /// **'فایل خوانده نشد. دوباره تلاش کنید.'**
  String get csvFileReadFailed;

  /// No description provided for @scanTitle.
  ///
  /// In fa, this message translates to:
  /// **'اسکن صفحهٔ کتاب'**
  String get scanTitle;

  /// No description provided for @scanIntro.
  ///
  /// In fa, this message translates to:
  /// **'از یک صفحهٔ آلمانی عکس بگیرید یا عکسی انتخاب کنید. متن روی همین دستگاه خوانده می‌شود و عکس جایی فرستاده نمی‌شود.'**
  String get scanIntro;

  /// No description provided for @scanOcrWarning.
  ///
  /// In fa, this message translates to:
  /// **'تشخیص متن ممکن است اشتباه کند؛ پیش از ذخیره، لغت‌ها را بررسی و اصلاح کنید.'**
  String get scanOcrWarning;

  /// No description provided for @scanTakePhoto.
  ///
  /// In fa, this message translates to:
  /// **'گرفتن عکس'**
  String get scanTakePhoto;

  /// No description provided for @scanChoosePhoto.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب از گالری'**
  String get scanChoosePhoto;

  /// No description provided for @scanTypeText.
  ///
  /// In fa, this message translates to:
  /// **'تایپ یا چسباندن متن'**
  String get scanTypeText;

  /// No description provided for @scanRecognizing.
  ///
  /// In fa, this message translates to:
  /// **'در حال خواندن متن…'**
  String get scanRecognizing;

  /// No description provided for @scanErrorCameraPermission.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی به دوربین داده نشده است. در تنظیمات دستگاه اجازه دهید یا عکسی از گالری انتخاب کنید.'**
  String get scanErrorCameraPermission;

  /// No description provided for @scanErrorPhotoPermission.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی به عکس‌ها داده نشده است. در تنظیمات دستگاه اجازه دهید یا از دوربین استفاده کنید.'**
  String get scanErrorPhotoPermission;

  /// No description provided for @scanErrorCameraUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'دوربین در دسترس نیست.'**
  String get scanErrorCameraUnavailable;

  /// No description provided for @scanErrorUnsupportedFormat.
  ///
  /// In fa, this message translates to:
  /// **'این قالب تصویر پشتیبانی نمی‌شود. از JPG، PNG، HEIC یا WebP استفاده کنید.'**
  String get scanErrorUnsupportedFormat;

  /// No description provided for @scanErrorTooLarge.
  ///
  /// In fa, this message translates to:
  /// **'تصویر بیش از حد بزرگ است.'**
  String get scanErrorTooLarge;

  /// No description provided for @scanErrorUnreadable.
  ///
  /// In fa, this message translates to:
  /// **'تصویر خوانده نشد.'**
  String get scanErrorUnreadable;

  /// No description provided for @scanErrorOcrUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'تشخیص متن روی این دستگاه در دسترس نیست. می‌توانید متن را تایپ کنید.'**
  String get scanErrorOcrUnavailable;

  /// No description provided for @scanErrorOcrFailed.
  ///
  /// In fa, this message translates to:
  /// **'خواندن متن انجام نشد. دوباره تلاش کنید یا متن را تایپ کنید.'**
  String get scanErrorOcrFailed;

  /// No description provided for @scanNoTextTitle.
  ///
  /// In fa, this message translates to:
  /// **'متنی پیدا نشد'**
  String get scanNoTextTitle;

  /// No description provided for @scanNoTextBody.
  ///
  /// In fa, this message translates to:
  /// **'عکس واضح‌تری بگیرید یا متن را تایپ کنید.'**
  String get scanNoTextBody;

  /// No description provided for @scanTryAgain.
  ///
  /// In fa, this message translates to:
  /// **'عکس دیگر'**
  String get scanTryAgain;

  /// No description provided for @scanTypedHint.
  ///
  /// In fa, this message translates to:
  /// **'متن آلمانی را اینجا تایپ یا جای‌گذاری کنید'**
  String get scanTypedHint;

  /// No description provided for @scanUseText.
  ///
  /// In fa, this message translates to:
  /// **'استفاده از این متن'**
  String get scanUseText;

  /// No description provided for @scanSelectHint.
  ///
  /// In fa, this message translates to:
  /// **'روی لغت‌ها بزنید تا انتخاب شوند. برای عبارت چندکلمه‌ای، حالت «عبارت» را بزنید و سپس روی اولین و آخرین لغت بزنید.'**
  String get scanSelectHint;

  /// No description provided for @scanModeWord.
  ///
  /// In fa, this message translates to:
  /// **'لغت'**
  String get scanModeWord;

  /// No description provided for @scanModeExpression.
  ///
  /// In fa, this message translates to:
  /// **'عبارت'**
  String get scanModeExpression;

  /// No description provided for @scanExpressionPickEnd.
  ///
  /// In fa, this message translates to:
  /// **'حالا روی آخرین لغت عبارت بزنید.'**
  String get scanExpressionPickEnd;

  /// No description provided for @scanExpressionTooLong.
  ///
  /// In fa, this message translates to:
  /// **'عبارت باید در یک پاراگراف و حداکثر {max} لغت باشد.'**
  String scanExpressionTooLong(int max);

  /// No description provided for @scanSelectedCount.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, =0{هیچ لغتی انتخاب نشده} other{{count} مورد انتخاب شده}}'**
  String scanSelectedCount(int count);

  /// No description provided for @scanClearSelection.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن انتخاب‌ها'**
  String get scanClearSelection;

  /// No description provided for @scanEditText.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح متن'**
  String get scanEditText;

  /// No description provided for @scanEditTextTitle.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح متن تشخیص‌داده‌شده'**
  String get scanEditTextTitle;

  /// No description provided for @scanSelectionsDropped.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{{count} انتخاب به‌دلیل تغییر متن حذف شد.}}'**
  String scanSelectionsDropped(int count);

  /// No description provided for @scanReviewButton.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{بررسی {count} مورد}}'**
  String scanReviewButton(int count);

  /// No description provided for @scanReviewTitle.
  ///
  /// In fa, this message translates to:
  /// **'بررسی پیش از ذخیره'**
  String get scanReviewTitle;

  /// No description provided for @scanReviewIntro.
  ///
  /// In fa, this message translates to:
  /// **'فقط موارد این فهرست ذخیره می‌شوند. اشتباه‌های تشخیص را اصلاح کنید.'**
  String get scanReviewIntro;

  /// No description provided for @scanItemWord.
  ///
  /// In fa, this message translates to:
  /// **'لغت یا عبارت آلمانی'**
  String get scanItemWord;

  /// No description provided for @scanItemContext.
  ///
  /// In fa, this message translates to:
  /// **'جملهٔ اصلی'**
  String get scanItemContext;

  /// No description provided for @scanItemLemma.
  ///
  /// In fa, this message translates to:
  /// **'شکل پایه (اختیاری)'**
  String get scanItemLemma;

  /// No description provided for @scanItemMeaning.
  ///
  /// In fa, this message translates to:
  /// **'معنی فارسی (اختیاری)'**
  String get scanItemMeaning;

  /// No description provided for @scanItemRemove.
  ///
  /// In fa, this message translates to:
  /// **'حذف از فهرست'**
  String get scanItemRemove;

  /// No description provided for @scanLemmaHint.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد شکل پایه: {base}'**
  String scanLemmaHint(String base);

  /// No description provided for @scanLemmaHintNote.
  ///
  /// In fa, this message translates to:
  /// **'از فهرست داخلی افعال بی‌قاعده؛ لطفاً بررسی کنید.'**
  String get scanLemmaHintNote;

  /// No description provided for @scanUseHint.
  ///
  /// In fa, this message translates to:
  /// **'استفاده'**
  String get scanUseHint;

  /// No description provided for @scanStatusNew.
  ///
  /// In fa, this message translates to:
  /// **'جدید'**
  String get scanStatusNew;

  /// No description provided for @scanStatusRedundant.
  ///
  /// In fa, this message translates to:
  /// **'در این دسته وجود دارد — ذخیره نمی‌شود'**
  String get scanStatusRedundant;

  /// No description provided for @scanStatusRedundantInList.
  ///
  /// In fa, this message translates to:
  /// **'تکراری در همین فهرست — ذخیره نمی‌شود'**
  String get scanStatusRedundantInList;

  /// No description provided for @scanStatusExists.
  ///
  /// In fa, this message translates to:
  /// **'لغت با معنی دیگری وجود دارد — ذخیره نمی‌شود'**
  String get scanStatusExists;

  /// No description provided for @scanStatusMerge.
  ///
  /// In fa, this message translates to:
  /// **'معنی به لغت موجود اضافه می‌شود'**
  String get scanStatusMerge;

  /// No description provided for @scanStatusInvalid.
  ///
  /// In fa, this message translates to:
  /// **'لغت خالی است'**
  String get scanStatusInvalid;

  /// No description provided for @scanSaveButton.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, =0{چیزی برای ذخیره نیست} other{ذخیرهٔ {count} مورد}}'**
  String scanSaveButton(int count);

  /// No description provided for @scanSavedTitle.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره شد'**
  String get scanSavedTitle;

  /// No description provided for @scanScanAnother.
  ///
  /// In fa, this message translates to:
  /// **'اسکن صفحهٔ دیگر'**
  String get scanScanAnother;

  /// No description provided for @scanBackToText.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت به متن'**
  String get scanBackToText;

  /// No description provided for @scanSaveFailed.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره انجام نشد و هیچ تغییری اعمال نشد. دوباره تلاش کنید.'**
  String get scanSaveFailed;

  /// No description provided for @scanResultCreated.
  ///
  /// In fa, this message translates to:
  /// **'{count} لغت جدید ذخیره شد'**
  String scanResultCreated(int count);

  /// No description provided for @scanResultMerged.
  ///
  /// In fa, this message translates to:
  /// **'معنی {count} مورد به لغت‌های موجود اضافه شد'**
  String scanResultMerged(int count);

  /// No description provided for @scanResultSkipped.
  ///
  /// In fa, this message translates to:
  /// **'{count} مورد تکراری ذخیره نشد'**
  String scanResultSkipped(int count);

  /// Settings row opening the license page (app dependencies and bundled fonts).
  ///
  /// In fa, this message translates to:
  /// **'مجوزهای نرم‌افزار و فونت‌ها'**
  String get settingsLicenses;

  /// Screen-reader hint for an unselected word on the scanned page.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب لغت'**
  String get scanWordTapToSelect;

  /// Screen-reader hint for a selected word on the scanned page.
  ///
  /// In fa, this message translates to:
  /// **'لغو انتخاب'**
  String get scanWordTapToDeselect;

  /// No description provided for @settingsAi.
  ///
  /// In fa, this message translates to:
  /// **'هوش مصنوعی'**
  String get settingsAi;

  /// No description provided for @settingsAiConfigured.
  ///
  /// In fa, this message translates to:
  /// **'فعال — کلید OpenRouter شما ذخیره شده است'**
  String get settingsAiConfigured;

  /// No description provided for @settingsAiNotConfigured.
  ///
  /// In fa, this message translates to:
  /// **'غیرفعال — کلید OpenRouter تنظیم نشده'**
  String get settingsAiNotConfigured;

  /// No description provided for @aiSettingsTitle.
  ///
  /// In fa, this message translates to:
  /// **'هوش مصنوعی'**
  String get aiSettingsTitle;

  /// No description provided for @aiIntroTitle.
  ///
  /// In fa, this message translates to:
  /// **'با حساب OpenRouter خودتان'**
  String get aiIntroTitle;

  /// No description provided for @aiIntroBody.
  ///
  /// In fa, this message translates to:
  /// **'برای پیشنهاد معنی، مثال و نکات دستوری، AI WortBox از حساب OpenRouter خود شما استفاده می‌کند. هزینهٔ هر درخواست از اعتبار حساب OpenRouter شما کم می‌شود. AI WortBox کلید یا حساب مشترکی ندارد و بدون کلید شما هیچ درخواستی نمی‌فرستد.'**
  String get aiIntroBody;

  /// No description provided for @aiGetKey.
  ///
  /// In fa, this message translates to:
  /// **'دریافت کلید در openrouter.ai/keys'**
  String get aiGetKey;

  /// No description provided for @aiKeyLabel.
  ///
  /// In fa, this message translates to:
  /// **'کلید API'**
  String get aiKeyLabel;

  /// No description provided for @aiKeyNewLabel.
  ///
  /// In fa, this message translates to:
  /// **'کلید API جدید'**
  String get aiKeyNewLabel;

  /// No description provided for @aiKeyShow.
  ///
  /// In fa, this message translates to:
  /// **'نمایش کلید'**
  String get aiKeyShow;

  /// No description provided for @aiKeyHide.
  ///
  /// In fa, this message translates to:
  /// **'پنهان کردن کلید'**
  String get aiKeyHide;

  /// No description provided for @aiKeySave.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره و بررسی'**
  String get aiKeySave;

  /// No description provided for @aiKeySaved.
  ///
  /// In fa, this message translates to:
  /// **'کلید ذخیره‌شده: ••••{suffix}'**
  String aiKeySaved(String suffix);

  /// No description provided for @aiKeySavedNote.
  ///
  /// In fa, this message translates to:
  /// **'کلید کامل دیگر نمایش داده نمی‌شود.'**
  String get aiKeySavedNote;

  /// No description provided for @aiKeyTest.
  ///
  /// In fa, this message translates to:
  /// **'بررسی کلید'**
  String get aiKeyTest;

  /// No description provided for @aiKeyReplace.
  ///
  /// In fa, this message translates to:
  /// **'جایگزینی کلید'**
  String get aiKeyReplace;

  /// No description provided for @aiKeyRemove.
  ///
  /// In fa, this message translates to:
  /// **'حذف کلید'**
  String get aiKeyRemove;

  /// No description provided for @aiKeyRemoveTitle.
  ///
  /// In fa, this message translates to:
  /// **'کلید حذف شود؟'**
  String get aiKeyRemoveTitle;

  /// No description provided for @aiKeyRemoveBody.
  ///
  /// In fa, this message translates to:
  /// **'کلید از حافظهٔ امن این دستگاه حذف می‌شود. لغت‌ها و معنی‌های ذخیره‌شده دست نمی‌خورند. کلید در حساب OpenRouter شما همچنان فعال است؛ برای باطل کردن آن به openrouter.ai بروید.'**
  String get aiKeyRemoveBody;

  /// No description provided for @aiKeyRemoved.
  ///
  /// In fa, this message translates to:
  /// **'کلید حذف شد.'**
  String get aiKeyRemoved;

  /// No description provided for @aiKeySaveFailed.
  ///
  /// In fa, this message translates to:
  /// **'کلید در فضای امن این دستگاه ذخیره نشد. دوباره تلاش کنید.'**
  String get aiKeySaveFailed;

  /// No description provided for @aiKeyRemoveFailed.
  ///
  /// In fa, this message translates to:
  /// **'کلید از فضای امن این دستگاه حذف نشد. دوباره تلاش کنید.'**
  String get aiKeyRemoveFailed;

  /// No description provided for @aiModelSaveFailed.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب مدل ذخیره نشد. دوباره تلاش کنید.'**
  String get aiModelSaveFailed;

  /// No description provided for @aiKeyProblemEmpty.
  ///
  /// In fa, this message translates to:
  /// **'کلید را وارد کنید.'**
  String get aiKeyProblemEmpty;

  /// No description provided for @aiKeyProblemWhitespace.
  ///
  /// In fa, this message translates to:
  /// **'کلید نباید فاصله یا خط جدید داشته باشد.'**
  String get aiKeyProblemWhitespace;

  /// No description provided for @aiKeyProblemShort.
  ///
  /// In fa, this message translates to:
  /// **'این کلید خیلی کوتاه است.'**
  String get aiKeyProblemShort;

  /// No description provided for @aiKeyProblemLong.
  ///
  /// In fa, this message translates to:
  /// **'این کلید خیلی بلند است.'**
  String get aiKeyProblemLong;

  /// No description provided for @aiCheckRunning.
  ///
  /// In fa, this message translates to:
  /// **'در حال بررسی کلید…'**
  String get aiCheckRunning;

  /// No description provided for @aiCheckPassed.
  ///
  /// In fa, this message translates to:
  /// **'کلید معتبر است و هوش مصنوعی آماده است.'**
  String get aiCheckPassed;

  /// No description provided for @aiCheckUsage.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار مصرف‌شده با این کلید (گزارش OpenRouter): {amount} دلار'**
  String aiCheckUsage(String amount);

  /// No description provided for @aiCheckRemaining.
  ///
  /// In fa, this message translates to:
  /// **'باقی‌ماندهٔ سقف این کلید: {amount} دلار'**
  String aiCheckRemaining(String amount);

  /// No description provided for @aiCheckModelUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'مدل انتخاب‌شده اکنون در OpenRouter با خروجی ساختاریافته در دسترس نیست. مدل دیگری انتخاب کنید.'**
  String get aiCheckModelUnavailable;

  /// No description provided for @aiCheckModelUnknown.
  ///
  /// In fa, this message translates to:
  /// **'فهرست مدل‌ها بارگیری نشد؛ در دسترس بودن مدل بررسی نشد.'**
  String get aiCheckModelUnknown;

  /// No description provided for @aiModelLabel.
  ///
  /// In fa, this message translates to:
  /// **'مدل'**
  String get aiModelLabel;

  /// No description provided for @aiModelHelper.
  ///
  /// In fa, this message translates to:
  /// **'فهرستی منتخب از مدل‌های کم‌هزینه که خروجی ساختاریافته دارند. قیمت‌ها در openrouter.ai آمده است.'**
  String get aiModelHelper;

  /// No description provided for @aiPrivacyTitle.
  ///
  /// In fa, this message translates to:
  /// **'حریم خصوصی و اتصال'**
  String get aiPrivacyTitle;

  /// No description provided for @aiPrivacyBody.
  ///
  /// In fa, this message translates to:
  /// **'فقط وقتی شما درخواست کنید، لغت، جملهٔ آن و معنی‌های فعلی‌اش به OpenRouter و ارائه‌دهندهٔ مدل فرستاده می‌شود. این متن از دستگاه خارج می‌شود و سیاست‌های آن‌ها بر آن اعمال می‌شود. پیشنهاد هوش مصنوعی به اینترنت نیاز دارد؛ بقیهٔ برنامه بدون اینترنت کار می‌کند.'**
  String get aiPrivacyBody;

  /// No description provided for @aiSecurityTitle.
  ///
  /// In fa, this message translates to:
  /// **'نگهداری کلید'**
  String get aiSecurityTitle;

  /// No description provided for @aiSecurityBody.
  ///
  /// In fa, this message translates to:
  /// **'کلید در حافظهٔ امن سیستم (Keychain در iOS، Keystore در اندروید) نگه داشته می‌شود؛ هرگز نمایش داده نمی‌شود و در پایگاه داده، گزارش‌ها یا پشتیبان قرار نمی‌گیرد. این کار خطر را کم می‌کند، اما روی دستگاهی آلوده یا دستکاری‌شده، استخراج کلید ناممکن نیست. در OpenRouter برای این کلید سقف اعتبار تعیین کنید.'**
  String get aiSecurityBody;

  /// No description provided for @enrichTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهادهای هوش مصنوعی'**
  String get enrichTitle;

  /// No description provided for @enrichAction.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد هوش مصنوعی'**
  String get enrichAction;

  /// No description provided for @enrichDeckAction.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد برای لغت‌های بدون معنی'**
  String get enrichDeckAction;

  /// No description provided for @enrichNotConfiguredTitle.
  ///
  /// In fa, this message translates to:
  /// **'هوش مصنوعی تنظیم نشده است'**
  String get enrichNotConfiguredTitle;

  /// No description provided for @enrichNotConfiguredBody.
  ///
  /// In fa, this message translates to:
  /// **'کلید API حساب OpenRouter خودتان را در تنظیمات وارد کنید. بدون کلید هیچ درخواستی فرستاده نمی‌شود.'**
  String get enrichNotConfiguredBody;

  /// No description provided for @enrichOpenSettings.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات هوش مصنوعی'**
  String get enrichOpenSettings;

  /// No description provided for @enrichEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'لغتی برای تکمیل نیست'**
  String get enrichEmptyTitle;

  /// No description provided for @enrichEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'فقط لغت‌های بدون معنی گروهی پیشنهاد می‌گیرند. برای لغتی که معنی دارد، از صفحهٔ همان لغت درخواست کنید.'**
  String get enrichEmptyBody;

  /// No description provided for @enrichReadyBatch.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{{count} لغت بدون معنی به OpenRouter فرستاده می‌شود.}} پیش از ذخیره، همهٔ پیشنهادها را بررسی می‌کنید.'**
  String enrichReadyBatch(int count);

  /// No description provided for @enrichReadySingle.
  ///
  /// In fa, this message translates to:
  /// **'این لغت و جملهٔ آن به OpenRouter فرستاده می‌شود. معنی‌ها و اطلاعات فعلی بدون تأیید شما تغییر نمی‌کنند.'**
  String get enrichReadySingle;

  /// No description provided for @enrichModel.
  ///
  /// In fa, this message translates to:
  /// **'مدل: {model}'**
  String enrichModel(String model);

  /// No description provided for @enrichStart.
  ///
  /// In fa, this message translates to:
  /// **'دریافت پیشنهادها'**
  String get enrichStart;

  /// No description provided for @enrichProgress.
  ///
  /// In fa, this message translates to:
  /// **'{done} از {total}'**
  String enrichProgress(int done, int total);

  /// No description provided for @enrichCancel.
  ///
  /// In fa, this message translates to:
  /// **'توقف'**
  String get enrichCancel;

  /// No description provided for @enrichStatusQueued.
  ///
  /// In fa, this message translates to:
  /// **'در صف'**
  String get enrichStatusQueued;

  /// No description provided for @enrichStatusRunning.
  ///
  /// In fa, this message translates to:
  /// **'در حال دریافت…'**
  String get enrichStatusRunning;

  /// No description provided for @enrichStatusProposed.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد هوش مصنوعی — بررسی کنید'**
  String get enrichStatusProposed;

  /// No description provided for @enrichStatusFailed.
  ///
  /// In fa, this message translates to:
  /// **'ناموفق'**
  String get enrichStatusFailed;

  /// No description provided for @enrichStatusSkipped.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد تازه‌ای نبود'**
  String get enrichStatusSkipped;

  /// No description provided for @enrichNewMeanings.
  ///
  /// In fa, this message translates to:
  /// **'معنی‌های پیشنهادی'**
  String get enrichNewMeanings;

  /// No description provided for @enrichExistingKept.
  ///
  /// In fa, this message translates to:
  /// **'معنی‌های فعلی دست نمی‌خورند؛ موارد انتخاب‌شده اضافه می‌شوند.'**
  String get enrichExistingKept;

  /// No description provided for @enrichDetails.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات پیشنهادی'**
  String get enrichDetails;

  /// No description provided for @enrichReplaces.
  ///
  /// In fa, this message translates to:
  /// **'به جای: {current}'**
  String enrichReplaces(String current);

  /// No description provided for @enrichAmbiguous.
  ///
  /// In fa, this message translates to:
  /// **'بدون جملهٔ کامل‌تر، معنی قطعی نیست؛ با دقت بررسی کنید.'**
  String get enrichAmbiguous;

  /// No description provided for @enrichSave.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{ذخیرهٔ {count} لغت}}'**
  String enrichSave(int count);

  /// No description provided for @enrichNothingSelected.
  ///
  /// In fa, this message translates to:
  /// **'چیزی برای ذخیره انتخاب نشده است.'**
  String get enrichNothingSelected;

  /// No description provided for @enrichRetry.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره برای موارد ناموفق'**
  String get enrichRetry;

  /// No description provided for @enrichSavedTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهادها ذخیره شد'**
  String get enrichSavedTitle;

  /// No description provided for @enrichSavedCount.
  ///
  /// In fa, this message translates to:
  /// **'{count, plural, other{{count} لغت به‌روز شد}}'**
  String enrichSavedCount(int count);

  /// No description provided for @enrichCost.
  ///
  /// In fa, this message translates to:
  /// **'هزینهٔ گزارش‌شده توسط OpenRouter: {amount} دلار'**
  String enrichCost(String amount);

  /// No description provided for @enrichConflict.
  ///
  /// In fa, this message translates to:
  /// **'برخی لغت‌ها در این فاصله تغییر کرده‌اند، پس چیزی ذخیره نشد. دوباره پیشنهاد بگیرید.'**
  String get enrichConflict;

  /// No description provided for @aiErrorNotConfigured.
  ///
  /// In fa, this message translates to:
  /// **'کلید OpenRouter تنظیم نشده است.'**
  String get aiErrorNotConfigured;

  /// No description provided for @aiErrorInvalidKey.
  ///
  /// In fa, this message translates to:
  /// **'OpenRouter این کلید را نپذیرفت. کلید را بررسی یا جایگزین کنید.'**
  String get aiErrorInvalidKey;

  /// No description provided for @aiErrorCredits.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار حساب یا سقف این کلید در OpenRouter تمام شده است. در openrouter.ai اعتبار اضافه کنید.'**
  String get aiErrorCredits;

  /// No description provided for @aiErrorForbidden.
  ///
  /// In fa, this message translates to:
  /// **'OpenRouter یا ارائه‌دهندهٔ مدل این درخواست را رد کرد.'**
  String get aiErrorForbidden;

  /// No description provided for @aiErrorRateLimited.
  ///
  /// In fa, this message translates to:
  /// **'تعداد درخواست‌ها زیاد است. کمی بعد دوباره امتحان کنید.'**
  String get aiErrorRateLimited;

  /// No description provided for @aiErrorTimeout.
  ///
  /// In fa, this message translates to:
  /// **'پاسخ به‌موقع نرسید. ممکن است OpenRouter درخواست را پردازش کرده و هزینه‌اش را حساب کرده باشد؛ فقط در صورت نیاز دوباره امتحان کنید.'**
  String get aiErrorTimeout;

  /// No description provided for @aiErrorNetwork.
  ///
  /// In fa, this message translates to:
  /// **'اتصال به اینترنت برقرار نیست. پیشنهاد هوش مصنوعی به اینترنت نیاز دارد.'**
  String get aiErrorNetwork;

  /// No description provided for @aiErrorModel.
  ///
  /// In fa, this message translates to:
  /// **'مدل انتخاب‌شده در دسترس نیست. مدل دیگری در تنظیمات انتخاب کنید.'**
  String get aiErrorModel;

  /// No description provided for @aiErrorBadRequest.
  ///
  /// In fa, this message translates to:
  /// **'OpenRouter درخواست را نپذیرفت. مدل دیگری را امتحان کنید.'**
  String get aiErrorBadRequest;

  /// No description provided for @aiErrorServer.
  ///
  /// In fa, this message translates to:
  /// **'OpenRouter خطا داد. کمی بعد دوباره امتحان کنید.'**
  String get aiErrorServer;

  /// No description provided for @aiErrorMalformed.
  ///
  /// In fa, this message translates to:
  /// **'پاسخ مدل قابل استفاده نبود. دوباره امتحان کنید یا مدل دیگری انتخاب کنید.'**
  String get aiErrorMalformed;

  /// No description provided for @aiErrorCancelled.
  ///
  /// In fa, this message translates to:
  /// **'متوقف شد.'**
  String get aiErrorCancelled;
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
