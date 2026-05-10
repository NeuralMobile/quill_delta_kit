import 'package:quill_delta_html/src/util/whitespace.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  group('Ws.encodeText direct', () {
    test('preserves emoji surrogate pair verbatim', () {
      // U+1F30D EARTH GLOBE EUROPE-AFRICA — outside BMP, encoded as surrogate
      // pair in UTF-16. encodeText must NOT emit a numeric entity for it.
      expect(Ws.encodeText('a🌍b'), 'a🌍b');
    });

    test('preserves multi-codepoint emoji ZWJ sequence', () {
      // family emoji uses ZWJ joins between surrogate pairs
      const fam = '👨‍👩‍👧';
      // ZWJ is a significantSpace -> emitted as &#8205;
      expect(Ws.encodeText(fam), contains('&#8205;'));
      expect(Ws.encodeText(fam), contains('👨'));
    });

    test('escapes &, <, >, " as named entities', () {
      expect(Ws.encodeText('a&b<c>d"e'), 'a&amp;b&lt;c&gt;d&quot;e');
    });

    test('tab and CR -> numeric entities', () {
      expect(Ws.encodeText('a\tb\rc'), 'a&#9;b&#13;c');
    });

    test('NBSP and ZWSP -> numeric entities', () {
      expect(Ws.encodeText('a b​c'), 'a&#160;b&#8203;c');
    });
  });

  final c = frag();

  group('whitespace torture', () {
    final cases = <String, String>{
      'NBSP': 'a b',
      'EN SPACE': 'a b',
      'EM SPACE': 'a b',
      'THIN SPACE': 'a b',
      'ZWSP': 'a​b',
      'ZWNJ': 'a‌b',
      'ZWJ': 'a‍b',
      'NARROW NBSP': 'a b',
      'MEDIUM MATH SPACE': 'a b',
      'IDEOGRAPHIC SPACE': 'a　b',
      'BOM': 'a﻿b',
      'SOFT HYPHEN': 'a­b',
      'TAB': 'a\tb',
      'multiple spaces': 'a   b',
      'trailing spaces': 'abc   ',
      'leading spaces': '   abc',
    };
    for (final entry in cases.entries) {
      test('preserves ${entry.key}', () {
        final input = [
          {'insert': '${entry.value}\n'}
        ];
        final html = c.encode(deltaOf(input));
        final back = c.decode(html);
        final ops = back.toJson();
        expect(ops.length, 1);
        expect(ops.first['insert'], '${entry.value}\n');
      });
    }

    test('CRLF preserved as separate \\n in delta', () {
      // We don't auto-normalize CRLF; consumers should pass LF-only.
      final input = [
        {'insert': 'a\r\nb\n'}
      ];
      final html = c.encode(deltaOf(input));
      // Encoder treats \r as plain text (not a line break).
      expect(html, contains('a&#13;'));
      // Whole roundtrip through decoder.
      final back = c.decode(html).toJson();
      expect(back.first['insert'].toString().contains('\r'), true);
    });

    test('multiple consecutive newlines -> multiple empty paragraphs', () {
      final input = [
        {'insert': 'a\n\n\nb\n'}
      ];
      final html = c.encode(deltaOf(input));
      expect(html, '<p>a</p><p><br></p><p><br></p><p>b</p>');
      final back = c.decode(html).toJson();
      expect(back, [
        {'insert': 'a\n\n\nb\n'}
      ]);
    });

    test('large unicode mix', () {
      const t = 'Hello 🌍, café — œuf  ​end';
      final input = [
        {'insert': '$t\n'}
      ];
      final back = c.decode(c.encode(deltaOf(input)));
      expect(back.toJson(), [
        {'insert': '$t\n'}
      ]);
    });
  });
}
