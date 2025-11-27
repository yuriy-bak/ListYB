// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ListYB';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonSettings => 'Settings';

  @override
  String get listCreate => 'Create list';

  @override
  String get listRename => 'Rename list';

  @override
  String get listArchive => 'Archive';

  @override
  String get listUnarchive => 'Unarchive';

  @override
  String get listDelete => 'Delete list';

  @override
  String get listEmpty => 'No lists — create the first one';

  @override
  String get itemsAddPlaceholder => 'New item...';

  @override
  String get itemsFilterAll => 'All';

  @override
  String get itemsFilterOpen => 'Open';

  @override
  String get itemsFilterDone => 'Done';

  @override
  String get itemsEmpty => 'No items — add the first one';

  @override
  String get snackbarCreated => 'Created';

  @override
  String get snackbarUpdated => 'Updated';

  @override
  String get snackbarDeleted => 'Deleted';

  @override
  String get snackbarListDeleted => 'List deleted';

  @override
  String get snackbarListArchived => 'List archived';

  @override
  String get snackbarItemDeleted => 'Item deleted';

  @override
  String get snackbarItemArchived => 'Item archived';

  @override
  String get snackbarUndo => 'Undo';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorValidationTitleEmpty => 'Title cannot be empty';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageRu => 'Russian';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get aboutLicense => 'MIT License';
}
