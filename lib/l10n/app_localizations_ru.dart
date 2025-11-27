// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ListYB';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonEdit => 'Редактировать';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonSearch => 'Поиск';

  @override
  String get commonSettings => 'Настройки';

  @override
  String get listCreate => 'Создать список';

  @override
  String get listRename => 'Переименовать список';

  @override
  String get listArchive => 'Архивировать';

  @override
  String get listUnarchive => 'Разархивировать';

  @override
  String get listDelete => 'Удалить список';

  @override
  String get listEmpty => 'Нет списков — создайте первый';

  @override
  String get itemsAddPlaceholder => 'Новый элемент…';

  @override
  String get itemsFilterAll => 'Все';

  @override
  String get itemsFilterOpen => 'Открытые';

  @override
  String get itemsFilterDone => 'Выполненные';

  @override
  String get itemsEmpty => 'Нет элементов — добавьте первый';

  @override
  String get snackbarCreated => 'Создано';

  @override
  String get snackbarUpdated => 'Обновлено';

  @override
  String get snackbarDeleted => 'Удалено';

  @override
  String get snackbarListDeleted => 'Список удалён';

  @override
  String get snackbarListArchived => 'Список архивирован';

  @override
  String get snackbarItemDeleted => 'Элемент удалён';

  @override
  String get snackbarItemArchived => 'Элемент архивирован';

  @override
  String get snackbarUndo => 'Отменить';

  @override
  String get errorGeneric => 'Что-то пошло не так';

  @override
  String get errorValidationTitleEmpty => 'Название не может быть пустым';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Системный';

  @override
  String get settingsLanguageRu => 'Русский';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get aboutLicense => 'MIT License';
}
