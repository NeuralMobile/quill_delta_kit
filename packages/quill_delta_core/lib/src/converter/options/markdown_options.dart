import '../converter_options.dart';

/// Markdown dialect.
enum MarkdownFlavour {
  /// CommonMark — strict spec, no extensions.
  commonmark,

  /// GitHub Flavoured Markdown — tables, task lists, strikethrough,
  /// fenced code with language tags, autolinks.
  gfm,
}

/// Strategy for embedded images in Markdown output.
enum MarkdownImageStrategy {
  /// Standard `![alt](url)` syntax.
  inline,

  /// Reference-style links collected at the end of the document.
  referenceList,

  /// Drop data-URI images; keep http/https.
  dropDataUri,
}

/// Options for the Markdown importer and exporter.
class MarkdownOptions extends ConverterOptions {
  const MarkdownOptions({
    this.flavour = MarkdownFlavour.gfm,
    this.allowHtmlPassthrough = true,
    this.hardLineBreak = false,
    this.imageStrategy = MarkdownImageStrategy.inline,
    this.fencedCodeBlockInfoString = true,
    this.tableAlignment = true,
    super.unknownEmbedFallback,
  });

  /// Target dialect. Default GFM.
  final MarkdownFlavour flavour;

  /// When true, raw HTML in the source survives as inline HTML; when false,
  /// HTML tags are stripped and only their text content kept.
  final bool allowHtmlPassthrough;

  /// When true, soft breaks (`\n` inside a paragraph) emit Markdown hard
  /// line breaks (two trailing spaces + newline). Default: false.
  final bool hardLineBreak;

  /// How embedded images are emitted.
  final MarkdownImageStrategy imageStrategy;

  /// Annotate fenced code with language ` ```dart `. Default true.
  final bool fencedCodeBlockInfoString;

  /// Emit GFM table alignment markers when [flavour] is [MarkdownFlavour.gfm].
  final bool tableAlignment;
}
