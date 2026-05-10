import 'package:quill_delta_core/quill_delta_core.dart';

import '../css/style_parser.dart';
import '../embeds/registry.dart';
import '../options.dart';
import '../util/html_writer.dart';
import 'inline_encoder.dart';

/// Group consecutive [Line]s into block-level HTML written to [writer].
class BlockEncoder {
  BlockEncoder(this.registry, this.options);

  final EmbedRegistry registry;
  final QuillHtmlOptions options;

  late final InlineEncoder _inline = InlineEncoder(registry, options);

  void encode(List<Line> lines, HtmlWriter writer) {
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final block = line.blockAttrs ?? const <String, dynamic>{};

      // 1) Code block: group consecutive code-block lines.
      if (block['code-block'] != null && block['code-block'] != false) {
        final lang = block['code-block'];
        writer.open('pre');
        if (lang is String && lang.isNotEmpty && lang != 'true') {
          writer.open('code', {'class': 'language-$lang'});
        } else {
          writer.open('code');
        }
        var first = true;
        while (i < lines.length) {
          final l = lines[i];
          final cb = l.blockAttrs?['code-block'];
          if (cb == null || cb == false) break;
          if (!first) writer.text('\n');
          first = false;
          for (final op in l.ops) {
            if (op.isText) {
              writer.text(op.asText);
            } else {
              _inline.emit(op, writer);
            }
          }
          i++;
        }
        writer.close('code');
        writer.close('pre');
        continue;
      }

      // 2) List block: group consecutive list lines (handles indent nesting).
      if (block['list'] != null) {
        final consumed = _emitListGroup(lines, i, writer);
        i += consumed;
        continue;
      }

      // 3) Header.
      final header = block['header'];
      if (header is num) {
        final tag = 'h${header.toInt().clamp(1, 6)}';
        final styleAttrs = _lineStyleAttrs(block);
        writer.open(tag, styleAttrs);
        for (final op in line.ops) {
          _inline.emit(op, writer);
        }
        if (line.ops.isEmpty) writer.voidEl('br');
        writer.close(tag);
        i++;
        continue;
      }

      // 4) Blockquote: group consecutive blockquote lines.
      if (block['blockquote'] != null && block['blockquote'] != false) {
        writer.open('blockquote');
        while (i < lines.length) {
          final l = lines[i];
          final bb = l.blockAttrs ?? const <String, dynamic>{};
          if (bb['blockquote'] == null || bb['blockquote'] == false) break;
          if (bb['list'] != null || bb['code-block'] != null || bb['header'] != null) break;
          final styleAttrs = _lineStyleAttrs(bb);
          writer.open('p', styleAttrs);
          for (final op in l.ops) {
            _inline.emit(op, writer);
          }
          if (l.ops.isEmpty) writer.voidEl('br');
          writer.close('p');
          i++;
        }
        writer.close('blockquote');
        continue;
      }

      // 5) Block-level embed standalone (e.g. divider as <hr>) — do not wrap in <p>.
      if (line.ops.length == 1 && line.ops.first.isEmbed) {
        final embed = line.ops.first.asEmbed;
        if (embed.isNotEmpty && _isBlockLevelEmbed(embed.keys.first)) {
          _inline.emit(line.ops.first, writer);
          i++;
          continue;
        }
      }

      // 6) Plain paragraph (with possible align/indent/direction/line-height).
      final styleAttrs = _lineStyleAttrs(block);
      writer.open('p', styleAttrs);
      for (final op in line.ops) {
        _inline.emit(op, writer);
      }
      if (line.ops.isEmpty) writer.voidEl('br');
      writer.close('p');
      i++;
    }
  }

  /// Build the (sorted) attribute map for a paragraph/header from line block
  /// attrs. Returns null when no styling applies.
  Map<String, String>? _lineStyleAttrs(Map<String, dynamic> block) {
    final style = StyleMap();
    final align = block['align']?.toString();
    if (align != null && align.isNotEmpty) {
      style['text-align'] = align;
    }
    final indent = block['indent'];
    if (indent is num && indent > 0) {
      style['padding-left'] = '${indent * 2}em';
    }
    final lh = block['line-height'];
    if (lh != null) {
      style['line-height'] = lh.toString();
    }
    final dir = block['direction']?.toString();
    final hasDir = dir == 'rtl' || dir == 'ltr';
    if (style.isEmpty && !hasDir) return null;
    final out = <String, String>{};
    if (hasDir) out['dir'] = dir!;
    if (style.isNotEmpty) out['style'] = style.toCss();
    return out;
  }

  /// Emit a contiguous list group; supports nested indents.
  ///
  /// Maintains parallel stacks [openLists] (currently-open `<ul>`/`<ol>` tag
  /// names) and [liOpen] (whether a `<li>` is currently open at that depth).
  /// On each item:
  ///   - de-nest: close excess `<li>`s and lists down to the target depth.
  ///   - nest: open new `<ul>`/`<ol>` (and a host `<li>` if absent at parent
  ///     depth) up to the target depth.
  ///   - close any open `<li>` at the target depth, then write a fresh
  ///     `<li>` carrying this item's content.
  /// The current `<li>` is left OPEN so the next item (potentially deeper)
  /// can nest inside it; closes happen during de-nest or at end of group.
  /// Returns number of lines consumed.
  int _emitListGroup(List<Line> lines, int start, HtmlWriter writer) {
    final firstAttrs = lines[start].blockAttrs ?? const <String, dynamic>{};
    final firstType = firstAttrs['list']?.toString();
    if (firstType == null) return 0;
    final outerTag = _listTag(firstType);
    final outerAttrs = (firstType == 'checked' || firstType == 'unchecked')
        ? <String, String>{
            'data-checked': firstType == 'checked' ? 'true' : 'false',
          }
        : null;
    writer.open(outerTag, outerAttrs);

    final openLists = <String>[outerTag];
    final liOpen = <bool>[false];

    int consumed = 0;
    while (start + consumed < lines.length) {
      final line = lines[start + consumed];
      final attrs = line.blockAttrs ?? const <String, dynamic>{};
      final type = attrs['list']?.toString();
      if (type == null) break;
      final tag = _listTag(type);
      if ((tag == 'ol') != (outerTag == 'ol')) break;

      consumed++;
      final indent =
          (attrs['indent'] is num) ? (attrs['indent'] as num).toInt() : 0;
      final targetDepth = indent + 1;

      // De-nest: close lists deeper than target.
      while (openLists.length > targetDepth) {
        if (liOpen.last) {
          writer.close('li');
          liOpen[liOpen.length - 1] = false;
        }
        writer.close(openLists.last);
        openLists.removeLast();
        liOpen.removeLast();
        // Close the host <li> at the now-current depth (the one that hosted
        // the list we just closed).
        if (liOpen.isNotEmpty && liOpen.last) {
          writer.close('li');
          liOpen[liOpen.length - 1] = false;
        }
      }

      // Nest: open lists up to target.
      while (openLists.length < targetDepth) {
        // At parent depth, we need an open <li> to host the nested list.
        if (!liOpen.last) {
          // Synthetic empty <li> placeholder.
          writer.open('li');
          liOpen[liOpen.length - 1] = true;
        }
        writer.open(outerTag);
        openLists.add(outerTag);
        liOpen.add(false);
      }

      // Close any prior <li> at the target depth before opening a fresh one.
      if (liOpen.last) {
        writer.close('li');
        liOpen[liOpen.length - 1] = false;
      }

      // Open this item's <li>.
      Map<String, String>? liAttrs;
      if (type == 'checked' || type == 'unchecked') {
        liAttrs = <String, String>{
          'data-checked': type == 'checked' ? 'true' : 'false',
          'data-list': type,
        };
      }
      writer.open('li', liAttrs);
      for (final op in line.ops) {
        _inline.emit(op, writer);
      }
      if (line.ops.isEmpty) writer.voidEl('br');
      // Leave <li> open; next iteration or post-loop close handles it.
      liOpen[liOpen.length - 1] = true;
    }

    // Unwind everything still open.
    while (openLists.isNotEmpty) {
      if (liOpen.last) {
        writer.close('li');
      }
      writer.close(openLists.last);
      openLists.removeLast();
      liOpen.removeLast();
      if (liOpen.isNotEmpty && liOpen.last) {
        writer.close('li');
        liOpen[liOpen.length - 1] = false;
      }
    }
    return consumed;
  }

  String _listTag(String type) {
    if (type == 'ordered') return 'ol';
    return 'ul';
  }

  bool _isBlockLevelEmbed(String type) =>
      type == 'divider' || type == 'hr' || type == 'table';
}
