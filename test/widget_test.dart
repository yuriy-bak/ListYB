import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:listyb/app/router.dart';

void main() {
  testWidgets('App smoke test: renders ListsScreen title', (
    WidgetTester tester,
  ) async {
    // Поднимаем приложение с роутером и провайдерами
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: appRouter)),
    );

    // Для тестовой среды достаточно тикнуть пару кадров.
    await tester.pump(); // первый кадр
    await tester.pump(const Duration(milliseconds: 50)); // второй тик

    // Подправь строку под фактический заголовок, если отличается.
    // Здесь проверяем, что хоть какой-то текст с "List" отрисовался.
    expect(find.textContaining('List'), findsWidgets);
  });
}
