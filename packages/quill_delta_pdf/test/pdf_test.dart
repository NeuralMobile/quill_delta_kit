import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';
import 'package:test/test.dart';

void main() {
  test('PdfImporter format metadata', () {
    final i = const PdfImporter();
    expect(i.format, 'pdf');
    expect(i.extensions, contains('pdf'));
    expect(i.mimeTypes, contains('application/pdf'));
  });

  test('PdfImporter throws UnimplementedError', () async {
    await expectLater(
      () => const PdfImporter().import([0x25, 0x50, 0x44, 0x46]),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('PdfExporter throws UnimplementedError', () async {
    await expectLater(
      () => const PdfExporter().export(Delta()..insert('x\n')),
      throwsA(isA<UnimplementedError>()),
    );
  });

  test('PdfOptions defaults', () {
    const o = PdfOptions();
    expect(o.pageSize, PdfPageSize.a4);
    expect(o.embedFonts, true);
    expect(o.compress, true);
  });
}
