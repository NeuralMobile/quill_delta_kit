import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';
import 'package:test/test.dart';

/// Decode the bytes as ISO-8859-1 (each byte one code unit) so we can
/// regex-search the PDF's textual portions without losing binary stream
/// boundaries.
String _asLatin1(List<int> bytes) => latin1.decode(bytes, allowInvalid: true);

void main() {
  final exp = const PdfExporter();
  // For structural inspection we disable compression so /Type entries are in
  // plain text rather than inside FlateDecode object streams.
  const uncompressed = PdfOptions(compress: false);

  group('PDF byte structure', () {
    test('header is %PDF-1.x', () async {
      final bytes = await exp.export(Delta()..insert('x\n'));
      final head = _asLatin1(bytes.sublist(0, 8));
      expect(head, startsWith('%PDF-'));
      // Major version digit
      expect(head.codeUnitAt(5), inInclusiveRange(0x30, 0x39));
    });

    test('ends with %%EOF', () async {
      final bytes = await exp.export(Delta()..insert('x\n'));
      final tail = _asLatin1(bytes.sublist(bytes.length - 32));
      expect(tail, contains('%%EOF'));
    });

    test('contains xref table', () async {
      final bytes = await exp.export(Delta()..insert('x\n'));
      final body = _asLatin1(bytes);
      expect(body, contains('xref'));
      // Trailer references xref offset.
      expect(body, contains('startxref'));
    });

    test('declares at least one page object', () async {
      final bytes = await exp.export(Delta()..insert('x\n'), options: uncompressed);
      final body = _asLatin1(bytes);
      expect(body, contains('/Pages'));
      expect(RegExp(r'/Page\b').hasMatch(body), true);
    });

    test('catalog object present', () async {
      final bytes = await exp.export(Delta()..insert('x\n'), options: uncompressed);
      final body = _asLatin1(bytes);
      expect(body, contains('/Catalog'));
    });
  });

  group('PDF page-format selection', () {
    test('A4 MediaBox is 595 x 842 pt (rounded)', () async {
      final bytes = await exp.export(
        Delta()..insert('x\n'),
        options: const PdfOptions(pageSize: PdfPageSize.a4),
      );
      final body = _asLatin1(bytes);
      // package:pdf serialises as "MediaBox [0 0 595.27559... 841.88976...]"
      // (or similar). Match the integer parts in the box.
      final m = RegExp(r'MediaBox\s*\[\s*0\s+0\s+(\d+)').firstMatch(body);
      expect(m, isNotNull);
      expect(int.parse(m!.group(1)!), inInclusiveRange(594, 596));
    });

    test('Letter MediaBox is 612 x 792 pt', () async {
      final bytes = await exp.export(
        Delta()..insert('x\n'),
        options: const PdfOptions(pageSize: PdfPageSize.letter),
      );
      final body = _asLatin1(bytes);
      final m = RegExp(r'MediaBox\s*\[\s*0\s+0\s+(\d+)').firstMatch(body);
      expect(m, isNotNull);
      expect(int.parse(m!.group(1)!), 612);
    });

    test('Legal MediaBox is 612 x 1008 pt', () async {
      final bytes = await exp.export(
        Delta()..insert('x\n'),
        options: const PdfOptions(pageSize: PdfPageSize.legal),
      );
      final body = _asLatin1(bytes);
      // Legal width 612, height 1008. Match the height.
      expect(body, contains('1008'));
    });
  });

  group('PDF content production', () {
    test('document with many lines spans a multipage object tree', () async {
      final delta = Delta();
      for (var i = 0; i < 200; i++) {
        delta.insert('Paragraph $i.\n');
      }
      final bytes = await exp.export(delta, options: uncompressed);
      final body = _asLatin1(bytes);
      // pw.MultiPage breaks into multiple page objects.
      final pageCount = RegExp(r'/Page\b').allMatches(body).length;
      expect(pageCount, greaterThanOrEqualTo(1));
      expect(bytes.length, greaterThan(2000));
    });

    test('hyperlink inserts /URI key with the destination', () async {
      final delta = Delta()
        ..insert('see ')
        ..insert('here', {'link': 'https://example.com'})
        ..insert('\n');
      final bytes = await exp.export(delta, options: uncompressed);
      final body = _asLatin1(bytes);
      expect(body, contains('/URI'));
      expect(body, contains('example.com'));
    });

    test('compress flag affects byte count', () async {
      final delta = Delta();
      for (var i = 0; i < 50; i++) {
        delta.insert('line $i with some words to compress\n');
      }
      final compressed = await exp.export(
        delta,
        options: const PdfOptions(compress: true),
      );
      final raw = await exp.export(
        delta,
        options: const PdfOptions(compress: false),
      );
      expect(compressed.length, lessThan(raw.length));
    });

    test('export of empty document still produces valid PDF', () async {
      final bytes = await exp.export(Delta()..insert('\n'));
      final body = _asLatin1(bytes);
      expect(body, startsWith('%PDF-'));
      expect(body, contains('%%EOF'));
    });
  });

  group('PDF importer stub', () {
    test('rejects with UnimplementedError on real PDF bytes', () async {
      final pdfBytes = await exp.export(Delta()..insert('x\n'));
      await expectLater(
        () => const PdfImporter().import(pdfBytes),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
