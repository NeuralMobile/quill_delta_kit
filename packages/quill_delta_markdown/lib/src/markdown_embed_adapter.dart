import 'package:quill_delta_core/quill_delta_core.dart';

/// Format-native embed adapter for Markdown.
///
/// Unlike the HTML adapter, encode targets a [StringBuffer] (the in-flight
/// markdown output) and decode receives the raw substring matched by the
/// adapter's [pattern]. Adapters that need access to the surrounding
/// markdown context can capture state via the registry singleton.
///
/// Why a parallel hierarchy instead of generic `<TNode>`: markdown decoding
/// is line/regex driven, not tree-walking like HTML, so the natural
/// interfaces diverge. Force-fitting both into one signature complicates
/// every implementation.
abstract class MarkdownEmbedAdapter extends EmbedAdapterBase<MarkdownOptions> {
  /// Regex matched against each markdown line during import. Capture group 1
  /// (when present) is passed to [decode] so adapters don't need to re-parse.
  /// Return null to use full-match dispatch via [matchesText] only.
  RegExp? get pattern;

  /// Encode a Delta embed into [buf]. Caller has already written any
  /// surrounding inline formatting; the adapter writes only its own glyph.
  void encodeMarkdown({
    required StringBuffer buf,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required MarkdownOptions options,
  });

  /// True if [text] should be handled by this adapter when [pattern] is null.
  /// Default returns false (pattern-only matching).
  bool matchesText(String text) => false;

  /// Decode the matched substring (or capture group 1) into a Delta op JSON
  /// map: `{"insert": {<type>: <data>}, "attributes": {...}?}`.
  Map<String, dynamic>? decodeMarkdown(
    String matched,
    MarkdownOptions options,
  );
}

/// Registry of markdown embed adapters. Format packages manage their own
/// registries; cross-format embed handling lives in each format.
class MarkdownEmbedRegistry {
  MarkdownEmbedRegistry({List<MarkdownEmbedAdapter> adapters = const []}) : _adapters = List.of(adapters);

  final List<MarkdownEmbedAdapter> _adapters;

  void register(MarkdownEmbedAdapter adapter) => _adapters.add(adapter);

  Iterable<MarkdownEmbedAdapter> get all => _adapters;

  MarkdownEmbedAdapter? forType(String type) {
    for (final a in _adapters) {
      if (a.type == type) return a;
    }
    return null;
  }

  /// Iterate each adapter's pattern over [text] left-to-right, returning the
  /// first match encountered as `(adapter, match start, match end, op)`. The
  /// caller writes any preceding plain-text segment, then emits the embed
  /// op, then continues from `end`.
  MarkdownEmbedMatch? firstMatchIn(String text, MarkdownOptions options) {
    MarkdownEmbedMatch? best;
    for (final a in _adapters) {
      final pat = a.pattern;
      if (pat == null) continue;
      final m = pat.firstMatch(text);
      if (m == null) continue;
      if (best == null || m.start < best.start) {
        final captured = m.groupCount >= 1 ? m.group(1) ?? m[0]! : m[0]!;
        final op = a.decodeMarkdown(captured, options);
        if (op != null) {
          best = MarkdownEmbedMatch(
            adapter: a,
            start: m.start,
            end: m.end,
            op: op,
          );
        }
      }
    }
    return best;
  }
}

class MarkdownEmbedMatch {
  const MarkdownEmbedMatch({
    required this.adapter,
    required this.start,
    required this.end,
    required this.op,
  });
  final MarkdownEmbedAdapter adapter;
  final int start;
  final int end;
  final Map<String, dynamic> op;
}
