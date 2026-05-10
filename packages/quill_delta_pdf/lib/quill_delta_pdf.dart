/// Quill Delta -> PDF export and PDF -> Delta import.
///
/// **STATUS: planned, not yet implemented.**
///
/// The package reserves the namespace and ships:
///   - [PdfOptions] so callers can wire up options ahead of implementation
///   - [PdfImporter] / [PdfExporter] stubs that throw [UnimplementedError]
///
/// The full implementation is tracked in the issue tracker. PDF round trip
/// is fundamentally lossy (PDF has no native concept of inline marks like
/// bold-as-attribute; everything is shapes/glyphs) so the design will be
/// approximate-fidelity (extracting text + best-effort structure on import,
/// rendering Delta to vector PDF on export).
library quill_delta_pdf;

export 'package:quill_delta_core/quill_delta_core.dart';

export 'src/pdf_exporter.dart';
export 'src/pdf_importer.dart';
export 'src/pdf_options.dart';
