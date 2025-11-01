import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/app/app.dart'; // импортируем наш корневой виджет

void main() {
  testWidgets('App smoke test: renders ListsScreen title', (WidgetTester tester) async {
    // Запускаем приложение
    await tester.pumpWidget(const App());

    // Дождаться первого кадра
    await tester.pumpAndSettle();

    // Проверяем наличие заголовка экрана списков
    expect(find.text('ListYB — Lists'), findsOneWidget);
  });
}