import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta_html_example/word_import.dart';

/// Build a minimal in-memory `.docx` from the given `word/document.xml` body.
List<int> buildDocx(String bodyXml, {Map<String, String>? rels, Map<String, List<int>>? media}) {
  final archive = Archive();
  final doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
      'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
      '<w:body>$bodyXml</w:body></w:document>';
  archive.addFile(ArchiveFile('word/document.xml', doc.length, utf8.encode(doc)));
  if (rels != null && rels.isNotEmpty) {
    final sb = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    rels.forEach((id, target) {
      sb.write('<Relationship Id="$id" Type="x" Target="$target"/>');
    });
    sb.write('</Relationships>');
    final str = sb.toString();
    archive.addFile(
      ArchiveFile('word/_rels/document.xml.rels', str.length, utf8.encode(str)),
    );
  }
  if (media != null) {
    media.forEach((path, bytes) {
      archive.addFile(ArchiveFile('word/$path', bytes.length, bytes));
    });
  }
  return ZipEncoder().encode(archive)!;
}

void main() {
  group('WordImporter', () {
    final importer = WordImporter();

    test('basic paragraph', () async {
      final bytes = buildDocx('<w:p><w:r><w:t>hello</w:t></w:r></w:p>');
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('<p>'));
      expect(html, contains('hello'));
    });

    test('bold + italic + underline', () async {
      final bytes = buildDocx(
        '<w:p><w:r><w:rPr><w:b/><w:i/><w:u w:val="single"/></w:rPr><w:t>fmt</w:t></w:r></w:p>',
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('<strong>'));
      expect(html, contains('<em>'));
      expect(html, contains('<u>'));
    });

    test('color + font + size', () async {
      final bytes = buildDocx(
        '<w:p><w:r><w:rPr><w:color w:val="ff0000"/>'
        '<w:rFonts w:ascii="Arial"/><w:sz w:val="28"/>'
        '</w:rPr><w:t>x</w:t></w:r></w:p>',
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('color: #ff0000'));
      expect(html, contains('font-family: Arial'));
      expect(html, contains('font-size: 19px'));
    });

    test('headings', () async {
      final bytes = buildDocx(
        '<w:p><w:pPr><w:pStyle w:val="Heading2"/></w:pPr>'
        '<w:r><w:t>title</w:t></w:r></w:p>',
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('<h2>'));
      expect(html, contains('title'));
    });

    test('hyperlink', () async {
      final bytes = buildDocx(
        '<w:p><w:hyperlink r:id="rId1"><w:r><w:t>link</w:t></w:r></w:hyperlink></w:p>',
        rels: {'rId1': 'https://example.com'},
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('<a href="https://example.com">'));
      expect(html, contains('link'));
    });

    test('alignment', () async {
      final bytes = buildDocx(
        '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
        '<w:r><w:t>x</w:t></w:r></w:p>',
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('text-align: center'));
    });

    test('table', () async {
      final bytes = buildDocx(
        '<w:tbl>'
        '<w:tr><w:tc><w:p><w:r><w:t>a</w:t></w:r></w:p></w:tc>'
        '<w:tc><w:p><w:r><w:t>b</w:t></w:r></w:p></w:tc></w:tr>'
        '</w:tbl>',
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('<table>'));
      expect(html, contains('<td>'));
      expect(html, contains('a'));
      expect(html, contains('b'));
    });

    test('docxToDelta runs through codec', () async {
      final bytes = buildDocx('<w:p><w:r><w:t>hi</w:t></w:r></w:p>');
      final delta = await importer.docxToDelta(Uint8List.fromList(bytes));
      expect(delta.toJson(), [
        {'insert': 'hi\n'}
      ]);
    });

    test('strike + script', () async {
      final bytes = buildDocx(
        '<w:p>'
        '<w:r><w:rPr><w:strike/></w:rPr><w:t>s</w:t></w:r>'
        '<w:r><w:rPr><w:vertAlign w:val="superscript"/></w:rPr><w:t>2</w:t></w:r>'
        '</w:p>',
      );
      final html = await importer.docxToHtml(Uint8List.fromList(bytes));
      expect(html, contains('<s>'));
      expect(html, contains('<sup>'));
    });

    test('rejects non-docx', () async {
      expect(
        () => importer.docxToHtml(Uint8List.fromList([0x00, 0x01])),
        throwsA(isA<Exception>()),
      );
    });
  });
}
