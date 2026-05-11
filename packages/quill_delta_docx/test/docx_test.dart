import 'dart:convert';

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

    test('inline image emits <img> with data-URI src', () async {
      // 1×1 transparent PNG.
      const pngBytes = [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x62,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ];
      const documentBody = '<w:p><w:r><w:drawing>'
          '<wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
          '<wp:extent cx="952500" cy="952500"/>'
          '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
          '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:blipFill>'
          '<a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="rId4"/>'
          '</pic:blipFill>'
          '</pic:pic>'
          '</a:graphicData>'
          '</a:graphic>'
          '</wp:inline>'
          '</w:drawing></w:r></w:p>';
      const relsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>'
          '</Relationships>';
      final doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<w:body>$documentBody</w:body></w:document>';
      final archive = Archive();
      void addStr(String path, String content) {
        final bytes = utf8.encode(content);
        archive.addFile(ArchiveFile(path, bytes.length, bytes));
      }

      void addBytes(String path, List<int> bytes) {
        archive.addFile(ArchiveFile(path, bytes.length, bytes));
      }

      addStr('word/document.xml', doc);
      addStr('word/_rels/document.xml.rels', relsXml);
      addBytes('word/media/image1.png', pngBytes);
      final docxBytes = ZipEncoder().encode(archive)!;

      final html = docxToHtml(docxBytes);
      expect(html, contains('<img'));
      expect(html, contains('data:image/png;base64,'));
      // 952500 EMU / 9525 = 100 px.
      expect(html, contains('width="100"'));
      expect(html, contains('height="100"'));
    });

    test('rejects non-docx bytes', () {
      expect(
        () => docxToHtml([0xDE, 0xAD, 0xBE, 0xEF]),
        throwsA(isA<Exception>()),
      );
    });

    test('numbering.xml resolves ordered vs bullet', () async {
      // Round-trip a Delta with both bullet and ordered lists through
      // DocxExporter -> DocxImporter. Tests that the importer picks up the
      // numbering.xml emitted by the exporter and routes lists correctly.
      final delta = Delta()
        ..insert('a')
        ..insert('\n', {'list': 'bullet'})
        ..insert('b')
        ..insert('\n', {'list': 'ordered'});
      final bytes = const DocxExporter().exportSync(delta);
      final delta2 = await DocxImporter().import(bytes);
      final json = delta2.toJson();
      // Find the two list-marker newlines and confirm their type.
      final listOps = json.where((op) {
        final attrs = op['attributes'];
        return attrs is Map && attrs['list'] != null;
      }).toList();
      expect(listOps.length, 2);
      expect((listOps[0]['attributes'] as Map)['list'], 'bullet');
      expect((listOps[1]['attributes'] as Map)['list'], 'ordered');
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
        (op) =>
            op['attributes'] is Map &&
            (op['attributes'] as Map)['bold'] == true,
        orElse: () => {},
      );
      expect(boldOp['insert'], 'Bold');
    });

    test('format metadata', () {
      expect(imp.format, 'docx');
      expect(imp.extensions, contains('docx'));
      expect(
          imp.mimeTypes,
          contains(
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document'));
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
      expect(
          names,
          containsAll(<String>{
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
