import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:quill_delta_html/quill_delta_html.dart' show HtmlImporter;

/// Markdown -> HTML -> Delta. Uses `package:markdown` for the MD → HTML
/// stage, then defers to [HtmlImporter].
final class MarkdownImporter extends HtmlPivotImporter<String, MarkdownOptions>
    implements SyncDeltaImporter<String, MarkdownOptions> {
  MarkdownImporter({
    DeltaImporter<String, HtmlOptions>? htmlImporter,
    MarkdownOptions? defaultOptions,
  })  : _defaultOptions = defaultOptions,
        super(
            htmlImporter: htmlImporter ??
                HtmlImporter(
                  defaultOptions: const HtmlOptions(wrapDocument: false),
                ));

  final MarkdownOptions? _defaultOptions;

  @override
  Future<Delta> import(String input, {MarkdownOptions? options}) async {
    final delta = await super.import(input, options: options);
    return _normalize(delta);
  }

  /// Synchronous variant. Both stages (`package:markdown` → HTML, then
  /// HTML → Delta) are fully sync; this entry point skips the Future.
  ///
  /// Requires the injected [htmlImporter] to implement [SyncDeltaImporter]
  /// (the default [HtmlImporter] does). Mock importers that don't will
  /// trigger a runtime [UnsupportedError].
  @override
  Delta importSync(String input, {MarkdownOptions? options}) {
    final opts = options ?? defaultOptions;
    final html = _toHtmlSync(input, opts);
    final inner = htmlImporter;
    if (inner is! SyncDeltaImporter<String, HtmlOptions>) {
      throw UnsupportedError(
        'MarkdownImporter.importSync requires a SyncDeltaImporter inner; got ${inner.runtimeType}.',
      );
    }
    return _normalize(inner.importSync(html));
  }

  String _toHtmlSync(String input, MarkdownOptions options) {
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

  /// Strip the empty-paragraph artefacts that the `package:markdown` →
  /// HTML → Delta pipeline emits for GFM blank-line paragraph separators
  /// (`\n\n`). GFM treats `\n\n` as pure paragraph separation with no
  /// visual output — spacing is the host editor's job (DefaultStyles /
  /// CSS), not the Delta's. Without this pass, every blank line between
  /// blocks materializes as an empty Quill paragraph.
  ///
  /// Passes (run in order):
  ///   1. Drop any bare `{insert: '\n'}` (no attrs) where the preceding op
  ///      already ends with `\n`. This eats the `<p></p>` / `<br>` ghost
  ///      ops that the HTML pivot emits between adjacent blocks.
  ///   2. Strip leading `\n`s from no-attrs text ops based on the previous
  ///      op's trailing newline. If the previous op already closes its
  ///      line, leading `\n`s are pure separator noise (`<h2>X</h2><p>Y</p>`
  ///      becomes `[X, {\n header:2}, {\nY\n}]` — the `\n` before `Y` is
  ///      redundant). If the previous op doesn't close (e.g. inline bold
  ///      ending without `\n`), keep exactly one `\n` so the paragraph
  ///      break is preserved.
  ///   3. Collapse trailing `\n+` in the final string op down to a single
  ///      `\n`, and drop trailing bare `{insert: '\n'}` ops whose role is
  ///      already filled by the preceding op's trailing newline. These
  ///      come from `package:markdown` always closing the document with a
  ///      `<p>...</p>\n` wrapper.
  static Delta _normalize(Delta input) {
    final ops = List<Map<String, dynamic>>.from(input.toJson());
    if (ops.isEmpty) return input;

    bool endsWithNewline(Map<String, dynamic> op) {
      final v = op['insert'];
      return v is String && v.endsWith('\n');
    }

    // Pass 1: drop interior blank-paragraph ops.
    for (var i = ops.length - 1; i >= 1; i--) {
      final op = ops[i];
      if (op['attributes'] != null) continue;
      if (op['insert'] != '\n') continue;
      if (endsWithNewline(ops[i - 1])) {
        ops.removeAt(i);
      }
    }

    // Pass 2: strip leading newlines from no-attrs text ops.
    for (var i = 1; i < ops.length; i++) {
      final op = ops[i];
      if (op['attributes'] != null) continue;
      final insert = op['insert'];
      if (insert is! String) continue;
      if (!insert.startsWith('\n')) continue;
      var n = 0;
      while (n < insert.length && insert.codeUnitAt(n) == 0x0A) {
        n++;
      }
      // Pure-newline ops are handled by pass 1; skip here.
      if (n == insert.length) continue;
      final prevEnds = endsWithNewline(ops[i - 1]);
      final keep = prevEnds ? 0 : 1;
      if (n > keep) {
        ops[i] = {'insert': '\n' * keep + insert.substring(n)};
      }
    }

    // Pass 3a: collapse trailing newlines in the final string op.
    final last = ops.last;
    final lastInsert = last['insert'];
    if (lastInsert is String && lastInsert.endsWith('\n\n')) {
      final trimmed = lastInsert.replaceAll(RegExp(r'\n+$'), '\n');
      ops[ops.length - 1] = {
        'insert': trimmed,
        if (last['attributes'] != null) 'attributes': last['attributes'],
      };
    }

    // Pass 3b: drop trailing bare-newline ops whose role is already filled.
    while (ops.length > 1 &&
        ops.last['attributes'] == null &&
        ops.last['insert'] == '\n' &&
        endsWithNewline(ops[ops.length - 2])) {
      ops.removeLast();
    }

    return Delta.fromJson(ops);
  }

  @override
  String get format => 'markdown';

  @override
  Set<String> get mimeTypes => const {'text/markdown', 'text/x-markdown'};

  @override
  Set<String> get extensions => const {'md', 'markdown', 'mdown', 'mkd'};

  @override
  MarkdownOptions get defaultOptions =>
      _defaultOptions ?? const MarkdownOptions();

  @override
  Future<String> toHtml(String input, MarkdownOptions options) async =>
      _toHtmlSync(input, options);
}
