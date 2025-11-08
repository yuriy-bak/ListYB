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

    // Дождёмся первого кадра
    await tester.pumpAndSettle();

    // Ожидание заголовка домашнего экрана (замени на точный текст, если он у тебя другой)
    expect(find.textContaining('List'), findsWidgets);
  });
}
