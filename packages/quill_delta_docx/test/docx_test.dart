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

  group('DocxExporter', () {
    final exp = const DocxExporter();

    test('format metadata', () {
      expect(exp.format, 'docx');
      expect(exp.extension, 'docx');
    });

    test('produces a valid ZIP with required parts', () async {
      final bytes = await exp.export(Delta()..insert('Hello\n'));
      expect(bytes, isNotEmpty);
      // ZIP local file header signature.
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
      expect(bytes[2], 0x03);
      expect(bytes[3], 0x04);
      // Required parts present.
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, containsAll(<String>{
        '[Content_Types].xml',
        '_rels/.rels',
        'word/document.xml',
        'word/_rels/document.xml.rels',
        'word/styles.xml',
        'word/numbering.xml',
      }));
    });

    test('round-trip via importer preserves text', () async {
      final delta = Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('Para with ')
        ..insert('bold', {'bold': true})
        ..insert(' and ')
        ..insert('italic', {'italic': true})
        ..insert('.\n')
        ..insert('item 1')
        ..insert('\n', {'list': 'bullet'})
        ..insert('item 2')
        ..insert('\n', {'list': 'bullet'});
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      final text = back.operations
          .where((op) => op.isInsert && op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text, contains('Title'));
      expect(text, contains('Para with bold and italic'));
      expect(text, contains('item 1'));
      expect(text, contains('item 2'));
    });

    test('hyperlink relationship written', () async {
      final delta = Delta()
        ..insert('see ')
        ..insert('here', {'link': 'https://example.com'})
        ..insert('\n');
      final bytes = await exp.export(delta);
      final archive = ZipDecoder().decodeBytes(bytes);
      final rels = archive.findFile('word/_rels/document.xml.rels')!;
      final relsXml = String.fromCharCodes(rels.content as List<int>);
      expect(relsXml, contains('https://example.com'));
      expect(relsXml, contains('hyperlink'));
    });

    test('color and size emit as half-points / hex', () async {
      final delta = Delta()
        ..insert('big red', {'color': '#ff0000', 'size': '24'})
        ..insert('\n');
      final bytes = await exp.export(delta);
      final archive = ZipDecoder().decodeBytes(bytes);
      final doc = archive.findFile('word/document.xml')!;
      final docXml = String.fromCharCodes(doc.content as List<int>);
      expect(docXml, contains('w:color w:val="FF0000"'));
      // 24px ≈ 18pt → 36 half-points.
      expect(docXml, contains('w:sz w:val="36"'));
    });
  });
}
