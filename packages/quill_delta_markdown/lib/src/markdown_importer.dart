import 'package:dart_quill_delta/dart_quill_delta.dart';
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
  Future<Delta> import(String input, {MarkdownOptions? options}) async {
    final delta = await super.import(input, options: options);
    return _normalizeTrailing(delta);
  }

  /// `package:markdown` wraps paragraphs in `<p>...</p>` with trailing
  /// whitespace, which the HTML decoder turns into spurious trailing
  /// newline ops. Drop them so the round trip is clean.
  ///
  /// Rules:
  ///   1. While the last op is a bare `{insert: '\n'}` (no attrs) and the
  ///      previous op's insert already ends with `\n` (line is closed),
  ///      drop the last op.
  ///   2. Collapse runs of trailing `\n` within the final string-only op
  ///      down to a single `\n`.
  static Delta _normalizeTrailing(Delta input) {
    final ops = List<Map<String, dynamic>>.from(input.toJson());
    if (ops.isEmpty) return input;

    bool _isBareNewline(Map<String, dynamic> op) {
      return op['attributes'] == null && op['insert'] == '\n';
    }

    bool _endsWithNewline(Map<String, dynamic> op) {
      final v = op['insert'];
      return v is String && v.endsWith('\n');
    }

    while (ops.length > 1 &&
        _isBareNewline(ops.last) &&
        _endsWithNewline(ops[ops.length - 2])) {
      ops.removeLast();
    }

    final last = ops.last;
    final lastInsert = last['insert'];
    if (lastInsert is String && lastInsert.endsWith('\n\n')) {
      final trimmed = lastInsert.replaceAll(RegExp(r'\n+$'), '\n');
      ops[ops.length - 1] = {
        'insert': trimmed,
        if (last['attributes'] != null) 'attributes': last['attributes'],
      };
    }
    return Delta.fromJson(ops);
  }

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
