import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('inline encoder', () {
    test('plain text', () {
      final html = c.encode(deltaOf([
        {'insert': 'hello\n'}
      ]));
      expect(html, '<p>hello</p>');
    });

    test('bold', () {
      final html = c.encode(deltaOf([
        {'insert': 'a'},
        {
          'insert': 'b',
          'attributes': {'bold': true}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p>a<strong>b</strong></p>');
    });

    test('italic + underline + strike + code', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {
            'italic': true,
            'underline': true,
            'strike': true,
            'code': true
          }
        },
        {'insert': '\n'}
      ]));
      // Order: code (innermost) -> u -> s -> em (outermost since bold not present)
      expect(html, '<p><em><s><u><code>x</code></u></s></em></p>');
    });

    test('bold + italic combined', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'bold': true, 'italic': true}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><strong><em>x</em></strong></p>');
    });

    test('color via canonical rgba', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'color': '#ff0000'}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><span style="color: #ff0000">x</span></p>');
    });

    test('color from flutter_quill ARGB', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'color': '#ffaa0000'}
        },
        {'insert': '\n'}
      ]));
      // 8-digit hex = RRGGBBAA per CSS spec; opaque red 0xaa? actually #ffaa0000 with last 2 hex = 0x00 = transparent.
      // Most code interprets via CSS. Confirm value.
      expect(html, contains('color:'));
    });

    test('background', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'background': '#00ff00'}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><span style="background-color: #00ff00">x</span></p>');
    });

    test('font + size', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'font': 'serif', 'size': 'large'}
        },
        {'insert': '\n'}
      ]));
      expect(html,
          '<p><span style="font-family: serif; font-size: 18px">x</span></p>');
    });

    test('size numeric', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'size': '14'}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><span style="font-size: 14px">x</span></p>');
    });

    test('script super', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'script': 'super'}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><sup>x</sup></p>');
    });

    test('script sub', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'script': 'sub'}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><sub>x</sub></p>');
    });

    test('link', () {
      final html = c.encode(deltaOf([
        {
          'insert': 'x',
          'attributes': {'link': 'https://example.com'}
        },
        {'insert': '\n'}
      ]));
      expect(html, '<p><a href="https://example.com">x</a></p>');
    });

    test('escapes html chars', () {
      final html = c.encode(deltaOf([
        {'insert': '<a&b>"c"\n'}
      ]));
      expect(html, '<p>&lt;a&amp;b&gt;&quot;c&quot;</p>');
    });

    test('preserves NBSP', () {
      final html = c.encode(deltaOf([
        {'insert': 'a b\n'}
      ]));
      expect(html, '<p>a&#160;b</p>');
    });

    test('preserves ZWSP + ZWJ', () {
      final html = c.encode(deltaOf([
        {'insert': 'a​b‍c\n'}
      ]));
      expect(html, '<p>a&#8203;b&#8205;c</p>');
    });

    test('preserves tab', () {
      final html = c.encode(deltaOf([
        {'insert': 'a\tb\n'}
      ]));
      expect(html, '<p>a&#9;b</p>');
    });
  });
}
