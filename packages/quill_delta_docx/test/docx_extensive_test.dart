import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';
import 'package:test/test.dart';

/// Build a minimal valid .docx archive containing the supplied
/// word/document.xml body and an optional numbering.xml.
List<int> buildDocxBytes(String bodyXml, {String? numberingXml}) {
  final document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<w:body>$bodyXml</w:body></w:document>';
  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add('word/document.xml', document);
  if (numberingXml != null) add('word/numbering.xml', numberingXml);
  return ZipEncoder().encode(archive)!;
}

void main() {
  final imp = DocxImporter();
  final exp = const DocxExporter();

  group('DocxImporter — text + runs', () {
    test('preserves literal whitespace in <w:t>', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r><w:t xml:space="preserve">  spaced  </w:t></w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      final text = delta.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text, contains('  spaced  '));
    });

    test('handles XML special chars correctly', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r><w:t>a &amp; b &lt; c &gt; d</w:t></w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      final text = delta.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text, contains('a & b < c > d'));
    });

    test('combined bold+italic+underline+strike on single run', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r>'
        '<w:rPr><w:b/><w:i/><w:u w:val="single"/><w:strike/></w:rPr>'
        '<w:t>all</w:t>'
        '</w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      final op = delta.operations.firstWhere(
        (op) => op.data == 'all',
        orElse: () => Operation.insert(''),
      );
      expect(op.attributes?['bold'], true);
      expect(op.attributes?['italic'], true);
      expect(op.attributes?['underline'], true);
      expect(op.attributes?['strike'], true);
    });

    test('color and size as hex/half-points', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r>'
        '<w:rPr><w:color w:val="FF8800"/><w:sz w:val="40"/></w:rPr>'
        '<w:t>x</w:t>'
        '</w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      final op = delta.operations
          .firstWhere((o) => o.data == 'x', orElse: () => Operation.insert(''));
      // 40 half-points = 20pt = 26.67px. Allow ±1 for rounding.
      expect(op.attributes?['color'].toString().toLowerCase(), '#ff8800');
      final size = int.parse(op.attributes!['size'] as String);
      expect(size, inInclusiveRange(26, 28));
    });

    test('multiple runs in one paragraph keep order', () async {
      final bytes = buildDocxBytes(
        '<w:p>'
        '<w:r><w:t>foo</w:t></w:r>'
        '<w:r><w:rPr><w:b/></w:rPr><w:t>bar</w:t></w:r>'
        '<w:r><w:t>baz</w:t></w:r>'
        '</w:p>',
      );
      final delta = await imp.import(bytes);
      final text = delta.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text.replaceAll('\n', ''), 'foobarbaz');
    });

    test('bold off via val="false" disables', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r>'
        '<w:rPr><w:b w:val="false"/></w:rPr>'
        '<w:t>plain</w:t>'
        '</w:r></w:p>',
      );
      final delta = await imp.import(bytes);
      final op = delta.operations.firstWhere(
        (o) => o.data == 'plain',
        orElse: () => Operation.insert(''),
      );
      expect(op.attributes?['bold'], isNull);
    });
  });

  group('DocxImporter — block structures', () {
    test('all heading levels', () async {
      for (var i = 1; i <= 6; i++) {
        final bytes = buildDocxBytes(
          '<w:p><w:pPr><w:pStyle w:val="Heading$i"/></w:pPr>'
          '<w:r><w:t>H$i</w:t></w:r></w:p>',
        );
        final html = docxToHtml(bytes);
        expect(html, contains('<h$i>'));
        expect(html, contains('H$i'));
      }
    });

    test('table with two rows produces tr+td', () async {
      final bytes = buildDocxBytes(
        '<w:tbl>'
        '<w:tr><w:tc><w:p><w:r><w:t>r1c1</w:t></w:r></w:p></w:tc>'
        '<w:tc><w:p><w:r><w:t>r1c2</w:t></w:r></w:p></w:tc></w:tr>'
        '<w:tr><w:tc><w:p><w:r><w:t>r2c1</w:t></w:r></w:p></w:tc>'
        '<w:tc><w:p><w:r><w:t>r2c2</w:t></w:r></w:p></w:tc></w:tr>'
        '</w:tbl>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<table>'));
      expect(html.split('<tr>').length - 1, 2);
      expect(html, contains('r1c1'));
      expect(html, contains('r2c2'));
    });

    test('paragraph with line break in run', () async {
      final bytes = buildDocxBytes(
        '<w:p><w:r><w:t>line1</w:t><w:br/><w:t>line2</w:t></w:r></w:p>',
      );
      final html = docxToHtml(bytes);
      expect(html, contains('line1'));
      expect(html, contains('<br>'));
      expect(html, contains('line2'));
    });
  });

  group('DocxImporter — numbering.xml', () {
    test('explicit ordered numbering is detected', () async {
      const numbering = '<?xml version="1.0"?>'
          '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
          '<w:abstractNum w:abstractNumId="0">'
          '<w:lvl w:ilvl="0"><w:numFmt w:val="decimal"/></w:lvl>'
          '</w:abstractNum>'
          '<w:num w:numId="5"><w:abstractNumId w:val="0"/></w:num>'
          '</w:numbering>';
      final bytes = buildDocxBytes(
        '<w:p><w:pPr><w:numPr>'
        '<w:ilvl w:val="0"/><w:numId w:val="5"/>'
        '</w:numPr></w:pPr><w:r><w:t>one</w:t></w:r></w:p>',
        numberingXml: numbering,
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<ol>'));
      expect(html, contains('one'));
    });

    test('explicit bullet numbering is detected', () async {
      const numbering = '<?xml version="1.0"?>'
          '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
          '<w:abstractNum w:abstractNumId="0">'
          '<w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/></w:lvl>'
          '</w:abstractNum>'
          '<w:num w:numId="3"><w:abstractNumId w:val="0"/></w:num>'
          '</w:numbering>';
      final bytes = buildDocxBytes(
        '<w:p><w:pPr><w:numPr>'
        '<w:ilvl w:val="0"/><w:numId w:val="3"/>'
        '</w:numPr></w:pPr><w:r><w:t>dot</w:t></w:r></w:p>',
        numberingXml: numbering,
      );
      final html = docxToHtml(bytes);
      expect(html, contains('<ul>'));
      expect(html, contains('dot'));
    });

    test('different ilvl produces nested list structure', () async {
      const numbering = '<?xml version="1.0"?>'
          '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
          '<w:abstractNum w:abstractNumId="0">'
          '<w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/></w:lvl>'
          '<w:lvl w:ilvl="1"><w:numFmt w:val="bullet"/></w:lvl>'
          '</w:abstractNum>'
          '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>'
          '</w:numbering>';
      final bytes = buildDocxBytes(
        '<w:p><w:pPr><w:numPr>'
        '<w:ilvl w:val="0"/><w:numId w:val="1"/>'
        '</w:numPr></w:pPr><w:r><w:t>a</w:t></w:r></w:p>'
        '<w:p><w:pPr><w:numPr>'
        '<w:ilvl w:val="1"/><w:numId w:val="1"/>'
        '</w:numPr></w:pPr><w:r><w:t>b</w:t></w:r></w:p>',
        numberingXml: numbering,
      );
      final html = docxToHtml(bytes);
      expect(html.split('<ul>').length - 1, 2);
      expect(html, contains('a'));
      expect(html, contains('b'));
    });
  });

  group('DocxExporter — round-trip preserves attributes', () {
    test('alignment center / right / justify', () async {
      for (final align in ['center', 'right', 'justify']) {
        final bytes = await exp.export(Delta()
          ..insert('x')
          ..insert('\n', {'align': align}));
        final archive = ZipDecoder().decodeBytes(bytes);
        final doc = utf8.decode(
            archive.findFile('word/document.xml')!.content as List<int>);
        final mapped = align == 'justify' ? 'both' : align;
        expect(doc, contains('w:val="$mapped"'));
      }
    });

    test('emoji and non-ASCII survive round trip', () async {
      final delta = Delta()..insert('Hello 🌍 café — œuf\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      final text = back.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text, contains('🌍'));
      expect(text, contains('café'));
      expect(text, contains('œuf'));
    });

    test('hyperlinks survive round trip with original href', () async {
      final delta = Delta()
        ..insert('site', {'link': 'https://example.com/path?q=1'})
        ..insert('\n');
      final bytes = await exp.export(delta);
      final archive = ZipDecoder().decodeBytes(bytes);
      final rels = utf8.decode(archive
          .findFile('word/_rels/document.xml.rels')!
          .content as List<int>);
      expect(rels, contains('https://example.com/path?q=1'));
    });

    test('mixed deep document round-trips text + structure', () async {
      final delta = Delta()
        ..insert('Top heading')
        ..insert('\n', {'header': 1})
        ..insert('Para with ')
        ..insert('bold', {'bold': true})
        ..insert(', ')
        ..insert('italic', {'italic': true})
        ..insert(', and ')
        ..insert('a link', {'link': 'https://x.test'})
        ..insert('.\n')
        ..insert('one')
        ..insert('\n', {'list': 'bullet'})
        ..insert('two')
        ..insert('\n', {'list': 'bullet', 'indent': 1})
        ..insert('three')
        ..insert('\n', {'list': 'ordered'})
        ..insert('quoted line')
        ..insert('\n', {'blockquote': true})
        ..insert('print(x)')
        ..insert('\n', {'code-block': 'dart'});
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      final text = back.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      for (final needle in [
        'Top heading',
        'bold',
        'italic',
        'a link',
        'one',
        'two',
        'three',
        'quoted line',
        'print(x)',
      ]) {
        expect(text, contains(needle), reason: needle);
      }
    });

    test('large document (200 paragraphs) produces well-formed bytes',
        () async {
      final delta = Delta();
      for (var i = 0; i < 200; i++) {
        delta.insert('Paragraph $i with some text. ');
        delta.insert('\n');
      }
      final bytes = await exp.export(delta);
      // Sanity: ZIP signature, plausible size.
      expect(bytes.length, greaterThan(2000));
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
      // Round trip retains every paragraph index marker.
      final back = await imp.import(bytes);
      final text = back.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text, contains('Paragraph 0'));
      expect(text, contains('Paragraph 199'));
    });

    test('color and size encode then decode equivalent values', () async {
      final delta = Delta()
        ..insert('label', {'color': '#3366FF', 'size': '20'})
        ..insert('\n');
      final bytes = await exp.export(delta);
      final back = await imp.import(bytes);
      final op = back.operations.firstWhere(
        (o) => o.data == 'label',
        orElse: () => Operation.insert(''),
      );
      expect(op.attributes?['color'].toString().toLowerCase(), '#3366ff');
      // Allow a 1-pixel drift due to half-point rounding.
      final size = int.parse(op.attributes!['size'] as String);
      expect(size, inInclusiveRange(19, 21));
    });
  });

  group('DocxExporter — package structure', () {
    test('content-types.xml registers required overrides', () async {
      final bytes = await exp.export(Delta()..insert('x\n'));
      final archive = ZipDecoder().decodeBytes(bytes);
      final ct = utf8.decode(
          archive.findFile('[Content_Types].xml')!.content as List<int>);
      expect(ct, contains('wordprocessingml.document.main'));
      expect(ct, contains('/word/document.xml'));
      expect(ct, contains('/word/styles.xml'));
      expect(ct, contains('/word/numbering.xml'));
    });

    test('root rels points at document.xml', () async {
      final bytes = await exp.export(Delta()..insert('x\n'));
      final archive = ZipDecoder().decodeBytes(bytes);
      final root =
          utf8.decode(archive.findFile('_rels/.rels')!.content as List<int>);
      expect(root, contains('Target="word/document.xml"'));
      expect(root, contains('officeDocument'));
    });

    test('numbering.xml contains both numId 1 (bullet) and 2 (ordered)',
        () async {
      final bytes = await exp.export(Delta()..insert('x\n'));
      final archive = ZipDecoder().decodeBytes(bytes);
      final num = utf8
          .decode(archive.findFile('word/numbering.xml')!.content as List<int>);
      expect(num, contains('w:numId="1"'));
      expect(num, contains('w:numId="2"'));
      expect(num, contains('numFmt w:val="bullet"'));
      expect(num, contains('numFmt w:val="decimal"'));
    });
  });
}
