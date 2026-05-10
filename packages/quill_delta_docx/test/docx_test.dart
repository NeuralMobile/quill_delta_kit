import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';
import 'package:test/test.dart';

/// Build a minimal valid .docx archive in-memory containing the supplied
/// word/document.xml body.
List<int> buildDocxBytes(String bodyXml) {
  final document = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>$bodyXml</w:body>
</w:document>''';

  final archive = Archive();
  archive.addFile(ArchiveFile(
    'word/document.xml',
    document.length,
    document.codeUnits,
  ));
  return ZipEncoder().encode(archive)!;
}

void main() {
  final imp = DocxImporter();

  group('docxToHtml direct', () {
    test('paragraph with single run', () {
      final bytes = buildDocxBytes(
        '<w:p><w:r><w:t>Hello</w:t></w:r></w:p>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<p>'));
      expect(html, contains('Hello'));
    });

    test('bold + italic run', () {
      final bytes = buildDocxBytes(
        '<w:p><w:r>'
        '<w:rPr><w:b/><w:i/></w:rPr>'
        '<w:t>boldI</w:t>'
        '</w:r></w:p>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<strong>'));
      expect(html, contains('<em>'));
      expect(html, contains('boldI'));
    });

    test('h2 via Heading2 paragraph style', () {
      final bytes = buildDocxBytes(
        '<w:p>'
        '<w:pPr><w:pStyle w:val="Heading2"/></w:pPr>'
        '<w:r><w:t>Sub</w:t></w:r>'
        '</w:p>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<h2>'));
      expect(html, contains('Sub'));
    });

    test('bullet list', () {
      final bytes = buildDocxBytes(
        '<w:p>'
        '<w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr>'
        '<w:r><w:t>item1</w:t></w:r>'
        '</w:p>'
        '<w:p>'
        '<w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr>'
        '<w:r><w:t>item2</w:t></w:r>'
        '</w:p>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<ul>'));
      expect(html, contains('<li>'));
      expect(html, contains('item1'));
      expect(html, contains('item2'));
    });

    test('hyperlink anchor', () {
      final bytes = buildDocxBytes(
        '<w:p><w:hyperlink w:anchor="frag">'
        '<w:r><w:t>jump</w:t></w:r>'
        '</w:hyperlink></w:p>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('href="#frag"'));
      expect(html, contains('jump'));
    });

    test('rejects non-docx bytes', () {
      expect(
        () => docxToHtml([0xDE, 0xAD, 0xBE, 0xEF]),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DocxImporter', () {
    test('imports paragraph to Delta', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r><w:t>Hello world</w:t></w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      // package:html wraps in <html><body>; HtmlImporter unwraps.
      // Expected: insert("Hello world\n").
      final json = delta.toJson();
      expect(json.length, greaterThanOrEqualTo(1));
      // First op should contain our text.
      final text = json
          .where((op) => op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join();
      expect(text, contains('Hello world'));
    });

    test('imports bold run', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Bold</w:t></w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      final json = delta.toJson();
      final boldOp = json.firstWhere(
        (op) => op['attributes'] is Map &&
            (op['attributes'] as Map)['bold'] == true,
        orElse: () => {},
      );
      expect(boldOp['insert'], 'Bold');
    });

    test('format metadata', () {
      expect(imp.format, 'docx');
      expect(imp.extensions, contains('docx'));
      expect(imp.mimeTypes,
          contains('application/vnd.openxmlformats-officedocument.wordprocessingml.document'));
    });
  });

  group('DocxExporter stub', () {
    test('throws UnimplementedError', () async {
      final exp = const DocxExporter();
      expect(exp.format, 'docx');
      await expectLater(
        () => exp.export(Delta()..insert('x\n')),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
