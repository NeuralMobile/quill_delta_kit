import 'package:test/test.dart';

import '../_helpers.dart';

/// HTML -> Delta -> HTML idempotence tests for canonical inputs.
/// Emits the same canonical HTML from a normalized Delta.
void main() {
  final c = frag();

  group('HTML -> Delta -> HTML idempotence', () {
    void rt(String html, String expected) {
      final delta = c.decode(html);
      final out = c.encode(delta);
      expect(out, expected, reason: 'delta=${delta.toJson()}');
    }

    test('paragraph', () => rt('<p>x</p>', '<p>x</p>'));
    test('h1', () => rt('<h1>x</h1>', '<h1>x</h1>'));
    test(
        'bold + italic',
        () => rt('<p><strong><em>x</em></strong></p>',
            '<p><strong><em>x</em></strong></p>'));

    test('CKEditor todo -> Quill canonical', () {
      const ck = '<ul class="todo-list"><li><label class="todo-list__label">'
          '<input type="checkbox" checked><span class="todo-list__label__description">x</span>'
          '</label></li></ul>';
      final delta = c.decode(ck);
      final out = c.encode(delta);
      expect(out, contains('<ul'));
      expect(out, contains('data-list="checked"'));
      expect(out, contains('>x</li></ul>'));
    });

    test('TipTap heading', () => rt('<h2>Title</h2>', '<h2>Title</h2>'));

    test('mention CKEditor -> Quill canonical', () {
      const html =
          '<p><span class="mention" data-mention="@Alice">@Alice</span></p>';
      final out = c.encode(c.decode(html));
      expect(out, contains('class="mention"'));
      expect(out, contains('data-mention-value="Alice"'));
      expect(out, contains('@Alice'));
    });
  });
}
