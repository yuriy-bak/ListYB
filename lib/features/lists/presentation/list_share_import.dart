import 'package:listyb/domain/entities/yb_item.dart';

/// Генерация Markdown для экспорта списка
String generateShareMarkdownText(String listTitle, List<YbItem> items) {
  final buffer = StringBuffer();
  buffer.writeln('# $listTitle\n');
  for (final item in items) {
    final status = item.isDone ? '[x]' : '[ ]';
    buffer.writeln('- $status ${item.title}');
  }
  return buffer.toString();
}

/// Результат разбора Markdown
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

class MarkdownItem {
  final String title;
  final bool isDone;
  const MarkdownItem({required this.title, required this.isDone});
}

/// Парсер Markdown → список
MarkdownImportResult parseShareMarkdown(String markdown) {
  final normalized = markdown.replaceAll('\r\n', '\n');
  final lines = normalized.split('\n');

  final headerRe = RegExp(r'^\s{0,3}#\s+(.*)$');
  final checkboxAnyRe = RegExp(r'\[(x|X|\s)\]');
  final bulletWithCheckboxRe = RegExp(r'^\s*[-*]\s*\[(x|X|\s)\]\s*(.+)$');
  final bulletNoCheckboxRe = RegExp(r'^\s*[-*]\s+(.+)$');
  final leadingBulletOrCheckboxRe = RegExp(r'^\s*[-*]\s*(\[(x|X|\s)\])?\s*');

  String? title;
  var headerCount = 0;
  final items = <MarkdownItem>[];

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    // Заголовок
    final h = headerRe.firstMatch(line);
    if (h != null) {
      headerCount++;
      title ??= h.group(1)?.trim();
      continue;
    }

    bool isDone = false;
    String text = line;

    final m1 = bulletWithCheckboxRe.firstMatch(line);
    if (m1 != null) {
      isDone = m1.group(1)!.toLowerCase() == 'x';
      text = m1.group(2)!.trim();
    } else {
      final m2 = bulletNoCheckboxRe.firstMatch(line);
      if (m2 != null) {
        text = m2.group(1)!.trim();
      } else {
        final any = checkboxAnyRe.firstMatch(line);
        if (any != null) {
          isDone = any.group(1)!.toLowerCase() == 'x';
        }
        text = text.replaceFirst(leadingBulletOrCheckboxRe, '').trim();
        text = text.replaceAll(checkboxAnyRe, '').trim();
      }
    }

    if (text.isNotEmpty) {
      items.add(MarkdownItem(title: text, isDone: isDone));
    }
  }

  return MarkdownImportResult(
    title: title,
    headerCount: headerCount,
    items: items,
  );
}
