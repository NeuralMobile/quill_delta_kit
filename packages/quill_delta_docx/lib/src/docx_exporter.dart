import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

import 'ooxml_builder.dart';
import 'ooxml_parts.dart';

/// Delta -> .docx bytes.
///
/// Produces a valid OOXML package with:
///   - `[Content_Types].xml`
///   - `_rels/.rels`
///   - `word/document.xml`
///   - `word/_rels/document.xml.rels` (hyperlink relationships)
///   - `word/styles.xml`
///   - `word/numbering.xml`
///
/// Out of scope for v0.1: images, comments, track changes, footnotes,
/// embedded objects, themes, fontTable, sections.
final class DocxExporter
    implements
        DeltaExporter<List<int>, DocxOptions>,
        SyncDeltaExporter<List<int>, DocxOptions> {
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
    return exportSync(delta, options: options);
  }

  /// Synchronous variant. ZIP construction is fully synchronous.
  @override
  List<int> exportSync(Delta delta, {DocxOptions? options}) {
    final result = buildOoxmlBody(delta);
    final documentXml = buildDocumentXml(result.bodyXml);
    final documentRelsXml = buildDocumentRelsXml(result.hyperlinks);

    final archive = Archive();
    void add(String path, String content) {
      // UTF-8 encode so non-ASCII XML content (e.g. "•" in numbering.xml,
      // user text with emoji) survives the ZIP roundtrip. codeUnits would
      // silently truncate any code unit > 0xFF.
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    add('[Content_Types].xml', contentTypesXml);
    add('_rels/.rels', rootRelsXml);
    add('word/document.xml', documentXml);
    add('word/_rels/document.xml.rels', documentRelsXml);
    add('word/styles.xml', stylesXml);
    add('word/numbering.xml', numberingXml);

    return ZipEncoder().encode(archive);
  }
}
