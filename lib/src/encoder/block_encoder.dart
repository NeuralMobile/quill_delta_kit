import 'package:html/dom.dart' as dom;

import '../css/style_parser.dart';
import '../embeds/registry.dart';
import '../options.dart';
import 'inline_encoder.dart';
import 'line_splitter.dart';

/// Group consecutive [Line]s into block-level HTML nodes appended to [root].
class BlockEncoder {
  BlockEncoder(this.registry, this.options);

  final EmbedRegistry registry;
  final QuillHtmlOptions options;

  late final InlineEncoder _inline = InlineEncoder(registry, options);

  void encode(List<Line> lines, dom.Element root) {
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final block = line.blockAttrs ?? const <String, dynamic>{};

      // 1) Code block: group consecutive code-block lines.
      // Per Quill spec, inline formatting is dropped inside code blocks.
      if (block['code-block'] != null && block['code-block'] != false) {
        final pre = dom.Element.tag('pre');
        final code = dom.Element.tag('code');
        final lang = block['code-block'];
        if (lang is String && lang.isNotEmpty && lang != 'true') {
          code.attributes['class'] = 'language-$lang';
        }
        pre.append(code);
        var first = true;
        while (i < lines.length) {
          final l = lines[i];
          final cb = l.blockAttrs?['code-block'];
          if (cb == null || cb == false) break;
          if (!first) code.append(dom.Text('\n'));
          first = false;
          for (final op in l.ops) {
            if (op.isText) {
              code.append(dom.Text(op.asText));
            } else {
              _inline.emit(op, code);
            }
          }
          i++;
        }
        root.append(pre);
        continue;
      }

      // 2) List block: group consecutive list lines (handles indent nesting).
      if (block['list'] != null) {
        final consumed = _emitListGroup(lines, i, root);
        i += consumed;
        continue;
      }

      // 3) Header.
      final header = block['header'];
      if (header is num) {
        final tag = 'h${header.toInt().clamp(1, 6)}';
        final el = dom.Element.tag(tag);
        _applyLineStyles(el, block);
        for (final op in line.ops) {
          _inline.emit(op, el);
        }
        if (line.ops.isEmpty) el.append(dom.Element.tag('br'));
        root.append(el);
        i++;
        continue;
      }

      // 4) Blockquote: group consecutive blockquote lines.
      if (block['blockquote'] != null && block['blockquote'] != false) {
        final bq = dom.Element.tag('blockquote');
        while (i < lines.length) {
          final l = lines[i];
          final bb = l.blockAttrs ?? const <String, dynamic>{};
          if (bb['blockquote'] == null || bb['blockquote'] == false) break;
          if (bb['list'] != null || bb['code-block'] != null || bb['header'] != null) break;
          final p = dom.Element.tag('p');
          _applyLineStyles(p, bb);
          for (final op in l.ops) {
            _inline.emit(op, p);
          }
          if (l.ops.isEmpty) p.append(dom.Element.tag('br'));
          bq.append(p);
          i++;
        }
        root.append(bq);
        continue;
      }

      // 5) Block-level embed standalone (e.g. divider as <hr>) — do not wrap in <p>.
      if (line.ops.length == 1 && line.ops.first.isEmbed && _isBlockLevelEmbed(line.ops.first.asEmbed)) {
        _inline.emit(line.ops.first, root);
        i++;
        continue;
      }

      // 6) Plain paragraph (with possible align/indent/direction/line-height).
      final p = dom.Element.tag('p');
      _applyLineStyles(p, block);
      for (final op in line.ops) {
        _inline.emit(op, p);
      }
      if (line.ops.isEmpty) p.append(dom.Element.tag('br'));
      root.append(p);
      i++;
    }
  }

  void _applyLineStyles(dom.Element el, Map<String, dynamic> block) {
    final style = StyleMap();
    final align = block['align']?.toString();
    if (align != null && align.isNotEmpty) {
      style['text-align'] = align;
    }
    final indent = block['indent'];
    if (indent is num && indent > 0) {
      style['padding-left'] = '${indent * 2}em';
    }
    final dir = block['direction']?.toString();
    if (dir == 'rtl' || dir == 'ltr') {
      el.attributes['dir'] = dir!;
    }
    final lh = block['line-height'];
    if (lh != null) {
      style['line-height'] = lh.toString();
    }
    if (style.isNotEmpty) el.attributes['style'] = style.toCss();
  }

  /// Emit a contiguous list group; supports nested indents.
  /// Returns number of lines consumed.
  int _emitListGroup(List<Line> lines, int start, dom.Element root) {
    final firstType = lines[start].blockAttrs?['list']?.toString();
    if (firstType == null) return 0;
    final outer = _listTag(firstType);
    final outerEl = dom.Element.tag(outer);
    if (firstType == 'checked' || firstType == 'unchecked') {
      outerEl.attributes['data-checked'] = firstType == 'checked' ? 'true' : 'false';
    }
    root.append(outerEl);

    int consumed = 0;
    while (start + consumed < lines.length) {
      final line = lines[start + consumed];
      final attrs = line.blockAttrs ?? const <String, dynamic>{};
      final type = attrs['list']?.toString();
      if (type == null) break;
      final tag = _listTag(type);
      // If switching between ordered/unordered roots, end the group.
      if ((tag == 'ol') != (outer == 'ol')) break;

      consumed++;
      final indent = (attrs['indent'] is num) ? (attrs['indent'] as num).toInt() : 0;
      _appendListItem(outerEl, line, type, indent);
    }
    return consumed;
  }

  void _appendListItem(dom.Element root, Line line, String type, int indent) {
    var target = root;
    for (var d = 0; d < indent; d++) {
      var lastLi = _lastChild(target, 'li');
      lastLi ??= dom.Element.tag('li')..append(dom.Text(''));
      if (lastLi.parent == null) target.append(lastLi);
      var nestedList = _lastChild(lastLi, target.localName!);
      if (nestedList == null) {
        nestedList = dom.Element.tag(target.localName!);
        lastLi.append(nestedList);
      }
      target = nestedList;
    }
    final li = dom.Element.tag('li');
    if (type == 'checked' || type == 'unchecked') {
      li.attributes['data-list'] = type;
      li.attributes['data-checked'] = type == 'checked' ? 'true' : 'false';
    }
    for (final op in line.ops) {
      _inline.emit(op, li);
    }
    if (line.ops.isEmpty) li.append(dom.Element.tag('br'));
    target.append(li);
  }

  String _listTag(String type) {
    if (type == 'ordered') return 'ol';
    return 'ul';
  }

  bool _isBlockLevelEmbed(Map<String, dynamic> embed) {
    final t = embed.keys.first;
    return t == 'divider' || t == 'hr' || t == 'table';
  }

  dom.Element? _lastChild(dom.Element parent, String tag) {
    for (var i = parent.nodes.length - 1; i >= 0; i--) {
      final n = parent.nodes[i];
      if (n is dom.Element && n.localName == tag) return n;
    }
    return null;
  }
}
