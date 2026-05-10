import 'package:dart_quill_delta/dart_quill_delta.dart';

/// One Delta op, possibly with a substring of the original insert text.
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

  for (final op in delta.toList()) {
    if (!op.isInsert) continue;
    final data = op.data;
    final attrs = op.attributes;

    if (data is String) {
      var start = 0;
      for (var i = 0; i < data.length; i++) {
        if (data.codeUnitAt(i) != 0x0A) continue;
        // Text before newline -> inline op (may be empty for back-to-back \n).
        if (i > start) {
          current.add(InlineOp(data: data.substring(start, i), attributes: attrs));
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
  if (attrs == null) return null;
  final out = <String, dynamic>{};
  for (final entry in attrs.entries) {
    if (_blockKeys.contains(entry.key)) out[entry.key] = entry.value;
  }
  return out.isEmpty ? null : out;
}
