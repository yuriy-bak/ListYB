import 'package:flutter/widgets.dart';

/// Временная заглушка i18n до R1-06.
/// Ключи взяты из docs/i18n/keys.md.
class Strings {
  const Strings._();

  static Strings of(BuildContext _) => const Strings._();

  // Common
  String get commonOk => 'ОК';
  String get commonCancel => 'Отмена';
  String get commonDelete => 'Удалить';
  String get commonEdit => 'Редактировать';
  String get commonSave => 'Сохранить';
  String get commonSearch => 'Поиск…';
  String get commonShare => "Поделиться";

  // Items screen
  String get itemsAddPlaceholder => 'Быстро добавить…';
  String get itemsFilterAll => 'Все';
  String get itemsFilterOpen => 'Открытые';
  String get itemsFilterDone => 'Выполненные';
  String get itemsEmpty => 'Нет элементов — добавьте первый';

  // Snackbars
  String get snackbarItemDeleted => 'Элемент удалён';
  // Архивирование не используем в R1-05
  String get snackbarUndo => 'Отменить';

  // List menu (в AppBar)
  String get listRename => 'Переименовать список';
  String get listArchive => 'Архивировать';
  String get listUnarchive => 'Разархивировать';
  String get listDelete => 'Удалить список';
}
