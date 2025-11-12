import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:listyb/app/router.dart';
import 'package:listyb/l10n/l10n_stub.dart';

void main() {
  testWidgets('App smoke test: renders ListsScreen localized title', (
    tester,
  ) async {
    // Поднимаем приложение с реальным роутером и провайдерами
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: appRouter)),
    );

    // Дожидаемся стабилизации анимаций/фреймов
    // Избегаем pumpAndSettle (может не завершаться из‑за Stream'ов/анимаций в тестовой среде)
    // Делаем несколько контролируемых тиков кадра
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Получаем локализованную строку заголовка и проверяем, что она есть в дереве
    final ctx = tester.element(find.byType(Scaffold).first);
    final titleText = L10n.t(ctx, 'home.title');

    expect(find.text(titleText), findsOneWidget);
  });
}
