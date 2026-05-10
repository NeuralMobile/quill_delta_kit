import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

import 'pdf_options.dart';

/// Delta -> PDF bytes. **Stub for v0.1; throws [UnimplementedError].**
final class PdfExporter implements DeltaExporter<List<int>, PdfOptions> {
  const PdfExporter({PdfOptions? defaultOptions})
      : _defaultOptions = defaultOptions;

  final PdfOptions? _defaultOptions;

  @override
  String get format => 'pdf';

  @override
  String get mimeType => 'application/pdf';

  @override
  String get extension => 'pdf';

  @override
  PdfOptions get defaultOptions => _defaultOptions ?? const PdfOptions();

  @override
  Future<List<int>> export(Delta delta, {PdfOptions? options}) async {
    throw UnimplementedError(
      'PdfExporter is a stub in v0.1. Track via the package issue tracker.',
    );
  }
}
