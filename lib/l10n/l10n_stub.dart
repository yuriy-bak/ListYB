// lib/l10n/l10n_stub.dart
import 'package:flutter/widgets.dart';

class L10n {
  static String t(BuildContext context, String key) {
    // Минимальная карта для R1-04. На R1-06 заменим на arb/intl.
    const ru = <String, String>{
      'app.title': 'ListYB',
      'common.ok': 'ОК',
      'common.cancel': 'Отмена',
      'common.delete': 'Удалить',
      'common.edit': 'Изменить',
      'common.save': 'Сохранить',
      'common.search': 'Поиск',
      'common.settings': 'Настройки',

      'list.create': 'Создать список',
      'list.rename': 'Переименовать',
      'list.archive': 'Архивировать',
      'list.unarchive': 'Разархивировать',
      'list.delete': 'Удалить',
      'list.empty': 'Нет списков — создайте первый',

      'snackbar.list_deleted': 'Список удалён',
      'snackbar.list_archived': 'Список архивирован',
      'snackbar.undo': 'Отменить',
    };
    return ru[key] ?? key;
  }
}
