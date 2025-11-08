// test/drift/migrations/migration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:listyb/data/db/app_database.dart' as db;

void main() {
  test('migration preserves data', () async {
    // Запуск старой версии схемы — если используешь step-by-step, drift генерит утилиты и тест‑скелет
    final database = db.AppDatabase(NativeDatabase.memory());

    // TODO: засидить старые данные, если нужно проверить перенос
    // await database.into(database.items).insert(...);

    // Закрытие и повторное открытие с новой версией (или вызов onUpgrade в in‑memory)
    await database.close();
    final db2 = db.AppDatabase(NativeDatabase.memory());

    // Проверки инвариантов
    // final items = await db2.select(db2.items).get();
    // expect(items, isNotEmpty);
    await db2.close();
  });
}
