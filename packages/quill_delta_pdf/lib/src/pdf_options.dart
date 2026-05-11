import 'package:meta/meta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

/// Page size for PDF output.
enum PdfPageSize { a4, letter, legal }

/// Options for the (planned) PDF importer and exporter.
@immutable
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

  PdfOptions copyWith({
    PdfPageSize? pageSize,
    bool? embedFonts,
    bool? compress,
    UnknownEmbedFallback? unknownEmbedFallback,
  }) {
    return PdfOptions(
      pageSize: pageSize ?? this.pageSize,
      embedFonts: embedFonts ?? this.embedFonts,
      compress: compress ?? this.compress,
      unknownEmbedFallback: unknownEmbedFallback ?? this.unknownEmbedFallback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PdfOptions &&
        pageSize == other.pageSize &&
        embedFonts == other.embedFonts &&
        compress == other.compress &&
        unknownEmbedFallback == other.unknownEmbedFallback;
  }

  @override
  int get hashCode =>
      Object.hash(pageSize, embedFonts, compress, unknownEmbedFallback);
}
