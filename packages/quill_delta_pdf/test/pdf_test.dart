import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';
import 'package:test/test.dart';

void main() {
  group('PdfImporter (stub)', () {
    test('format metadata', () {
      final i = const PdfImporter();
      expect(i.format, 'pdf');
      expect(i.extensions, contains('pdf'));
      expect(i.mimeTypes, contains('application/pdf'));
    });

    test('throws UnimplementedError', () async {
      await expectLater(
        () => const PdfImporter().import([0x25, 0x50, 0x44, 0x46]),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('PdfExporter', () {
    final exp = const PdfExporter();

    test('format metadata', () {
      expect(exp.format, 'pdf');
      expect(exp.extension, 'pdf');
      expect(exp.mimeType, 'application/pdf');
    });

    test('produces valid PDF bytes', () async {
      final delta = Delta()..insert('Hello\n');
      final bytes = await exp.export(delta);
      expect(bytes, isNotEmpty);
      // PDF magic: %PDF
      expect(bytes[0], 0x25);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x44);
      expect(bytes[3], 0x46);
    });

    test('large mixed content does not throw', () async {
      final delta = Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('A paragraph with ')
        ..insert('bold', {'bold': true})
        ..insert(' and ')
        ..insert('a link', {'link': 'https://example.com'})
        ..insert('.\n')
        ..insert('item 1')
        ..insert('\n', {'list': 'bullet'})
        ..insert('item 2')
        ..insert('\n', {'list': 'bullet'})
        ..insert('print("x")')
        ..insert('\n', {'code-block': 'dart'})
        ..insert('quoted')
        ..insert('\n', {'blockquote': true});
      final bytes = await exp.export(delta);
      expect(bytes.length, greaterThan(100));
    });

    test('respects pageSize option', () async {
      final delta = Delta()..insert('x\n');
      final letter = await exp.export(
        delta,
        options: const PdfOptions(pageSize: PdfPageSize.letter),
      );
      final a4 = await exp.export(
        delta,
        options: const PdfOptions(pageSize: PdfPageSize.a4),
      );
      // Different page sizes produce different bytes (page MediaBox differs).
      expect(letter, isNot(equals(a4)));
    });
  });

  group('PdfOptions', () {
    test('defaults', () {
      const o = PdfOptions();
      expect(o.pageSize, PdfPageSize.a4);
      expect(o.embedFonts, true);
      expect(o.compress, true);
    });
  });
}
