import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('block decoder', () {
    test('h1', () {
      expect(c.decode('<h1>x</h1>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'header': 1}}
      ]);
    });

    test('blockquote with single child', () {
      expect(c.decode('<blockquote>x</blockquote>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'blockquote': true}}
      ]);
    });

    test('blockquote with nested <p>', () {
      expect(c.decode('<blockquote><p>a</p><p>b</p></blockquote>').toJson(), [
        {'insert': 'a'},
        {'insert': '\n', 'attributes': {'blockquote': true}},
        {'insert': 'b'},
        {'insert': '\n', 'attributes': {'blockquote': true}}
      ]);
    });

    test('pre + code -> code-block', () {
      expect(c.decode('<pre><code>line1\nline2</code></pre>').toJson(), [
        {'insert': 'line1'},
        {'insert': '\n', 'attributes': {'code-block': true}},
        {'insert': 'line2'},
        {'insert': '\n', 'attributes': {'code-block': true}}
      ]);
    });

    test('pre with language class', () {
      expect(c.decode('<pre><code class="language-dart">x</code></pre>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'code-block': 'dart'}}
      ]);
    });

    test('align center via style', () {
      expect(c.decode('<p style="text-align: center">x</p>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'align': 'center'}}
      ]);
    });

    test('legacy align attr', () {
      expect(c.decode('<p align="right">x</p>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'align': 'right'}}
      ]);
    });

    test('direction rtl via dir attr', () {
      expect(c.decode('<p dir="rtl">x</p>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'direction': 'rtl'}}
      ]);
    });

    test('indent via padding-left em', () {
      expect(c.decode('<p style="padding-left: 4em">x</p>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'indent': 2}}
      ]);
    });

    test('indent via padding-left px', () {
      expect(c.decode('<p style="padding-left: 32px">x</p>').toJson(), [
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'indent': 1}}
      ]);
    });

    test('hr -> divider embed', () {
      expect(c.decode('<p>before</p><hr><p>after</p>').toJson(), [
        {'insert': 'before\n'},
        {
          'insert': {'divider': true}
        },
        {'insert': '\nafter\n'}
      ]);
    });

    test('pre with single line no trailing newline', () {
      expect(c.decode('<pre><code>only</code></pre>').toJson(), [
        {'insert': 'only'},
        {'insert': '\n', 'attributes': {'code-block': true}},
      ]);
    });

    test('pre with explicit trailing newline', () {
      expect(c.decode('<pre><code>line1\n</code></pre>').toJson(), [
        {'insert': 'line1'},
        {'insert': '\n', 'attributes': {'code-block': true}},
      ]);
    });

    test('pre with leading empty line', () {
      // Leading \n produces empty line, then 'line2', both code-block.
      // Adjacent same-attr \n inserts merge in Delta.
      expect(c.decode('<pre><code>\nline2</code></pre>').toJson(), [
        {'insert': '\n', 'attributes': {'code-block': true}},
        {'insert': 'line2'},
        {'insert': '\n', 'attributes': {'code-block': true}},
      ]);
    });

    test('pre with multiple internal blank lines', () {
      // Delta merges consecutive same-attr \n inserts -> '\n\n' as one op.
      expect(c.decode('<pre><code>a\n\nb</code></pre>').toJson(), [
        {'insert': 'a'},
        {'insert': '\n\n', 'attributes': {'code-block': true}},
        {'insert': 'b'},
        {'insert': '\n', 'attributes': {'code-block': true}},
      ]);
    });
  });
}
