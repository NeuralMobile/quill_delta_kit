import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';
import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';

/// High-level helper that converts external documents (HTML / Markdown /
/// Docx / PDF) into a [Delta] and loads it into a [QuillController].
///
/// Wraps the converter family's [ConverterRegistry] with a single API
/// suited to UI flows:
///
/// ```dart
/// final importer = QuillDocumentImporter();
/// // From a file picker:
/// await importer.importBytes(
///   controller: controller,
///   bytes: pickedFile.bytes!,
///   filename: pickedFile.name,            // "report.docx"
/// );
/// // Or directly from text:
/// await importer.importText(
///   controller: controller,
///   text: '# Title\nbody',
///   format: 'markdown',
/// );
/// ```
///
/// Use [QuillDocumentImporter.defaults] (the default constructor) for the
/// standard registry. Inject a custom [registry] when you want to register
/// extra adapters (custom embeds, alternative MIME mappings) before
/// importing.
class QuillDocumentImporter {
  QuillDocumentImporter({ConverterRegistry? registry})
      : registry = registry ?? defaultRegistry();

  /// Wraps the registry actually used. The registry is mutable — register
  /// additional importers by calling [ConverterRegistry.registerImporter].
  final ConverterRegistry registry;

  /// Build a [ConverterRegistry] preloaded with HTML, Markdown, and Docx
  /// importers. PDF intentionally absent (the importer is a stub that
  /// throws [UnimplementedError]; surface that only when explicitly
  /// requested).
  static ConverterRegistry defaultRegistry() => ConverterRegistry(
        importers: [
          HtmlImporter(),
          MarkdownImporter(),
          DocxImporter(),
        ],
      );

  /// Convert binary [bytes] (.docx, .pdf future) into a [Delta] and load
  /// it into [controller]. Format detection order:
  ///   1. explicit [format]
  ///   2. [mime]
  ///   3. [filename] extension
  ///   4. magic-byte sniff
  Future<void> importBytes({
    required QuillController controller,
    required List<int> bytes,
    String? format,
    String? mime,
    String? filename,
  }) async {
    final delta = await registry.importAuto(
      bytes,
      format: format,
      mime: mime,
      filename: filename,
    );
    _load(controller, delta);
  }

  /// Convert [text] (HTML / Markdown / plain) into a [Delta] and load it
  /// into [controller].
  Future<void> importText({
    required QuillController controller,
    required String text,
    String? format,
    String? mime,
  }) async {
    final delta = await registry.importAuto(text, format: format, mime: mime);
    _load(controller, delta);
  }

  /// Replace [controller]'s document with one built from [delta].
  static void _load(QuillController controller, Delta delta) {
    controller.document = Document.fromDelta(_ensureTrailingNewline(delta));
  }

  /// Quill documents must end with a `\n` op. Appends one when the input
  /// Delta doesn't already finish with a newline; otherwise the editor
  /// asserts.
  static Delta _ensureTrailingNewline(Delta delta) {
    if (delta.operations.isEmpty) {
      return Delta()..insert('\n');
    }
    final last = delta.operations.last;
    if (last.isInsert &&
        last.data is String &&
        (last.data as String).endsWith('\n')) {
      return delta;
    }
    return delta..insert('\n');
  }
}
