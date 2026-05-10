import '../converter_options.dart';

/// How embedded images are stored inside the produced .docx archive.
enum DocxImageEmbed {
  /// Store image bytes as a relationship part inside the .docx ZIP.
  embedded,

  /// Store a data-URI (smaller code path; some renderers reject).
  dataUri,

  /// Replace data-URI images with placeholder; keep http/https as external.
  externalOrPlaceholder,
}

/// Page size for layout.
enum DocxPageSize { a4, letter, legal }

/// Options for the Docx importer and exporter.
class DocxOptions extends ConverterOptions {
  const DocxOptions({
    this.preserveTrackChanges = false,
    this.imageEmbed = DocxImageEmbed.embedded,
    this.pageSize = DocxPageSize.a4,
    this.extractCommentsAsSideNotes = false,
    this.defaultFontFamily = 'Calibri',
    this.defaultFontSizePt = 11,
    this.expandMergedCells = true,
    super.unknownEmbedFallback,
  });

  /// When true, Word `<w:ins>`/`<w:del>` track-changes are preserved as
  /// passthrough embeds rather than resolved to the accepted version.
  final bool preserveTrackChanges;

  /// Image storage strategy.
  final DocxImageEmbed imageEmbed;

  /// Page size written into `<w:pgSz>`.
  final DocxPageSize pageSize;

  /// When true, Word comments become inline Delta `comment` attributes
  /// rather than being dropped.
  final bool extractCommentsAsSideNotes;

  /// Default font family for runs without an explicit font.
  final String defaultFontFamily;

  /// Default font size in typographic points.
  final double defaultFontSizePt;

  /// When true (default), merged table cells are expanded; merge metadata
  /// is lost. When false, merge info is stored in a passthrough attribute.
  final bool expandMergedCells;
}
