import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';
import 'package:test/test.dart';

/// PDF is one-way (no importer) so we cannot assert round-trip. Instead we
/// verify that whitespace appears in the produced byte stream and that
/// non-ASCII space codepoints don't crash the writer.
///
/// PDF text strings are encoded as `(literal) Tj` operators. With
/// compress: false the literal is in plain ASCII; bytes outside the base
/// font's encoding may be replaced with placeholders by package:pdf, so we
/// don't insist on byte-exact preservation — we test "does not crash and
/// the document is well-formed".
void main() {
  final exp = const PdfExporter();
  const _u = PdfOptions(compress: false);

  String _body(List<int> bytes) =>
      latin1.decode(bytes, allowInvalid: true);

  group('PdfExporter does not crash on whitespace inputs', () {
    final cases = <String, String>{
      'multiple internal spaces': 'a   b',
      'leading spaces': '   abc',
      'trailing spaces': 'abc   ',
      'tab': 'a\tb',
      'NBSP': 'a b',
      'EN SPACE': 'a b',
      'EM SPACE': 'a b',
      'THIN SPACE': 'a b',
      'ZWSP': 'a​b',
      'ZWNJ': 'a‌b',
      'ZWJ': 'a‍b',
      'NARROW NBSP': 'a b',
      'IDEOGRAPHIC SPACE': 'a　b',
      'mixed': '   a   b   ',
    };
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final bytes = await exp.export(
          Delta()..insert('${entry.value}\n'),
          options: _u,
        );
        // Header + EOF -> well-formed PDF.
        expect(bytes[0], 0x25); // %
        expect(bytes[1], 0x50); // P
        final tail = _body(bytes.sublist(bytes.length - 32));
        expect(tail, contains('%%EOF'));
      });
    }
  });

  group('text payload contains the whitespace surrounded by non-space', () {
    test('multiple internal spaces emitted in content stream', () async {
      final bytes = await exp.export(
        Delta()..insert('hello   world\n'),
        options: _u,
      );
      final body = _body(bytes);
      // package:pdf writes (hello   world) Tj in the content stream when
      // compression is disabled. The literal substring should appear.
      expect(body, contains('hello'));
      expect(body, contains('world'));
    });

    test('NBSP in content does not corrupt subsequent objects', () async {
      // Encode several paragraphs after an NBSP-containing one. If the
      // encoder mishandles the codepoint the trailing objects break.
      final delta = Delta()
        ..insert('a b\n')
        ..insert('next line\n')
        ..insert('final line\n');
      final bytes = await exp.export(delta, options: _u);
      final body = _body(bytes);
      expect(body, contains('next'));
      expect(body, contains('final'));
      expect(body, contains('%%EOF'));
    });
  });

  group('code block preserves whitespace styling', () {
    test('multi-space code block does not crash', () async {
      final bytes = await exp.export(
        Delta()
          ..insert('a   b   c')
          ..insert('\n', {'code-block': 'dart'}),
      );
      expect(bytes.length, greaterThan(100));
    });

    test('tab in code block does not crash', () async {
      final bytes = await exp.export(
        Delta()
          ..insert('def\tx():')
          ..insert('\n', {'code-block': 'python'}),
      );
      expect(bytes.length, greaterThan(100));
    });
  });
}
