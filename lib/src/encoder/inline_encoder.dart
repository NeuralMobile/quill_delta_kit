import 'dart:convert';

import 'package:html/dom.dart' as dom;

import '../css/color.dart';
import '../css/size.dart';
import '../css/style_parser.dart';
import '../embeds/registry.dart';
import '../options.dart';
import 'line_splitter.dart';

/// Emit one [InlineOp] into [parent] as DOM nodes.
class InlineEncoder {
  InlineEncoder(this.registry, this.options);

  final EmbedRegistry registry;
  final QuillHtmlOptions options;

  void emit(InlineOp op, dom.Element parent) {
    if (op.isEmbed) {
      _emitEmbed(op, parent);
      return;
    }
    final text = op.asText;
    if (text.isEmpty) return;
    final attrs = op.attributes ?? const <String, dynamic>{};

    dom.Node node = dom.Text(text);

    if (_truthy(attrs['code'])) {
      final el = dom.Element.tag('code');
      el.append(node);
      node = el;
    }
    if (_truthy(attrs['underline'])) {
      final el = dom.Element.tag('u');
      el.append(node);
      node = el;
    }
    if (_truthy(attrs['strike'])) {
      final el = dom.Element.tag('s');
      el.append(node);
      node = el;
    }
    if (_truthy(attrs['italic'])) {
      final el = dom.Element.tag('em');
      el.append(node);
      node = el;
    }
    if (_truthy(attrs['bold'])) {
      final el = dom.Element.tag('strong');
      el.append(node);
      node = el;
    }
    final script = attrs['script'];
    if (script == 'super') {
      final el = dom.Element.tag('sup');
      el.append(node);
      node = el;
    } else if (script == 'sub') {
      final el = dom.Element.tag('sub');
      el.append(node);
      node = el;
    }

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

    if (style.isNotEmpty || _truthy(attrs['placeholder'])) {
      final span = dom.Element.tag('span');
      if (style.isNotEmpty) span.attributes['style'] = style.toCss();
      if (_truthy(attrs['placeholder'])) span.attributes['data-placeholder'] = 'true';
      span.append(node);
      node = span;
    }

    final link = attrs['link']?.toString();
    if (link != null && link.isNotEmpty) {
      final a = dom.Element.tag('a')..attributes['href'] = link;
      if (attrs['target'] != null) a.attributes['target'] = attrs['target'].toString();
      if (attrs['rel'] != null) a.attributes['rel'] = attrs['rel'].toString();
      a.append(node);
      node = a;
    }

    parent.append(node);
  }

  void _emitEmbed(InlineOp op, dom.Element parent) {
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
              parent: parent,
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
        parent: parent,
        value: value,
        siblingAttrs: op.attributes,
        options: options,
      );
      return;
    }
    final fallback = registry.forType('__passthrough__');
    if (fallback != null) {
      fallback.encode(
        parent: parent,
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
