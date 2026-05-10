import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('list encoder', () {
    test('bullet single', () {
      expect(
        c.encode(deltaOf([
          {'insert': 'a'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}}
        ])),
        '<ul><li>a</li></ul>',
      );
    });

    test('ordered multiple', () {
      expect(
        c.encode(deltaOf([
          {'insert': 'a'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'b'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}}
        ])),
        '<ol><li>a</li><li>b</li></ol>',
      );
    });

    test('checked + unchecked', () {
      final html = c.encode(deltaOf([
        {'insert': 'a'},
        {'insert': '\n', 'attributes': {'list': 'checked'}},
        {'insert': 'b'},
        {'insert': '\n', 'attributes': {'list': 'unchecked'}}
      ]));
      expect(html, contains('data-list="checked"'));
      expect(html, contains('data-list="unchecked"'));
      expect(html, startsWith('<ul'));
    });

    test('nested ordered list', () {
      final html = c.encode(deltaOf([
        {'insert': 'a'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'b'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'c'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}}
      ]));
      expect(html, '<ol><li>a<ol><li>b</li></ol></li><li>c</li></ol>');
    });

    test('switch ul -> ol breaks group', () {
      final html = c.encode(deltaOf([
        {'insert': 'a'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'b'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}}
      ]));
      expect(html, '<ul><li>a</li></ul><ol><li>b</li></ol>');
    });
  });
}
