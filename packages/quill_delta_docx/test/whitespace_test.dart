import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';
import 'package:test/test.dart';

/// OOXML preserves whitespace via `xml:space="preserve"` on `<w:t>` and
/// requires `<w:br/>` for hard line breaks within a run. The exporter
/// always writes preserve; these tests verify the importer reads it back
/// faithfully and that significant unicode spaces survive the UTF-8 ZIP
/// roundtrip.
void main() {
  final exp = const DocxExporter();
  final imp = DocxImporter();

  String plain(Delta d) => d.operations
      .where((op) => op.data is String)
      .map((op) => op.data as String)
      .join();

  group('exporter writes xml:space="preserve"', () {
    test('on every <w:t>', () async {
      final bytes = await exp.export(Delta()..insert('one\n'));
      final archive = ZipDecoder().decodeBytes(bytes);
      final doc = utf8
          .decode(archive.findFile('word/document.xml')!.content as List<int>);
      expect(doc, contains('xml:space="preserve"'));
    });
  });

  group('round trip — ASCII whitespace', () {
    test('multiple internal spaces preserved', () async {
      final delta = Delta()..insert('a   b\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('a   b'));
    });

    test('leading spaces preserved', () async {
      final delta = Delta()..insert('   abc\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('   abc'));
    });

    test('trailing spaces preserved', () async {
      final delta = Delta()..insert('abc   \n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('abc   '));
    });

    test('tab character preserved', () async {
      final delta = Delta()..insert('a\tb\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('a\tb'));
    });

    test('mix of leading + internal + trailing spaces', () async {
      final delta = Delta()..insert('   a   b   \n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('   a   b   '));
    });
  });

  group('round trip — significant unicode spaces', () {
    final cases = <String, String>{
      'NBSP': 'a b',
      'EN SPACE': 'a b',
      'EM SPACE': 'a b',
      'THIN SPACE': 'a b',
      'ZWSP': 'a​b',
      'ZWNJ': 'a‌b',
      'ZWJ': 'a‍b',
      'NARROW NBSP': 'a b',
      'IDEOGRAPHIC SPACE': 'a　b',
    };
    for (final entry in cases.entries) {
      test('${entry.key} survives encode + decode', () async {
        final delta = Delta()..insert('${entry.value}\n');
        final bytes = await exp.export(delta);
        final back = await imp.import(bytes);
        expect(plain(back), contains(entry.value));
      });
    }
  });

  group('whitespace inside formatted runs', () {
    test('multi-space inside bold run preserved', () async {
      final delta = Delta()
        ..insert('a   b', {'bold': true})
        ..insert('\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      final boldOp = back.operations.firstWhere(
        (op) => op.attributes != null && op.attributes!['bold'] == true,
        orElse: () => Operation.insert(''),
      );
      expect(boldOp.data, 'a   b');
    });

    test('NBSP inside italic run preserved', () async {
      final delta = Delta()
        ..insert('a b', {'italic': true})
        ..insert('\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      final italicOp = back.operations.firstWhere(
        (op) => op.attributes != null && op.attributes!['italic'] == true,
        orElse: () => Operation.insert(''),
      );
      expect(italicOp.data, 'a b');
    });
  });

  group('paragraph + line-break handling', () {
    test('two text segments separated by \\n produce two <w:p>', () async {
      final delta = Delta()..insert('line1\nline2\n');
      final bytes = await exp.export(delta);
      final archive = ZipDecoder().decodeBytes(bytes);
      final doc = utf8
          .decode(archive.findFile('word/document.xml')!.content as List<int>);
      // splitIntoLines breaks on \n -> two paragraphs.
      expect('<w:p'.allMatches(doc).length, greaterThanOrEqualTo(2));
    });
  });

  group('code-block whitespace', () {
    test('multiple spaces inside code-block preserved', () async {
      final delta = Delta()
        ..insert('a   b   c')
        ..insert('\n', {'code-block': true});
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('a   b   c'));
    });

    test('tab inside code-block preserved', () async {
      final delta = Delta()
        ..insert('def\tx():')
        ..insert('\n', {'code-block': 'python'});
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('def\tx():'));
    });
  });

  group('whitespace and XML escaping interaction', () {
    test('ampersand surrounded by spaces survives', () async {
      final delta = Delta()..insert('a & b\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('a & b'));
    });

    test('angle brackets surrounded by spaces survive', () async {
      final delta = Delta()..insert('a < b > c\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      expect(plain(back), contains('a < b > c'));
    });
  });
}
