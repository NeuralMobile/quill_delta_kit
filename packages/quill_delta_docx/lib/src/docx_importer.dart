import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:quill_delta_html/quill_delta_html.dart' show HtmlImporter;

import 'ooxml_to_html.dart';

/// .docx bytes -> Delta. Pivots through HTML.
final class DocxImporter extends HtmlPivotImporter<List<int>, DocxOptions> {
  DocxImporter({
    DeltaImporter<String, HtmlOptions>? htmlImporter,
    DocxOptions? defaultOptions,
  })  : _defaultOptions = defaultOptions,
        super(
            htmlImporter: htmlImporter ??
                HtmlImporter(
                  defaultOptions: const HtmlOptions(wrapDocument: false),
                ));

  final DocxOptions? _defaultOptions;

  @override
  String get format => 'docx';

  @override
  Set<String> get mimeTypes => const {
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/msword',
      };

  @override
  Set<String> get extensions => const {'docx'};

  @override
  DocxOptions get defaultOptions => _defaultOptions ?? const DocxOptions();

  @override
  Future<String> toHtml(List<int> input, DocxOptions options) async {
    return docxToHtml(input);
  }
}
