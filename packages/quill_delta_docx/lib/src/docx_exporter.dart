import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

/// Delta -> .docx bytes.
///
/// Stub for v0.1. Writing OOXML round-trip is a large task — track-changes,
/// images, tables, styles, numbering definitions, sections, comments,
/// content-types.xml, _rels, themes — we ship the importer first and
/// implement the exporter incrementally.
final class DocxExporter
    implements DeltaExporter<List<int>, DocxOptions> {
  const DocxExporter({DocxOptions? defaultOptions})
      : _defaultOptions = defaultOptions;

  final DocxOptions? _defaultOptions;

  @override
  String get format => 'docx';

  @override
  String get mimeType =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  @override
  String get extension => 'docx';

  @override
  DocxOptions get defaultOptions => _defaultOptions ?? const DocxOptions();

  @override
  Future<List<int>> export(Delta delta, {DocxOptions? options}) async {
    throw UnimplementedError(
      'DocxExporter is not implemented in v0.1. '
      'Track via the package issue tracker. '
      'For now use HtmlExporter then a third-party HTML -> DOCX tool.',
    );
  }
}
