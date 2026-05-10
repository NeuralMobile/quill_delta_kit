import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlImporter / HtmlExporter', () {
    test('async import/export round trip', () async {
      final delta = Delta()
        ..insert('Hello ')
        ..insert('world', {'bold': true})
        ..insert('!\n');
      final exporter = HtmlExporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      );
      final html = await exporter.export(delta);
      expect(html, '<p>Hello <strong>world</strong>!</p>');

      final importer = HtmlImporter(
        defaultOptions: const HtmlOptions(wrapDocument: false),
      );
      final back = await importer.import(html);
      expect(back.toJson(), delta.toJson());
    });

    test('format/mime/extension metadata', () {
      final i = HtmlImporter();
      expect(i.format, 'html');
      expect(i.mimeTypes, contains('text/html'));
      expect(i.extensions, contains('html'));
      final e = HtmlExporter();
      expect(e.format, 'html');
      expect(e.mimeType, 'text/html');
      expect(e.extension, 'html');
    });

    test('default options when none supplied', () async {
      final delta = Delta()..insert('x\n');
      final html = await HtmlExporter().export(delta);
      expect(html, startsWith('<div class="ql-html-doc"'));
    });
  });

  group('ConverterRegistry', () {
    test('registers + dispatches by format', () async {
      final reg = ConverterRegistry(
        importers: [HtmlImporter()],
        exporters: [HtmlExporter()],
      );
      final imp = reg.importer<String, HtmlOptions>('html');
      expect(imp.format, 'html');
      final delta = await imp.import('<p>a</p>');
      expect(delta.toJson(), [
        {'insert': 'a\n'}
      ]);
    });

    test('importAuto detects HTML by content', () async {
      final reg = ConverterRegistry(importers: [HtmlImporter()]);
      final delta = await reg.importAuto('<p>hi</p>');
      expect(delta.toJson(), [
        {'insert': 'hi\n'}
      ]);
    });

    test('importAuto detects HTML by mime', () async {
      final reg = ConverterRegistry(importers: [HtmlImporter()]);
      final delta = await reg.importAuto('<p>hi</p>', mime: 'text/html');
      expect(delta.toJson(), [
        {'insert': 'hi\n'}
      ]);
    });

    test('importAuto detects HTML by filename ext', () async {
      final reg = ConverterRegistry(importers: [HtmlImporter()]);
      final delta = await reg.importAuto('<p>hi</p>', filename: 'doc.html');
      expect(delta.toJson(), [
        {'insert': 'hi\n'}
      ]);
    });

    test('importAuto throws for unknown format', () async {
      final reg = ConverterRegistry(importers: [HtmlImporter()]);
      await expectLater(
        () => reg.importAuto([0xFF, 0xFE, 0xFD, 0xFC]),
        throwsA(isA<ConverterNotFound>()),
      );
    });

    test('lookup of unregistered format throws', () {
      final reg = ConverterRegistry();
      expect(
        () => reg.importer<String, HtmlOptions>('nope'),
        throwsA(isA<ConverterNotFound>()),
      );
    });

    test('sniffMagicBytes recognises ZIP and PDF', () {
      expect(sniffMagicBytes([0x50, 0x4B, 0x03, 0x04]), 'docx');
      expect(sniffMagicBytes([0x25, 0x50, 0x44, 0x46]), 'pdf');
      expect(sniffMagicBytes([0x00, 0x00, 0x00, 0x00]), isNull);
      expect(sniffMagicBytes([]), isNull);
    });

    test('sniffExtension', () {
      expect(sniffExtension('a.docx'), 'docx');
      expect(sniffExtension('a.MD'), 'markdown');
      expect(sniffExtension('a.markdown'), 'markdown');
      expect(sniffExtension('a.html'), 'html');
      expect(sniffExtension('a.unknown'), isNull);
      expect(sniffExtension('a'), isNull);
    });
  });

  group('QuillHtmlOptions backwards compat', () {
    test('typedef alias still works', () {
      const opts = QuillHtmlOptions(wrapDocument: false);
      expect(opts.wrapDocument, false);
      // QuillHtmlOptions IS HtmlOptions.
      expect(opts, isA<HtmlOptions>());
    });
  });
}
