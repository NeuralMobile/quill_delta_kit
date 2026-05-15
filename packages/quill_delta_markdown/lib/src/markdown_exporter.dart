import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

import 'markdown_embed_adapter.dart';

/// Delta -> Markdown. Native walker over `splitIntoLines` output. No HTML
/// pivot, so format-specific decisions (fenced code, GFM tables, task lists)
/// are made directly.
final class MarkdownExporter
    implements
        DeltaExporter<String, MarkdownOptions>,
        SyncDeltaExporter<String, MarkdownOptions> {
  const MarkdownExporter({
    MarkdownOptions? defaultOptions,
    MarkdownEmbedRegistry? embedRegistry,
  })  : _defaultOptions = defaultOptions,
        _embedRegistry = embedRegistry;

  final MarkdownOptions? _defaultOptions;
  final MarkdownEmbedRegistry? _embedRegistry;

  @override
  String get format => 'markdown';

  @override
  String get mimeType => 'text/markdown';

  @override
  String get extension => 'md';

  @override
  MarkdownOptions get defaultOptions =>
      _defaultOptions ?? const MarkdownOptions();

  @override
  Future<String> export(Delta delta, {MarkdownOptions? options}) async {
    return exportSync(delta, options: options);
  }

  /// Synchronous variant.
  @override
  String exportSync(Delta delta, {MarkdownOptions? options}) {
    final opts = options ?? defaultOptions;
    final lines = splitIntoLines(delta);
    final buf = StringBuffer();
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final block = line.blockAttrs ?? const <String, dynamic>{};

      // Code block: group consecutive code-block lines into one fence.
      if (_truthy(block['code-block'])) {
        final lang = block['code-block'] is String &&
                block['code-block'] != 'true' &&
                (block['code-block'] as String).isNotEmpty
            ? block['code-block'] as String
            : '';
        buf.write('```');
        if (opts.fencedCodeBlockInfoString && lang.isNotEmpty) {
          buf.write(lang);
        }
        buf.write('\n');
        while (i < lines.length) {
          final l = lines[i];
          final cb = l.blockAttrs?['code-block'];
          if (cb == null || cb == false) break;
          for (final op in l.ops) {
            if (op.isText) buf.write(op.asText);
          }
          buf.write('\n');
          i++;
        }
        buf.write('```\n\n');
        continue;
      }

      // Blockquote: each line gets a leading "> ".
      if (_truthy(block['blockquote'])) {
        while (i < lines.length) {
          final l = lines[i];
          final bb = l.blockAttrs ?? const <String, dynamic>{};
          if (!_truthy(bb['blockquote'])) break;
          buf.write('> ');
          _writeInline(l.ops, buf, opts);
          buf.write('\n');
          i++;
        }
        buf.write('\n');
        continue;
      }

      // Header.
      final header = block['header'];
      if (header is num) {
        final level = header.toInt().clamp(1, 6);
        buf.write('#' * level);
        buf.write(' ');
        _writeInline(line.ops, buf, opts);
        buf.write('\n\n');
        i++;
        continue;
      }

      // List.
      if (block['list'] != null) {
        i = _writeListGroup(lines, i, buf, opts);
        buf.write('\n');
        continue;
      }

      // Empty paragraph -> blank line.
      if (line.ops.isEmpty) {
        buf.write('\n');
        i++;
        continue;
      }

      // Plain paragraph.
      _writeInline(line.ops, buf, opts);
      buf.write('\n\n');
      i++;
    }
    // Trim trailing blank lines but preserve a single final newline.
    var s = buf.toString();
    s = s.replaceAll(RegExp(r'\n+$'), '');
    if (s.isNotEmpty) s += '\n';
    return s;
  }

  int _writeListGroup(
    List<Line> lines,
    int start,
    StringBuffer buf,
    MarkdownOptions opts,
  ) {
    final orderedCounters = <int, int>{};
    var i = start;
    while (i < lines.length) {
      final line = lines[i];
      final attrs = line.blockAttrs ?? const <String, dynamic>{};
      final type = attrs['list']?.toString();
      if (type == null) break;
      final indent =
          (attrs['indent'] is num) ? (attrs['indent'] as num).toInt() : 0;
      buf.write('  ' * indent);
      switch (type) {
        case 'ordered':
          final n = (orderedCounters[indent] ??= 0) + 1;
          orderedCounters[indent] = n;
          buf.write('$n. ');
          break;
        case 'checked':
          buf.write('- [x] ');
          break;
        case 'unchecked':
          buf.write('- [ ] ');
          break;
        default:
          buf.write('- ');
      }
      // Reset deeper-level counters when we surface back to a shallower
      // level so re-entering a deeper level restarts numbering.
      orderedCounters.removeWhere((k, _) => k > indent);
      _writeInline(line.ops, buf, opts);
      buf.write('\n');
      i++;
    }
    return i;
  }

  void _writeInline(
      List<InlineOp> ops, StringBuffer buf, MarkdownOptions opts) {
    for (final op in ops) {
      if (op.isEmbed) {
        _writeEmbed(op, buf, opts);
        continue;
      }
      final text = op.asText;
      final attrs = op.attributes ?? const <String, dynamic>{};
      var s = _escapeMd(text);
      // Wrap order: code (innermost) -> strike -> italic -> bold -> link.
      if (_truthy(attrs['code'])) s = '`$s`';
      if (_truthy(attrs['strike'])) s = '~~$s~~';
      if (_truthy(attrs['italic'])) s = '*$s*';
      if (_truthy(attrs['bold'])) s = '**$s**';
      final link = attrs['link']?.toString();
      if (link != null && link.isNotEmpty) {
        s = '[$s]($link)';
      }
      buf.write(s);
    }
  }

  void _writeEmbed(InlineOp op, StringBuffer buf, MarkdownOptions opts) {
    final embed = op.asEmbed;
    if (embed.isEmpty) return;
    final type = embed.keys.first;
    final value = embed[type];

    // Format-native adapter beats built-in handling.
    final adapter = _embedRegistry?.forType(type);
    if (adapter != null) {
      adapter.encodeMarkdown(
        buf: buf,
        value: value,
        siblingAttrs: op.attributes,
        options: opts,
      );
      return;
    }

    switch (type) {
      case 'image':
        final src = value is String ? value : '';
        if (src.isNotEmpty) buf.write('![]($src)');
        break;
      case 'divider':
      case 'hr':
        buf.write('\n---\n');
        break;
      default:
        if (opts.allowHtmlPassthrough) {
          buf.write('<!-- $type -->');
        }
    }
  }

  // Inline-significant characters only. Block-level markers (`#`, `+`, `-`,
  // `>`) are written by the block writers at line start, so they don't need
  // escaping when they appear mid-paragraph. Parentheses are only structural
  // inside link targets (`[text](url)`) where the escape on `]` already
  // disambiguates. Braces and `!` carry no structural meaning in CommonMark
  // outside of `${...}` (template) and `![](...)` (image), neither of which
  // arise from plain text. Aggressive escaping here corrupts text across
  // round-trips (each save adds another backslash).
  static final _mdEscape = RegExp(r'([\\`*_\[\]#+!|<>])');

  static String _escapeMd(String s) =>
      s.replaceAllMapped(_mdEscape, (m) => '\\${m[0]}');

  static bool _truthy(Object? v) =>
      v == true ||
      v == 'true' ||
      v == 1 ||
      (v is String && v.isNotEmpty && v != 'false');
}
