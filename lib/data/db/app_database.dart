import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('ListEntity')
class Lists extends Table {
  @override
  String get tableName => 'lists';

  IntColumn get id => integer().named('id').autoIncrement()();
  TextColumn get title => text().named('title')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get archivedAt => dateTime().named('archived_at').nullable()();
}

/// Индексы описываем декларативно аннотациями TableIndex.
/// Генератор Drift создаст:
///  - CREATE INDEX idx_items_list ON items(list_id)
///  - CREATE INDEX idx_items_list_completed ON items(list_id, completed)
///  - CREATE INDEX idx_items_list_position  ON items(list_id, position)
@TableIndex(name: 'idx_items_list', columns: {#listId})
@TableIndex(name: 'idx_items_list_completed', columns: {#listId, #completed})
@TableIndex(name: 'idx_items_list_position', columns: {#listId, #position})
@DataClassName('ItemEntity')
class Items extends Table {
  @override
  String get tableName => 'items';

  IntColumn get id => integer().named('id').autoIncrement()();

  IntColumn get listId => integer()
      .named('list_id')
      .references(Lists, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text().named('title')();
  TextColumn get note => text().named('note').nullable()();

  BoolColumn get completed =>
      boolean().named('completed').withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get dueAt => dateTime().named('due_at').nullable()();

  IntColumn get position =>
      integer().named('position').withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Lists, Items], daos: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 -> v1: ничего
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory(); // path_provider
    final file = File('${dir.path}/listyb.db');
    return NativeDatabase.createInBackground(file);
  });
}
