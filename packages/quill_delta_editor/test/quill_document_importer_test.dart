import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

void main() {
  group('QuillDocumentImporter.importText', () {
    test('html updates controller document', () async {
      final controller = QuillController.basic();
      await QuillDocumentImporter().importText(
        controller: controller,
        text: '<p>Hello <strong>world</strong></p>',
        format: 'html',
      );
      final json = controller.document.toDelta().toJson();
      expect(json.where((op) => op['insert'] == 'world').isNotEmpty, true);
      expect(
        json.firstWhere((op) => op['insert'] == 'world')['attributes'],
        {'bold': true},
      );
      controller.dispose();
    });

    test('markdown via filename hint', () async {
      final controller = QuillController.basic();
      await QuillDocumentImporter().importText(
        controller: controller,
        text: '# Title\n\nBody.\n',
        format: 'markdown',
      );
      final json = controller.document.toDelta().toJson();
      expect(json.any((op) => op['insert'] == 'Title'), true);
      expect(
        json.any((op) =>
            op['insert'] == '\n' &&
            (op['attributes'] as Map?)?['header'] == 1),
        true,
      );
      controller.dispose();
    });

    test('content-sniff html when no format given', () async {
      final controller = QuillController.basic();
      await QuillDocumentImporter().importText(
        controller: controller,
        text: '<p>sniffed</p>',
      );
      // After Document.fromDelta normalization, adjacent inserts merge.
      // Check the rendered plain text rather than exact ops.
      final text = controller.document.toPlainText();
      expect(text, contains('sniffed'));
      controller.dispose();
    });
  });

  group('QuillDocumentImporter.importBytes', () {
    test('docx round trips through importer', () async {
      // Build a docx via the exporter so we have valid bytes.
      final source = QuillController.basic();
      source.document.insert(0, 'Imported content\n');
      final bytes = await const DocxExporter().export(
        source.document.toDelta(),
      );
      source.dispose();

      final target = QuillController.basic();
      await QuillDocumentImporter().importBytes(
        controller: target,
        bytes: bytes,
        filename: 'sample.docx',
      );
      final text = target.document
          .toDelta()
          .toJson()
          .where((op) => op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join();
      expect(text, contains('Imported content'));
      target.dispose();
    });

    test('magic-byte sniff resolves docx without filename', () async {
      final source = QuillController.basic();
      source.document.insert(0, 'sniffed bytes\n');
      final bytes = await const DocxExporter().export(
        source.document.toDelta(),
      );
      source.dispose();

      final target = QuillController.basic();
      await QuillDocumentImporter().importBytes(
        controller: target,
        bytes: bytes,
      );
      final text = target.document
          .toDelta()
          .toJson()
          .where((op) => op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join();
      expect(text, contains('sniffed bytes'));
      target.dispose();
    });
  });

  test('defaultRegistry exposes html / markdown / docx importers', () {
    final reg = QuillDocumentImporter.defaultRegistry();
    // Every registered importer is dispatchable by format key without
    // throwing.
    expect(() => reg.importer<String, HtmlOptions>('html'), returnsNormally);
    expect(
      () => reg.importer<String, MarkdownOptions>('markdown'),
      returnsNormally,
    );
    expect(
      () => reg.importer<List<int>, DocxOptions>('docx'),
      returnsNormally,
    );
  });
}
