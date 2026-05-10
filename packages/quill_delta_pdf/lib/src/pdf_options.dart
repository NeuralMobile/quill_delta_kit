import 'package:quill_delta_core/quill_delta_core.dart';

/// Page size for PDF output.
enum PdfPageSize { a4, letter, legal }

/// Options for the (planned) PDF importer and exporter.
class PdfOptions extends ConverterOptions {
  const PdfOptions({
    this.pageSize = PdfPageSize.a4,
    this.embedFonts = true,
    this.compress = true,
    super.unknownEmbedFallback,
  });

  final PdfPageSize pageSize;
  final bool embedFonts;
  final bool compress;
}
