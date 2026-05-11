import 'package:meta/meta.dart';

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
@immutable
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

  DocxOptions copyWith({
    bool? preserveTrackChanges,
    DocxImageEmbed? imageEmbed,
    DocxPageSize? pageSize,
    bool? extractCommentsAsSideNotes,
    String? defaultFontFamily,
    double? defaultFontSizePt,
    bool? expandMergedCells,
    UnknownEmbedFallback? unknownEmbedFallback,
  }) {
    return DocxOptions(
      preserveTrackChanges: preserveTrackChanges ?? this.preserveTrackChanges,
      imageEmbed: imageEmbed ?? this.imageEmbed,
      pageSize: pageSize ?? this.pageSize,
      extractCommentsAsSideNotes:
          extractCommentsAsSideNotes ?? this.extractCommentsAsSideNotes,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
      defaultFontSizePt: defaultFontSizePt ?? this.defaultFontSizePt,
      expandMergedCells: expandMergedCells ?? this.expandMergedCells,
      unknownEmbedFallback: unknownEmbedFallback ?? this.unknownEmbedFallback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocxOptions &&
        preserveTrackChanges == other.preserveTrackChanges &&
        imageEmbed == other.imageEmbed &&
        pageSize == other.pageSize &&
        extractCommentsAsSideNotes == other.extractCommentsAsSideNotes &&
        defaultFontFamily == other.defaultFontFamily &&
        defaultFontSizePt == other.defaultFontSizePt &&
        expandMergedCells == other.expandMergedCells &&
        unknownEmbedFallback == other.unknownEmbedFallback;
  }

  @override
  int get hashCode => Object.hash(
        preserveTrackChanges,
        imageEmbed,
        pageSize,
        extractCommentsAsSideNotes,
        defaultFontFamily,
        defaultFontSizePt,
        expandMergedCells,
        unknownEmbedFallback,
      );
}
