import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/features/lists/presentation/lists_screen.dart';
import 'package:listyb/di/stream_providers.dart';
import 'package:listyb/domain/entities/yb_list.dart';

void main() {
  testWidgets('App smoke test: renders ListsScreen title', (
    WidgetTester tester,
  ) async {
    // Переопределяем источники данных на мгновенные:
    final overrides = <Override>[
      listsStreamProvider.overrideWith((ref) async* {
        // пустой список — мгновенная отдача
        yield <YbList>[];
      }),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: ListsScreen()),
      ),
    );

    // Достаточно одного кадра (или небольшого таймаута, если хочешь):
    await tester.pump();

    // Проверяем наличие заголовка экрана списков
    expect(find.text('ListYB — Lists'), findsOneWidget);
  });
}
