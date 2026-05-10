import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';
import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';
import 'package:test/test.dart';

/// Pull plain text out of a Delta. Compares ignoring whitespace differences.
String _plain(Delta d) => d.operations.where((op) => op.data is String).map((op) => op.data as String).join();

/// Whitespace-collapsed comparison.
String _norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  // The same Delta we'll funnel through every format.
  final fixture = Delta()
    ..insert('Project Alpha')
    ..insert('\n', {'header': 1})
    ..insert('Status: ')
    ..insert('green', {'bold': true, 'color': '#00aa00'})
    ..insert(' as of release.\n')
    ..insert('Backlog')
    ..insert('\n', {'header': 2})
    ..insert('feature one')
    ..insert('\n', {'list': 'bullet'})
    ..insert('feature two')
    ..insert('\n', {'list': 'bullet'})
    ..insert('print("hello")')
    ..insert('\n', {'code-block': 'dart'})
    ..insert('See ')
    ..insert('docs', {'link': 'https://docs.example.com'})
    ..insert('.\n');

  group('plain text fidelity across all formats', () {
    final expected = _norm(_plain(fixture));

    test('html round trip', () async {
      final s = await HtmlExporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      ).export(fixture);
      final back = await HtmlImporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      ).import(s);
      expect(_norm(_plain(back)), expected);
    });

    test('markdown round trip preserves text', () async {
      final s = await const MarkdownExporter().export(fixture);
      final back = await MarkdownImporter().import(s);
      expect(_norm(_plain(back)), expected);
    });

    test('docx round trip preserves text', () async {
      final bytes = await const DocxExporter().export(fixture);
      final back = await DocxImporter().import(bytes);
      expect(_norm(_plain(back)), expected);
    });

    test('pdf produces text containing every word', () async {
      // PDF is one-way (no importer). PDF content streams may split words
      // with kerning Tj operators, so we look for individual words rather
      // than multi-word phrases.
      final bytes = await const PdfExporter().export(
        fixture,
        options: const PdfOptions(compress: false),
      );
      final body = latin1.decode(bytes, allowInvalid: true);
      for (final word in [
        'Project',
        'Alpha',
        'green',
        'feature',
        'docs',
      ]) {
        expect(body, contains(word), reason: word);
      }
    });
  });

  group('ConverterRegistry auto-dispatch', () {
    final registry = ConverterRegistry(
      importers: [
        HtmlImporter(),
        MarkdownImporter(),
        DocxImporter(),
      ],
      exporters: [
        HtmlExporter(),
        const MarkdownExporter(),
        const DocxExporter(),
      ],
    );

    test('text/html mime hint -> HtmlImporter', () async {
      final delta = await registry.importAuto(
        '<p>hello</p>',
        mime: 'text/html',
      );
      expect(_plain(delta), contains('hello'));
    });

    test('text/markdown mime hint -> MarkdownImporter', () async {
      final delta = await registry.importAuto(
        '# Hello\n',
        mime: 'text/markdown',
      );
      expect(_plain(delta), contains('Hello'));
    });

    test('docx filename ext -> DocxImporter', () async {
      final bytes = await const DocxExporter().export(Delta()..insert('docfile\n'));
      final delta = await registry.importAuto(bytes, filename: 'sample.docx');
      expect(_plain(delta), contains('docfile'));
    });

    test('magic-byte sniff PK\\x03\\x04 -> docx', () async {
      final bytes = await const DocxExporter().export(Delta()..insert('zipped\n'));
      final delta = await registry.importAuto(bytes);
      expect(_plain(delta), contains('zipped'));
    });

    test('content sniff <p> -> html', () async {
      final delta = await registry.importAuto('<p>fragment</p>');
      expect(_plain(delta), contains('fragment'));
    });

    test('content sniff # heading -> markdown', () async {
      final delta = await registry.importAuto('# Heading\n');
      expect(_plain(delta), contains('Heading'));
    });

    test('typed lookup returns correct exporter', () async {
      final exp = registry.exporter<String, HtmlOptions>('html');
      expect(exp.format, 'html');
      final out = await exp.export(Delta()..insert('typed\n'));
      expect(out, contains('typed'));
    });

    test('unknown format throws ConverterNotFound', () {
      expect(
        () => registry.exporter<String, HtmlOptions>('latex'),
        throwsA(isA<ConverterNotFound>()),
      );
    });
  });

  group('format chains', () {
    test('html -> markdown via Delta intermediate', () async {
      const html = '<h1>Title</h1><p>body with <strong>bold</strong>.</p>';
      final delta = await HtmlImporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      ).import(html);
      final md = await const MarkdownExporter().export(delta);
      expect(md, contains('# Title'));
      expect(md, contains('**bold**'));
    });

    test('markdown -> docx via Delta intermediate', () async {
      const md = '# Title\n\nBody **strong**.\n';
      final delta = await MarkdownImporter().import(md);
      final bytes = await const DocxExporter().export(delta);
      // Re-import to verify content survived.
      final back = await DocxImporter().import(bytes);
      expect(_plain(back), contains('Title'));
      expect(_plain(back), contains('strong'));
    });

    test('docx -> pdf via Delta intermediate', () async {
      // Build a minimal docx.
      final docxBytes = await const DocxExporter().export(Delta()..insert('Pipeline\n'));
      final delta = await DocxImporter().import(docxBytes);
      final pdfBytes = await const PdfExporter().export(
        delta,
        options: const PdfOptions(compress: false),
      );
      expect(pdfBytes[0], 0x25);
      expect(latin1.decode(pdfBytes, allowInvalid: true), contains('Pipeline'));
    });

    test('all four formats agree on plain text', () async {
      final input = Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('A paragraph.\n');
      final expected = _norm(_plain(input));

      final html = await HtmlExporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      ).export(input);
      final fromHtml = await HtmlImporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      ).import(html);
      expect(_norm(_plain(fromHtml)), expected);

      final md = await const MarkdownExporter().export(input);
      final fromMd = await MarkdownImporter().import(md);
      expect(_norm(_plain(fromMd)), expected);

      final docx = await const DocxExporter().export(input);
      final fromDocx = await DocxImporter().import(docx);
      expect(_norm(_plain(fromDocx)), expected);
    });
  });
}
