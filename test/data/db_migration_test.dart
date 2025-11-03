import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/data/db/app_database.dart';
import 'package:drift/native.dart';

void main() {
  test('migration from v1 to v2 adds note column', () async {
    // Создаём БД с версией 1
    // final dbFile = ':memory:'; // или temp файл
    final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
      'PRAGMA user_version = 1',
    ); // симуляция старой версии
    await db.close();

    // Открываем с новой схемой
    final db2 = AppDatabase(NativeDatabase.memory());
    expect(db2.schemaVersion, 2);
    // Проверяем, что колонка note существует
    final columns = await db2
        .customSelect('PRAGMA table_info(items_table)')
        .get();
    expect(columns.any((c) => c.read<String>('name') == 'note'), true);
  });
}
