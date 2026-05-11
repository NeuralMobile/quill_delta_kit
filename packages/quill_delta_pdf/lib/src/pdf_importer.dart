import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

import 'pdf_options.dart';

/// PDF bytes -> Delta. **Stub for v0.1.**
///
/// PDF lacks a document model — it stores glyphs at fixed page coordinates
/// rather than paragraphs or sections — so faithful structural import is
/// outside this release's scope. Calling [import] always throws
/// [UnsupportedFormatException].
final class PdfImporter implements DeltaImporter<List<int>, PdfOptions> {
  const PdfImporter({PdfOptions? defaultOptions}) : _defaultOptions = defaultOptions;

  final PdfOptions? _defaultOptions;

  @override
  String get format => 'pdf';

  @override
  Set<String> get mimeTypes => const {'application/pdf'};

  @override
  Set<String> get extensions => const {'pdf'};

  @override
  PdfOptions get defaultOptions => _defaultOptions ?? const PdfOptions();

  @override
  Future<Delta> import(List<int> input, {PdfOptions? options}) async {
    throw UnsupportedFormatException(
      'pdf',
      'PDF import is not yet supported. Track via the package issue tracker.',
    );
  }
}
