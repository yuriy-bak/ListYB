import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'daos/lists_dao.dart';
import 'daos/items_dao.dart';

part 'app_database.g.dart';

class ListsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ItemsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId =>
      integer().references(ListsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [ListsTable, ItemsTable], daos: [ListsDao, ItemsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  // ИМЕНОВАННЫЙ КОНСТРУКТОР ДЛЯ ТЕСТОВ:
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll(); // для новой установки
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // Добавляем колонку note в items_table
        await m.addColumn(itemsTable, itemsTable.note);
      }
    },
    beforeOpen: (details) async {
      // Можно включить foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

// опционально, утилита для in-memory
AppDatabase makeInMemoryDb() => AppDatabase(NativeDatabase.memory());
