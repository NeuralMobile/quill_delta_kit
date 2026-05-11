import 'package:dart_quill_delta/dart_quill_delta.dart';

/// One Delta op, possibly with a substring of the original insert text.
///
/// **Attribute shape contract.** [attributes] is the same
/// `Map<String, dynamic>` shape used by upstream `dart_quill_delta` —
/// keys are Quill attribute names ('bold', 'italic', 'color', 'header',
/// 'list', …) and values follow Quill's per-attribute conventions
/// (`true`/`null` for toggles, hex / `rgb()` / `rgba()` strings for colors,
/// integer-coercible values for header levels, …). The map's `dynamic`
/// value type mirrors upstream; callers should read via guarded `is`
/// checks before downcasting (`attrs?['bold'] == true`,
/// `attrs?['header'] is num`).
class InlineOp {
  InlineOp({required this.data, this.attributes});

  /// Either a String fragment or a Map (embed payload).
  final Object data;
  final Map<String, dynamic>? attributes;

  bool get isEmbed => data is Map;
  bool get isText => data is String;
  String get asText => data as String;
  Map<String, dynamic> get asEmbed => (data as Map).cast<String, dynamic>();
}

/// One line = a sequence of inline ops + the block attributes from the trailing `\n`.
///
/// [blockAttrs] follows the same dynamic-valued shape as [InlineOp.attributes]
/// but is filtered to block-level keys (header, list, blockquote, code-block,
/// indent, align, direction, line-height).
class Line {
  Line({required this.ops, this.blockAttrs});

  final List<InlineOp> ops;
  final Map<String, dynamic>? blockAttrs;

  /// Empty line marker. blockAttrs == null and ops empty => `\n` with no attrs.
  bool get isEmpty => ops.isEmpty;
}

/// Split a Delta into a list of [Line]s.
///
/// Quill convention: text inserts that contain `\n` may carry both inline
/// content (before the `\n`) and a block attribute (on the `\n` itself).
/// We split each text insert on `\n`. For every chunk before a newline we emit
/// the text as inline. When we hit a newline we close the current line, attach
/// the op's attributes as the block attrs (filtered to block keys), and start
/// a fresh line.
List<Line> splitIntoLines(Delta delta) {
  final out = <Line>[];
  var current = <InlineOp>[];

  void flush(Map<String, dynamic>? blockAttrs) {
    out.add(Line(ops: current, blockAttrs: blockAttrs));
    current = <InlineOp>[];
  }

  for (final op in delta.operations) {
    if (!op.isInsert) continue;
    final data = op.data;
    final attrs = op.attributes;

    if (data is String) {
      var start = 0;
      for (var i = 0; i < data.length; i++) {
        if (data.codeUnitAt(i) != 0x0A) continue;
        // Text before newline -> inline op (may be empty for back-to-back \n).
        if (i > start) {
          current
              .add(InlineOp(data: data.substring(start, i), attributes: attrs));
        }
        // Block attrs come from this op's attributes (block-keyed subset).
        flush(_extractBlockAttrs(attrs));
        start = i + 1;
      }
      if (start < data.length) {
        current.add(InlineOp(data: data.substring(start), attributes: attrs));
      }
    } else if (data is Map) {
      current.add(InlineOp(data: data, attributes: attrs));
    }
  }
  if (current.isNotEmpty) {
    flush(null);
  }
  return out;
}

const _blockKeys = <String>{
  'header',
  'list',
  'blockquote',
  'code-block',
  'indent',
  'align',
  'direction',
  'line-height',
};

Map<String, dynamic>? _extractBlockAttrs(Map<String, dynamic>? attrs) {
  if (attrs == null || attrs.isEmpty) return null;
  Map<String, dynamic>? out;
  for (final entry in attrs.entries) {
    if (_blockKeys.contains(entry.key)) {
      (out ??= <String, dynamic>{})[entry.key] = entry.value;
    }
  }
  return out;
}
