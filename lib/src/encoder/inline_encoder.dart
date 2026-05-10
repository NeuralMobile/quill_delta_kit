import 'dart:convert';

import '../css/color.dart';
import '../css/size.dart';
import '../css/style_parser.dart';
import '../embeds/registry.dart';
import '../options.dart';
import '../util/html_writer.dart';
import 'line_splitter.dart';

/// Emit one [InlineOp] into [writer] as HTML.
class InlineEncoder {
  InlineEncoder(this.registry, this.options);

  final EmbedRegistry registry;
  final QuillHtmlOptions options;

  /// Reusable scratch buffer for the open-tag stack so we don't allocate
  /// a fresh List per text op. Cleared at start of every emit.
  final List<String> _stack = <String>[];

  void emit(InlineOp op, HtmlWriter writer) {
    if (op.isEmbed) {
      _emitEmbed(op, writer);
      return;
    }
    final text = op.asText;
    if (text.isEmpty) return;
    final attrs = op.attributes ?? const <String, dynamic>{};

    _stack.clear();

    // Order matches the previous DOM-based wrapping which built innermost
    // first: we now append open tags from innermost to outermost so the
    // emitted HTML has the same nesting (innermost tags appear first in
    // the open sequence and get closed last).
    if (_truthy(attrs['code'])) _stack.add('code');
    if (_truthy(attrs['underline'])) _stack.add('u');
    if (_truthy(attrs['strike'])) _stack.add('s');
    if (_truthy(attrs['italic'])) _stack.add('em');
    if (_truthy(attrs['bold'])) _stack.add('strong');

    final script = attrs['script'];
    if (script == 'super') {
      _stack.add('sup');
    } else if (script == 'sub') {
      _stack.add('sub');
    }

    // span (color/background/font/size/placeholder) — built into a single attr map.
    Map<String, String>? spanAttrs;
    final style = StyleMap();
    final color = attrs['color']?.toString();
    if (color != null && color.isNotEmpty) {
      final parsed = CssColor.parse(color) ?? CssColor.parseArgb(color);
      style['color'] = parsed?.toCss() ?? color;
    }
    final bg = attrs['background']?.toString();
    if (bg != null && bg.isNotEmpty) {
      final parsed = CssColor.parse(bg) ?? CssColor.parseArgb(bg);
      style['background-color'] = parsed?.toCss() ?? bg;
    }
    final font = attrs['font']?.toString();
    if (font != null && font.isNotEmpty) {
      style['font-family'] = font;
    }
    final size = attrs['size']?.toString();
    if (size != null && size.isNotEmpty) {
      style['font-size'] = QuillSize.toCss(size);
    }
    if (_truthy(attrs['small'])) {
      style['font-size'] = '${QuillSize.namedToPx['small']!.toInt()}px';
    }
    final placeholder = _truthy(attrs['placeholder']);
    if (style.isNotEmpty || placeholder) {
      spanAttrs = <String, String>{};
      if (style.isNotEmpty) spanAttrs['style'] = style.toCss();
      if (placeholder) spanAttrs['data-placeholder'] = 'true';
    }

    // link (outermost wrapper).
    Map<String, String>? linkAttrs;
    final link = attrs['link']?.toString();
    if (link != null && link.isNotEmpty) {
      linkAttrs = <String, String>{'href': link};
      if (attrs['target'] != null) linkAttrs['target'] = attrs['target'].toString();
      if (attrs['rel'] != null) linkAttrs['rel'] = attrs['rel'].toString();
    }

    // Write opens: link → span → ...stack(reverse) → text → reverse.
    if (linkAttrs != null) writer.open('a', linkAttrs);
    if (spanAttrs != null) writer.open('span', spanAttrs);
    // Stack is innermost-first; opens must be outermost-first → iterate reverse.
    for (var i = _stack.length - 1; i >= 0; i--) {
      writer.open(_stack[i]);
    }
    writer.text(text);
    for (var i = 0; i < _stack.length; i++) {
      writer.close(_stack[i]);
    }
    if (spanAttrs != null) writer.close('span');
    if (linkAttrs != null) writer.close('a');
  }

  void _emitEmbed(InlineOp op, HtmlWriter writer) {
    final embed = op.asEmbed;
    if (embed.isEmpty) return;
    final type = embed.keys.first;
    final value = embed[type];

    // flutter_quill custom wrapper: {"custom": "<json {sub: data}>"}
    if (type == 'custom' && value is String) {
      try {
        final inner = _decodeCustom(value);
        if (inner != null) {
          final adapter =
              registry.forType(inner.key, customSubType: inner.key) ?? registry.forType(inner.key);
          if (adapter != null) {
            adapter.encode(
              writer: writer,
              value: inner.value,
              siblingAttrs: op.attributes,
              options: options,
            );
            return;
          }
        }
      } on FormatException {
        // Fall through.
      }
    }

    final adapter = registry.forType(type);
    if (adapter != null) {
      adapter.encode(
        writer: writer,
        value: value,
        siblingAttrs: op.attributes,
        options: options,
      );
      return;
    }
    final fallback = registry.forType('__passthrough__');
    if (fallback != null) {
      fallback.encode(
        writer: writer,
        value: embed,
        siblingAttrs: op.attributes,
        options: options,
      );
    }
  }

  static MapEntry<String, dynamic>? _decodeCustom(String json) {
    final decoded = jsonDecode(json);
    if (decoded is Map && decoded.length == 1) {
      final k = decoded.keys.first.toString();
      return MapEntry(k, decoded[k]);
    }
    return null;
  }
}

bool _truthy(Object? v) => v == true || v == 'true' || v == 1;
