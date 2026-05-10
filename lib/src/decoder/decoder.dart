import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:html/dom.dart' as dom;

import '../css/color.dart';
import '../css/size.dart';
import '../css/style_parser.dart';
import '../embeds/registry.dart';
import '../options.dart';

/// HTML -> Delta walker.
class HtmlDecoder {
  HtmlDecoder(this.registry, this.options);

  final EmbedRegistry registry;
  final QuillHtmlOptions options;

  Delta decode(dom.Document doc) {
    final builder = _DeltaBuilder();
    final body = doc.body ?? doc.documentElement;
    if (body == null) return builder.build();

    // If the body contains a single `.ql-html-doc` wrapper from our encoder, unwrap it.
    final wrapper = _unwrap(body);

    _walkChildren(wrapper, builder, _InlineAttrs.empty(), <String, dynamic>{});
    return builder.build();
  }

  dom.Element _unwrap(dom.Element body) {
    final children = body.children;
    if (children.length == 1 &&
        children.first.localName == 'div' &&
        (children.first.attributes['class'] ?? '').split(' ').contains('ql-html-doc')) {
      return children.first;
    }
    return body;
  }

  void _walkChildren(
    dom.Element parent,
    _DeltaBuilder out,
    _InlineAttrs inline,
    Map<String, dynamic> blockCtx,
  ) {
    for (final node in parent.nodes) {
      if (node is dom.Text) {
        if (node.text.isEmpty) continue;
        out.insertText(node.text, inline.snapshot());
      } else if (node is dom.Element) {
        _visit(node, out, inline, blockCtx);
      }
    }
  }

  /// Visit one element. Routes by tag.
  void _visit(
    dom.Element el,
    _DeltaBuilder out,
    _InlineAttrs inline,
    Map<String, dynamic> blockCtx,
  ) {
    // First: embed adapter dispatch (highest priority).
    final adapter = registry.forElement(el);
    if (adapter != null) {
      final op = adapter.decode(el, options);
      if (op != null) {
        out.insertEmbed(op);
        // Block-level standalone embeds (divider, raw <hr>) terminate the line.
        if (_isBlockLevelEmbedTag(el)) {
          out.flushLine(const <String, dynamic>{});
        }
        return;
      }
    }

    final name = el.localName ?? '';
    switch (name) {
      case 'p':
      case 'div':
        _emitParagraph(el, out, inline, blockCtx);
        return;
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.parse(name.substring(1));
        final block = _readLineStyles(el, base: blockCtx)..['header'] = level;
        _walkChildren(el, out, inline, block);
        out.flushLine(block);
        return;
      case 'blockquote':
        final block = _readLineStyles(el, base: blockCtx)..['blockquote'] = true;
        // If contains block-level children, recurse normally; otherwise treat as one line.
        if (_hasBlockChild(el)) {
          _walkChildren(el, out, inline, block);
        } else {
          _walkChildren(el, out, inline, block);
          out.flushLine(block);
        }
        return;
      case 'pre':
        _emitPre(el, out, inline);
        return;
      case 'ul':
      case 'ol':
        _emitList(el, out, inline, blockCtx, ordered: name == 'ol', depth: 0);
        return;
      case 'br':
        out.insertText('\n', null);
        return;
      case 'hr':
        out.insertEmbed({
          'insert': {'divider': true}
        });
        return;
      case 'strong':
      case 'b':
        _walkChildren(el, out, inline.with_('bold', true), blockCtx);
        return;
      case 'em':
      case 'i':
        _walkChildren(el, out, inline.with_('italic', true), blockCtx);
        return;
      case 'u':
      case 'ins':
        _walkChildren(el, out, inline.with_('underline', true), blockCtx);
        return;
      case 's':
      case 'del':
      case 'strike':
        _walkChildren(el, out, inline.with_('strike', true), blockCtx);
        return;
      case 'sup':
        _walkChildren(el, out, inline.with_('script', 'super'), blockCtx);
        return;
      case 'sub':
        _walkChildren(el, out, inline.with_('script', 'sub'), blockCtx);
        return;
      case 'code':
        _walkChildren(el, out, inline.with_('code', true), blockCtx);
        return;
      case 'mark':
        _walkChildren(
          el,
          out,
          inline.with_('background', '#ffff00'),
          blockCtx,
        );
        return;
      case 'a':
        final href = el.attributes['href'];
        var attrs = inline;
        if (href != null && href.isNotEmpty) {
          attrs = attrs.with_('link', href);
        }
        _walkChildren(el, out, attrs, blockCtx);
        return;
      case 'span':
      case 'font':
        final next = _applyInlineStyle(el, inline);
        _walkChildren(el, out, next, blockCtx);
        return;
      case 'figure':
        // Already handled by adapter if class=media; else recurse.
        _walkChildren(el, out, inline, blockCtx);
        return;
      case 'label':
        // Often used inside CKEditor todo items wrapping checkbox + span — treat as transparent.
        _walkChildren(el, out, inline, blockCtx);
        return;
      case 'input':
      case 'script':
      case 'style':
      case 'noscript':
      case 'meta':
      case 'link':
        // Skip entirely (security + presentation).
        return;
      default:
        // Unknown element: descend into its children with same context.
        _walkChildren(el, out, inline, blockCtx);
    }
  }

