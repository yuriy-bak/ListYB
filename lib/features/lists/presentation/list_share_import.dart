// lib/features/lists/presentation/list_share_import.dart
import 'package:listyb/domain/entities/yb_item.dart';

/// Генерация Markdown для экспорта списка
///
/// Формат:
///   # <Название списка>
///   - [ ] <элемент   - [x] <выполненный элемент>///   - [ ] <элемент>
///   * [ ] <элемент>
///   * [x] <выполненный элемент>
String generateShareMarkdownText(String listTitle, List<YbItem> items) {
  final buffer = StringBuffer();
  buffer.writeln('# $listTitle\n');
  for (final item in items) {
    final status = item.isDone ? '[x]' : '[ ]';
    buffer.writeln('- $status ${item.title}');
  }
  return buffer.toString();
}

/// Итог разбора Markdown для импорта.
class MarkdownImportResult {
  final String? title;
  final int headerCount;
  final List<MarkdownItem> items;
  const MarkdownImportResult({
    required this.title,
    required this.headerCount,
    required this.items,
  });

  bool get hasMultipleLists => headerCount > 1;
  bool get hasTitle => title != null && title!.trim().isNotEmpty;
}

/// Модель импортируемого элемента.
class MarkdownItem {
  final String title;
  final bool isDone;
  const MarkdownItem({required this.title, required this.isDone});
}

/// Разбор Markdown в структуру для импорта.
///
/// Правила:
/// - Заголовок списка: строка вида `# Title` (до 3 ведущих пробелов допускается).
/// - Элемент = **абзац**: непрерывная группа непустых строк, отделённая пустой строкой.
/// - Если в абзаце есть чекбокс `[...]`, то он определяет статус (x/X → done, пробел → open).
/// - Если чекбокса нет, но абзац начинается с маркера `-` или `*`, это **невыполненный** элемент.
/// - Если чекбокса нет и нет маркера, это тоже элемент со статусом **невыполнено**.
/// - Если встречается **несколько заголовков** `# ...`, это несколько списков → вызывающая сторона должна
///   показать ошибку и **не импортировать**.
MarkdownImportResult parseShareMarkdown(String markdown) {
  final lines = markdown.split('\n');

  final headerRe = RegExp(r'^\s{0,3}#\s+(.*)$'); // "# Title"
  final checkboxAnyRe = RegExp(r'\[(x|X|\s)\]'); // "[x]" / "[ ]" где угодно
  final bulletWithCheckboxRe = RegExp(
    r'^\s*[-*]\s*\[(x|X|\s)\]\s*(.+)$',
  ); // "- [x] text" / "* [ ] text"
  final bulletNoCheckboxRe = RegExp(r'^\s*[-*]\s+(.+)$'); // "- text" / "* text"
  final leadingBulletOrCheckboxRe = RegExp(
    r'^\s*[-*]\s*(\[(x|X|\s)\])?\s*',
  ); // Префикс для удаления в тексте

  String? title;
  var headerCount = 0;
  final items = <MarkdownItem>[];

  // Текущий абзац
  final current = <String>[];

  void flushParagraph() {
    if (current.isEmpty) return;
    // Собираем текст абзаца
    final rawText = current.join(' ').trimRight();
    if (rawText.trim().isEmpty) {
      current.clear();
      return;
    }

    bool isDone = false;
    String text = rawText;

    // Если весь абзац — маркерный пункт
    final first = current.first.trimRight();
    final m1 = bulletWithCheckboxRe.firstMatch(first);
    if (m1 != null) {
      final mark = (m1.group(1) ?? ' ').toLowerCase();
      isDone = mark == 'x';
      text = m1.group(2)?.trim() ?? '';
    } else {
      // Без чекбокса, но с маркером "- ..." / "* ..."
      final m2 = bulletNoCheckboxRe.firstMatch(first);
      if (m2 != null) {
        isDone = false;
        text = (m2.group(1) ?? '').trim();
      } else {
        // В тексте абзаца может встретиться чекбокс где-нибудь внутри
        final any = checkboxAnyRe.firstMatch(rawText);
        if (any != null) {
          isDone = (any.group(1)?.toLowerCase() == 'x');
        }
        // Удаляем ведущие маркеры/чекбокс, если они есть
        text = rawText.replaceFirst(leadingBulletOrCheckboxRe, '').trim();
        // И убираем случайные чекбоксы внутри тела
        text = text.replaceAll(checkboxAnyRe, '').trim();
      }
    }

    if (text.isNotEmpty) {
      items.add(MarkdownItem(title: text, isDone: isDone));
    }
    current.clear();
  }

  for (final raw in lines) {
    final line = raw.trimRight();

    // Заголовок
    final h = headerRe.firstMatch(line);
    if (h != null) {
      flushParagraph();
      headerCount += 1;
      title ??= h.group(1)?.trim();
      continue;
    }

    // Пустая строка — конец абзаца
    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    // Иначе — часть абзаца
    current.add(line);
  }
  flushParagraph();

  return MarkdownImportResult(
    title: title,
    headerCount: headerCount,
    items: items,
  );
}
