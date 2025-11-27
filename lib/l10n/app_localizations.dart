import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('ru'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ListYB'**
  String get appTitle;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @listCreate.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get listCreate;

  /// No description provided for @listRename.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get listRename;

  /// No description provided for @listArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get listArchive;

  /// No description provided for @listUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get listUnarchive;

  /// No description provided for @listDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get listDelete;

  /// No description provided for @listEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lists — create the first one'**
  String get listEmpty;

  /// No description provided for @itemsAddPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New item...'**
  String get itemsAddPlaceholder;

  /// No description provided for @itemsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get itemsFilterAll;

  /// No description provided for @itemsFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get itemsFilterOpen;

  /// No description provided for @itemsFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get itemsFilterDone;

  /// No description provided for @itemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items — add the first one'**
  String get itemsEmpty;

  /// No description provided for @snackbarCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get snackbarCreated;

  /// No description provided for @snackbarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get snackbarUpdated;

  /// No description provided for @snackbarDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get snackbarDeleted;

  /// No description provided for @snackbarListDeleted.
  ///
  /// In en, this message translates to:
  /// **'List deleted'**
  String get snackbarListDeleted;

  /// No description provided for @snackbarListArchived.
  ///
  /// In en, this message translates to:
  /// **'List archived'**
  String get snackbarListArchived;

  /// No description provided for @snackbarItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get snackbarItemDeleted;

  /// No description provided for @snackbarItemArchived.
  ///
  /// In en, this message translates to:
  /// **'Item archived'**
  String get snackbarItemArchived;

  /// No description provided for @snackbarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get snackbarUndo;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorValidationTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get errorValidationTitleEmpty;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageRu.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get settingsLanguageRu;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @aboutLicense.
  ///
  /// In en, this message translates to:
  /// **'MIT License'**
  String get aboutLicense;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