  void _emitParagraph(
    dom.Element el,
    _DeltaBuilder out,
    _InlineAttrs inline,
    Map<String, dynamic> blockCtx,
  ) {
    final block = _readLineStyles(el, base: blockCtx);
    if (_isEmptyParagraph(el)) {
      // <p></p> or <p><br></p> -> single empty line.
      out.flushLine(block);
      return;
    }
    _walkChildren(el, out, inline, block);
    out.flushLine(block);
  }

  bool _isEmptyParagraph(dom.Element el) {
    if (el.nodes.isEmpty) return true;
    if (el.nodes.length == 1) {
      final only = el.nodes.first;
      if (only is dom.Element && only.localName == 'br') return true;
      if (only is dom.Text && only.text.isEmpty) return true;
    }
    return false;
  }

  void _emitPre(dom.Element pre, _DeltaBuilder out, _InlineAttrs inline) {
    // Either <pre>text</pre> or <pre><code class="language-x">text</code></pre>.
    String? lang;
    dom.Element source = pre;
    final inner = pre.children.length == 1 && pre.children.first.localName == 'code'
        ? pre.children.first
        : null;
    if (inner != null) {
      source = inner;
      final cls = inner.attributes['class'] ?? '';
      for (final c in cls.split(' ')) {
        if (c.startsWith('language-')) {
          lang = c.substring('language-'.length);
          break;
        }
      }
    }
    final text = source.text;
    final block = <String, dynamic>{'code-block': lang ?? true};
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].isNotEmpty) out.insertText(lines[i], inline.snapshot());
      // Last segment without trailing \n shouldn't emit a flushLine.
      if (i < lines.length - 1 || text.endsWith('\n')) {
        out.flushLine(block);
      }
    }
    if (!text.endsWith('\n') && lines.last.isNotEmpty) {
      out.flushLine(block);
    } else if (lines.isEmpty) {
      out.flushLine(block);
    }
  }

  void _emitList(
    dom.Element listEl,
    _DeltaBuilder out,
    _InlineAttrs inline,
    Map<String, dynamic> blockCtx, {
    required bool ordered,
    required int depth,
  }) {
    // Per-list "is this a task list?" hints.
    final listDataChecked = listEl.attributes['data-checked'];
    final listDataType = listEl.attributes['data-type']; // TipTap "taskList"
    final listCls = listEl.attributes['class'] ?? '';
    final listIsTask = listDataChecked != null ||
        listDataType == 'taskList' ||
        listCls.split(' ').contains('todo-list') ||
        listCls.split(' ').contains('task-list');

    for (final child in listEl.children) {
      if (child.localName != 'li') continue;
      // Skip placeholder <li> that exists only to host a nested list.
      if (_isPlaceholderLi(child)) {
        for (final node in child.children) {
          if (node.localName == 'ul' || node.localName == 'ol') {
            _emitList(node, out, inline, blockCtx,
                ordered: node.localName == 'ol', depth: depth + 1);
          }
        }
        continue;
      }
      final itemAttrs = <String, dynamic>{};
      // Per-item task detection: data-list, data-checked, embedded checkbox,
      // or task-list parent.
      final liData = child.attributes['data-list'];
      final liChecked = child.attributes['data-checked'];
      final input = child.querySelector('input[type=checkbox]');
      final itemIsTask = listIsTask ||
          liData != null ||
          liChecked != null ||
          input != null;
      String listVal;
      if (itemIsTask) {
        bool checked;
        if (liData != null) {
          checked = liData == 'checked';
        } else if (liChecked != null) {
          checked = liChecked == 'true' || liChecked == 'checked';
        } else if (input != null) {
          checked = input.attributes.containsKey('checked');
        } else if (listDataChecked == 'true') {
          checked = true;
        } else {
          checked = false;
        }
        listVal = checked ? 'checked' : 'unchecked';
      } else {
        listVal = ordered ? 'ordered' : 'bullet';
      }
      itemAttrs['list'] = listVal;
      if (depth > 0) itemAttrs['indent'] = depth;

      _walkLiInline(child, out, inline, itemAttrs);
      out.flushLine(itemAttrs);

      // Recurse into nested lists.
      for (final node in child.nodes) {
        if (node is dom.Element && (node.localName == 'ul' || node.localName == 'ol')) {
          _emitList(node, out, inline, blockCtx,
              ordered: node.localName == 'ol', depth: depth + 1);
        }
      }
    }
  }

  /// True if [li] contains only nested list(s) and no inline / text content.
  bool _isPlaceholderLi(dom.Element li) {
    for (final node in li.nodes) {
      if (node is dom.Text) {
        if (node.text.isNotEmpty) return false;
      } else if (node is dom.Element) {
        if (node.localName != 'ul' && node.localName != 'ol') return false;
      }
    }
    return true;
  }

  /// Walk inline content inside a list item, treating `<div>`/`<p>`/`<label>` as transparent.
  /// Skips nested `<ul>`/`<ol>` (handled by caller) and `<input>` checkboxes.
  void _walkLiInline(
    dom.Element parent,
    _DeltaBuilder out,
    _InlineAttrs inline,
    Map<String, dynamic> itemAttrs,
  ) {
    for (final node in parent.nodes) {
      if (node is dom.Text) {
        if (node.text.isNotEmpty) out.insertText(node.text, inline.snapshot());
      } else if (node is dom.Element) {
        final n = node.localName;
        if (n == 'ul' || n == 'ol' || n == 'input') continue;
        if (n == 'label' || n == 'div' || n == 'p' || n == 'span' && node.attributes['class'] == 'todo-list__label__description') {
          // Transparent containers in list items.
          if (n == 'span') {
            final next = _applyInlineStyle(node, inline);
            _walkLiInline(node, out, next, itemAttrs);
          } else {
            _walkLiInline(node, out, inline, itemAttrs);
          }
          continue;
        }
        _visit(node, out, inline, itemAttrs);
      }
    }
  }

  /// Apply CSS inline styles or `<font>` attrs onto inline attrs.
  _InlineAttrs _applyInlineStyle(dom.Element el, _InlineAttrs inline) {
    var next = inline;
    final style = StyleMap.parse(el.attributes['style']);

    final color = style['color'] ?? el.attributes['color'];
    if (color != null && color.isNotEmpty) {
      final parsed = CssColor.parse(color) ?? CssColor.parseArgb(color);
      next = next.with_('color', parsed?.toCss() ?? color);
    }
    final bg = style['background-color'] ?? style['background'];
    if (bg != null && bg.isNotEmpty) {
      final parsed = CssColor.parse(bg) ?? CssColor.parseArgb(bg);
      next = next.with_('background', parsed?.toCss() ?? bg);
    }
    final fontFamily = style['font-family'] ?? el.attributes['face'];
    if (fontFamily != null && fontFamily.isNotEmpty) {
      next = next.with_('font', fontFamily);
    }
    final fontSize = style['font-size'] ?? el.attributes['size'];
    if (fontSize != null && fontSize.isNotEmpty) {
      next = next.with_('size', QuillSize.fromCss(fontSize));
    }
    final fontWeight = style['font-weight'];
    if (fontWeight == 'bold' || (fontWeight != null && (int.tryParse(fontWeight) ?? 0) >= 600)) {
      next = next.with_('bold', true);
    }
    final fontStyle = style['font-style'];
    if (fontStyle == 'italic') {
      next = next.with_('italic', true);
    }
    final textDecoration = style['text-decoration'] ?? style['text-decoration-line'];
    if (textDecoration != null) {
      if (textDecoration.contains('underline')) next = next.with_('underline', true);
      if (textDecoration.contains('line-through')) next = next.with_('strike', true);
    }
    final verticalAlign = style['vertical-align'];
    if (verticalAlign == 'super' || verticalAlign == 'sub') {
      next = next.with_('script', verticalAlign);
    }
    if (el.attributes['data-placeholder'] == 'true') {
      next = next.with_('placeholder', true);
    }
    return next;
  }

  /// Read block-level styles (align, indent via padding-left, direction, line-height) from element.
  Map<String, dynamic> _readLineStyles(dom.Element el, {required Map<String, dynamic> base}) {
    final out = Map<String, dynamic>.of(base);
    final style = StyleMap.parse(el.attributes['style']);
    final align = style['text-align'];
    if (align != null && align.isNotEmpty) {
      out['align'] = align;
    } else if (el.attributes['align'] != null) {
      out['align'] = el.attributes['align']!.toLowerCase();
    }
    final padding = style['padding-left'];
    if (padding != null) {
      final m = RegExp(r'^([0-9]+(?:\.[0-9]+)?)(em|px|rem)?$').firstMatch(padding.trim());
      if (m != null) {
        final v = double.parse(m.group(1)!);
        final unit = m.group(2) ?? 'em';
        double indent;
        if (unit == 'em' || unit == 'rem') {
          indent = v / 2.0;
        } else {
          indent = v / 32.0; // assume 16px = 1em, 2em = indent 1
        }
        final i = indent.round();
        if (i > 0) out['indent'] = i;
      }
    }
    final dir = el.attributes['dir'];
    if (dir != null && (dir == 'rtl' || dir == 'ltr')) {
      out['direction'] = dir;
    }
    final lh = style['line-height'];
    if (lh != null && lh.isNotEmpty) {
      out['line-height'] = lh;
    }
    return out;
  }

  bool _isBlockLevelEmbedTag(dom.Element el) {
    return el.localName == 'hr' || el.localName == 'table';
  }

  bool _hasBlockChild(dom.Element el) {
    const blocks = {'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'pre', 'ul', 'ol', 'li', 'hr'};
    for (final c in el.children) {
      if (blocks.contains(c.localName)) return true;
    }
    return false;
  }
}

