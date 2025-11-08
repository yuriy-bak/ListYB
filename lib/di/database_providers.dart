import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// Твой класс БД:
import 'package:listyb/data/db/app_database.dart'
    as db; // поправь импорт под pubspec name

import 'package:listyb/data/db/daos/items_dao.dart';
import 'package:listyb/data/db/daos/lists_dao.dart';

// Настройка ленивого коннекшена к файлу базы
LazyDatabase _openConnection({String fileName = 'listyb.db'}) {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    return NativeDatabase.createInBackground(file);
  });
}

/// AppDatabase (singleton в рамках ProviderScope)
final appDatabaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase(_openConnection());
});

/// DAO: ItemsDao (есть в репо)
final itemsDaoProvider = Provider<ItemsDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.itemsDao;
});

/// DAO: ListsDao (если у тебя есть отдельный dao/файл — подключи аналогично)
final listsDaoProvider = Provider<ListsDao>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.listsDao; // если геттер называется иначе — поправь
});
