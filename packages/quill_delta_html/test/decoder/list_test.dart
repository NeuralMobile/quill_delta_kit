import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('list decoder', () {
    test('bullet list', () {
      expect(c.decode('<ul><li>a</li><li>b</li></ul>').toJson(), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'}
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'}
        }
      ]);
    });

    test('ordered list', () {
      expect(c.decode('<ol><li>a</li></ol>').toJson(), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        }
      ]);
    });

    test('checked via Quill data-checked', () {
      expect(c.decode('<ul data-checked="true"><li>a</li></ul>').toJson(), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'}
        }
      ]);
    });

    test('checked via per-li data-list (TipTap-ish)', () {
      expect(
        c.decode('<ul data-checked="false"><li data-list="checked">a</li></ul>').toJson(),
        [
          {'insert': 'a'},
          {
            'insert': '\n',
            'attributes': {'list': 'checked'}
          }
        ],
      );
    });

    test('CKEditor todo list', () {
      const ck = '<ul class="todo-list"><li><label class="todo-list__label">'
          '<input type="checkbox" checked><span class="todo-list__label__description">a</span>'
          '</label></li></ul>';
      expect(c.decode(ck).toJson(), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'}
        }
      ]);
    });

    test('TipTap task list', () {
      const tip = '<ul data-type="taskList"><li data-type="taskItem" data-checked="true">'
          '<label><input type="checkbox" checked></label><div>a</div></li></ul>';
      expect(c.decode(tip).toJson(), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'}
        }
      ]);
    });

    test('nested list -> indent', () {
      const html = '<ol><li>a<ol><li>b</li></ol></li><li>c</li></ol>';
      expect(c.decode(html).toJson(), [
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered', 'indent': 1}
        },
        {'insert': 'c'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        }
      ]);
    });
  });
}
