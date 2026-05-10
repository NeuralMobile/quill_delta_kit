import 'package:markdown/markdown.dart' as md;
import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:quill_delta_html/quill_delta_html.dart' show HtmlImporter;

/// Markdown -> HTML -> Delta. Uses `package:markdown` for the MD → HTML
/// stage, then defers to [HtmlImporter].
final class MarkdownImporter
    extends HtmlPivotImporter<String, MarkdownOptions> {
  MarkdownImporter({
    DeltaImporter<String, HtmlOptions>? htmlImporter,
    MarkdownOptions? defaultOptions,
  })  : _defaultOptions = defaultOptions,
        super(htmlImporter: htmlImporter ?? HtmlImporter(
          defaultOptions: const HtmlOptions(wrapDocument: false),
        ));

  final MarkdownOptions? _defaultOptions;

  @override
  String get format => 'markdown';

  @override
  Set<String> get mimeTypes =>
      const {'text/markdown', 'text/x-markdown'};

  @override
  Set<String> get extensions => const {'md', 'markdown', 'mdown', 'mkd'};

  @override
  MarkdownOptions get defaultOptions =>
      _defaultOptions ?? const MarkdownOptions();

  @override
  Future<String> toHtml(String input, MarkdownOptions options) async {
    final extensions = options.flavour == MarkdownFlavour.gfm
        ? md.ExtensionSet.gitHubFlavored
        : md.ExtensionSet.commonMark;
    return md.markdownToHtml(
      input,
      extensionSet: extensions,
      inlineSyntaxes: options.flavour == MarkdownFlavour.gfm
          ? [md.InlineHtmlSyntax()]
          : const [],
    );
  }
}
