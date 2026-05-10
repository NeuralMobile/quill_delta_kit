import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('block encoder', () {
    test('paragraph', () {
      expect(c.encode(deltaOf([{'insert': 'a\n'}])), '<p>a</p>');
    });

    test('multiple paragraphs', () {
      expect(c.encode(deltaOf([
        {'insert': 'a\nb\nc\n'}
      ])), '<p>a</p><p>b</p><p>c</p>');
    });

    test('empty paragraph -> <p><br></p>', () {
      expect(c.encode(deltaOf([
        {'insert': 'a\n\nb\n'}
      ])), '<p>a</p><p><br></p><p>b</p>');
    });

    test('h1-h6', () {
      for (var i = 1; i <= 6; i++) {
        final html = c.encode(deltaOf([
          {'insert': 'x'},
          {'insert': '\n', 'attributes': {'header': i}}
        ]));
        expect(html, '<h$i>x</h$i>');
      }
    });

    test('blockquote', () {
      final html = c.encode(deltaOf([
        {'insert': 'q'},
        {'insert': '\n', 'attributes': {'blockquote': true}}
      ]));
      expect(html, '<blockquote><p>q</p></blockquote>');
    });

    test('blockquote multiline groups', () {
      final html = c.encode(deltaOf([
        {'insert': 'a'},
        {'insert': '\n', 'attributes': {'blockquote': true}},
        {'insert': 'b'},
        {'insert': '\n', 'attributes': {'blockquote': true}}
      ]));
      expect(html, '<blockquote><p>a</p><p>b</p></blockquote>');
    });

    test('code-block groups consecutive lines', () {
      final html = c.encode(deltaOf([
        {'insert': 'line1'},
        {'insert': '\n', 'attributes': {'code-block': true}},
        {'insert': 'line2'},
        {'insert': '\n', 'attributes': {'code-block': true}}
      ]));
      expect(html, '<pre><code>line1\nline2</code></pre>');
    });

    test('code-block with language', () {
      final html = c.encode(deltaOf([
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'code-block': 'dart'}}
      ]));
      expect(html, '<pre><code class="language-dart">x</code></pre>');
    });

    test('align center', () {
      final html = c.encode(deltaOf([
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'align': 'center'}}
      ]));
      expect(html, '<p style="text-align: center">x</p>');
    });

    test('direction rtl', () {
      final html = c.encode(deltaOf([
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'direction': 'rtl'}}
      ]));
      expect(html, '<p dir="rtl">x</p>');
    });

    test('indent uses padding-left em', () {
      final html = c.encode(deltaOf([
        {'insert': 'x'},
        {'insert': '\n', 'attributes': {'indent': 2}}
      ]));
      expect(html, '<p style="padding-left: 4em">x</p>');
    });
  });
}