/// Accumulator that knows when to emit `\n` ops with block attrs.
class _DeltaBuilder {
  final Delta _delta = Delta();

  /// Insert a text fragment with optional inline attrs.
  void insertText(String text, Map<String, dynamic>? attrs) {
    if (text.isEmpty) return;
    _delta.insert(text, attrs);
  }

  /// Insert an embed op JSON: `{"insert": {...}, "attributes": {...}?}`.
  void insertEmbed(Map<String, dynamic> op) {
    final insert = op['insert'];
    final attrs = op['attributes'] as Map<String, dynamic>?;
    _delta.insert(insert, attrs);
  }

  /// Close the current line with the given block attrs.
  void flushLine(Map<String, dynamic> blockAttrs) {
    final attrs = blockAttrs.isEmpty ? null : Map<String, dynamic>.of(blockAttrs);
    _delta.insert('\n', attrs);
  }

  Delta build() => _delta;
}

/// Immutable inline attribute frame.
class _InlineAttrs {
  const _InlineAttrs._(this._map);
  factory _InlineAttrs.empty() => const _InlineAttrs._(<String, dynamic>{});

  final Map<String, dynamic> _map;

  _InlineAttrs with_(String key, Object? value) {
    if (value == null) return this;
    final next = Map<String, dynamic>.of(_map);
    next[key] = value;
    return _InlineAttrs._(next);
  }

  Map<String, dynamic>? snapshot() => _map.isEmpty ? null : Map<String, dynamic>.of(_map);
}
