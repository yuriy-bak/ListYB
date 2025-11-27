import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/features/lists/presentation/list_share_import.dart';

void main() {
  group('parseShareMarkdown', () {
    test('Импорт одного элемента с чекбоксом', () {
      const markdown = '- [x] Done item';
      final result = parseShareMarkdown(markdown);
      expect(result.items.length, 1);
      expect(result.items.first.title, 'Done item');
      expect(result.items.first.isDone, true);
    });

    test('Импорт нескольких элементов с чекбоксами', () {
      const markdown = '- [ ] First\n\n- [x] Second\n\n- [ ] Third';
      final result = parseShareMarkdown(markdown);
      expect(result.items.length, 3);
      expect(result.items[0].title, 'First');
      expect(result.items[1].title, 'Second');
      expect(result.items[2].title, 'Third');
      expect(result.items[1].isDone, true);
    });

    test('Импорт элементов без чекбоксов (абзацы)', () {
      const markdown = 'First paragraph\n\nSecond paragraph';
      final result = parseShareMarkdown(markdown);
      expect(result.items.length, 2);
      expect(result.items[0].title, 'First paragraph');
      expect(result.items[1].title, 'Second paragraph');
      expect(result.items[0].isDone, false);
    });

    test('Импорт с заголовком списка', () {
      const markdown = '# My List\n- [ ] Item 1\n- [x] Item 2';
      final result = parseShareMarkdown(markdown);
      expect(result.hasTitle, true);
      expect(result.title, 'My List');
      expect(result.items.length, 2);
    });

    test('Ошибка при нескольких заголовках', () {
      const markdown = '# List 1\n- [ ] Item\n\n# List 2\n- [ ] Another';
      final result = parseShareMarkdown(markdown);
      expect(result.hasMultipleLists, true);
    });
  });
}
