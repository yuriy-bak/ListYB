import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/app/deeplink_parser.dart';

void main() {
  group('parseDeepLink — supported patterns', () {
    test('list/<id> (scheme with host): listyb://list/42', () {
      final cmd = parseDeepLink(Uri.parse('listyb://list/42'));
      expect(cmd, isA<OpenListCmd>());
      expect((cmd as OpenListCmd).listId, 42);
    });

    test('list/<id>/add (scheme with host): listyb://list/7/add', () {
      final cmd = parseDeepLink(Uri.parse('listyb://list/7/add'));
      expect(cmd, isA<QuickAddCmd>());
      expect((cmd as QuickAddCmd).listId, 7);
    });

    test('item/<id>/edit (scheme with host): listyb://item/9/edit', () {
      final cmd = parseDeepLink(Uri.parse('listyb://item/9/edit'));
      expect(cmd, isA<QuickEditCmd>());
      expect((cmd as QuickEditCmd).itemId, 9);
    });

    test('list/<id> (single slash): listyb:/list/123', () {
      final cmd = parseDeepLink(Uri.parse('listyb:/list/123'));
      expect(cmd, isA<OpenListCmd>());
      expect((cmd as OpenListCmd).listId, 123);
    });

    test('list/<id>/add (single slash): listyb:/list/55/add', () {
      final cmd = parseDeepLink(Uri.parse('listyb:/list/55/add'));
      expect(cmd, isA<QuickAddCmd>());
      expect((cmd as QuickAddCmd).listId, 55);
    });

    test('item/<id>/edit (single slash): listyb:/item/808/edit', () {
      final cmd = parseDeepLink(Uri.parse('listyb:/item/808/edit'));
      expect(cmd, isA<QuickEditCmd>());
      expect((cmd as QuickEditCmd).itemId, 808);
    });
  });

  group('parseDeepLink — invalid patterns', () {
    test('invalid scheme', () {
      expect(parseDeepLink(Uri.parse('http://list/1')), isNull);
      expect(parseDeepLink(Uri.parse('myapp://list/1')), isNull);
    });

    test('missing segments', () {
      expect(parseDeepLink(Uri.parse('listyb:')), isNull); // пусто
      expect(parseDeepLink(Uri.parse('listyb://list')), isNull); // нет id
      expect(parseDeepLink(Uri.parse('listyb:/list')), isNull); // нет id
      expect(parseDeepLink(Uri.parse('listyb://item')), isNull); // нет id/edit
      expect(parseDeepLink(Uri.parse('listyb:/item')), isNull); // нет id/edit
    });

    test('non-numeric ids', () {
      expect(parseDeepLink(Uri.parse('listyb://list/NaN')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/list/abc/add')), isNull);
      expect(parseDeepLink(Uri.parse('listyb://item/xx/edit')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/item/xyz/edit')), isNull);
    });

    test('unknown head segments', () {
      expect(parseDeepLink(Uri.parse('listyb://unknown/1')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/unknown/1')), isNull);
    });

    test('extra unexpected segments', () {
      // list/<id>/add/extra — лишний сегмент
      expect(parseDeepLink(Uri.parse('listyb://list/1/add/extra')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/list/1/add/extra')), isNull);

      // item/<id>/edit/extra — лишний сегмент
      expect(parseDeepLink(Uri.parse('listyb://item/2/edit/extra')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/item/2/edit/extra')), isNull);

      // неподдерживаемое действие
      expect(parseDeepLink(Uri.parse('listyb://list/3/remove')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/list/3/remove')), isNull);
    });

    test('empty/space ids or query/fragment present', () {
      expect(parseDeepLink(Uri.parse('listyb://list/')), isNull);
      expect(parseDeepLink(Uri.parse('listyb:/list/')), isNull);
      expect(parseDeepLink(Uri.parse('listyb://item/%20/edit')), isNull);

      // проверим, что query/fragment тоже отсекаются
      expect(parseDeepLink(Uri.parse('listyb://list/1?x=1')), isNull);
      expect(parseDeepLink(Uri.parse('listyb://list/1#frag')), isNull);
    });
  });
}
