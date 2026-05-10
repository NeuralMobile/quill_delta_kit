import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Sanitize HTML that Microsoft Word / Outlook places on the clipboard.
///
/// Word HTML is bristly:
/// - `<o:p>`, `<v:*>`, `<w:*>` Office namespace elements.
/// - `class="MsoNormal"`, `MsoListParagraphCxSpFirst`, etc.
/// - `style="mso-*: ..."` properties on every element.
/// - `<!--StartFragment-->` / `<!--EndFragment-->` marker comments.
/// - Conditional comments `<![if !supportLists]>...<![endif]>`.
/// - Lists encoded as `<p class=MsoListParagraph style='mso-list:l0 level1'>`
///   instead of `<ul>/<ol>`.
///
/// [WordHtmlCleaner.clean] returns body HTML stripped of these quirks and
/// with paragraph-encoded lists folded back into `<ul>/<ol>` so the standard
/// codec can decode them.
class WordHtmlCleaner {
  /// True if [html] looks like it was produced by Microsoft Word / Outlook.
  static bool isWordHtml(String html) {
    return html.contains('urn:schemas-microsoft-com:office') ||
        html.contains('class="Mso') ||
        html.contains("class='Mso") ||
        html.contains('class=Mso') ||
        html.contains('mso-') ||
        html.contains('<o:p') ||
        html.contains('StartFragment');
  }

  /// Strip Word cruft. Always safe to call (no-op for non-Word HTML).
  static String clean(String html) {
    var s = html;
    // Strip conditional comments + fragment markers.
    s = s.replaceAll(RegExp(r'<!--\[if[^>]*\]>.*?<!\[endif\]-->', dotAll: true), '');
    s = s.replaceAll(RegExp(r'<!\[if[^>]*\]>.*?<!\[endif\]>', dotAll: true), '');
    s = s.replaceAll(RegExp(r'<!--\s*Start\s*Fragment\s*-->', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<!--\s*End\s*Fragment\s*-->', caseSensitive: false), '');

    final doc = html_parser.parse(s);
    final body = doc.body ?? doc.documentElement!;

    _stripOfficeElements(body);
    _foldMsoLists(body);
    _stripMsoAttrs(body);
    _normalizeWhitespace(body);

    // Remove leftover empty <p>/<span> wrappers Word adds.
    _pruneEmptyWrappers(body);

    return body.innerHtml;
  }

  /// Drop `<o:p>`, `<o:*>`, `<v:*>`, `<w:*>` namespaced elements (preserve text).
  static void _stripOfficeElements(dom.Element root) {
    final remove = <dom.Element>[];
    root.querySelectorAll('*').forEach((el) {
      final name = el.localName ?? '';
      if (name.startsWith('o:') || name.startsWith('v:') || name.startsWith('w:') || name.startsWith('m:')) {
        remove.add(el);
      }
    });
    for (final el in remove) {
      // Preserve text by replacing element with its child nodes.
      final parent = el.parent;
      if (parent == null) continue;
      final idx = parent.nodes.indexOf(el);
      final children = List<dom.Node>.from(el.nodes);
      parent.nodes.removeAt(idx);
      for (var i = 0; i < children.length; i++) {
        parent.nodes.insert(idx + i, children[i]);
      }
    }
  }

  /// Strip `class="Mso*"`, `lang="..."`, `style="mso-*: ..."` and unsupported
  /// namespaced attrs. Also drop empty style/class attrs left after cleanup.
  static void _stripMsoAttrs(dom.Element root) {
    for (final el in root.querySelectorAll('*')) {
      // class: drop Mso*; keep the rest.
      final cls = el.attributes['class'];
      if (cls != null) {
        final keep = cls.split(RegExp(r'\s+')).where((c) {
          final t = c.trim();
          return t.isNotEmpty && !t.startsWith('Mso');
        }).toList();
        if (keep.isEmpty) {
          el.attributes.remove('class');
        } else {
          el.attributes['class'] = keep.join(' ');
        }
      }
      // style: drop mso-* properties.
      final style = el.attributes['style'];
      if (style != null) {
        final cleaned = style.split(';').where((p) {
          final t = p.trim();
          return t.isNotEmpty && !t.toLowerCase().startsWith('mso-');
        }).join('; ');
        if (cleaned.trim().isEmpty) {
          el.attributes.remove('style');
        } else {
          el.attributes['style'] = cleaned;
        }
      }
      // Drop noisy attrs.
      el.attributes.remove('lang');
      el.attributes.remove('xml:lang');
      // Namespaced attrs Word uses (xmlns:o, xmlns:w, etc).
      el.attributes.removeWhere((k, _) {
        final s = k.toString();
        return s.startsWith('xmlns:') || s.startsWith('o:') || s.startsWith('v:') || s.startsWith('w:');
      });
    }
  }

  /// Convert paragraph-encoded Word lists into proper `<ul>/<ol>`.
  ///
  /// Word emits list items as:
  ///   <p class=MsoListParagraph style='mso-list:l0 level2 lfo1'>
  ///     <span style='mso-list:Ignore'>2.<span>&nbsp;</span></span>
  ///     Item text
  ///   </p>
  ///
  /// We detect runs of consecutive `<p>`s with `mso-list:` style, group them,
  /// strip the marker span, and wrap in `<ul>` (bullet) or `<ol>` (numeric).
  static void _foldMsoLists(dom.Element root) {
    // First pass: scan top-level <p>s for mso-list signature.
    final body = root;
    final children = List<dom.Element>.from(body.children);
    var i = 0;
    while (i < children.length) {
      final el = children[i];
      final info = _msoListInfo(el);
      if (info == null) {
        i++;
        continue;
      }
      // Collect run of consecutive list paragraphs.
      final group = <_MsoListItem>[];
      while (i < children.length) {
        final cur = children[i];
        final cinfo = _msoListInfo(cur);
        if (cinfo == null) break;
        group.add(_MsoListItem(p: cur, level: cinfo.level, ordered: cinfo.ordered));
        i++;
      }
      // Build nested list HTML and replace first paragraph; remove others.
      final listHtml = _buildNestedList(group);
      final container = html_parser.parseFragment(listHtml);
      final first = group.first.p;
      final parent = first.parent!;
      final idx = parent.nodes.indexOf(first);
      parent.nodes.removeAt(idx);
      for (final g in group.skip(1)) {
        g.p.remove();
      }
      var insertAt = idx;
      // Snapshot container nodes before reparenting (insert moves node from container).
      for (final node in List<dom.Node>.from(container.nodes)) {
        parent.nodes.insert(insertAt++, node);
      }
    }
  }

  static _MsoInfo? _msoListInfo(dom.Element el) {
    if (el.localName != 'p') return null;
    final style = el.attributes['style'] ?? '';
    final m = RegExp(r'mso-list\s*:\s*\S+\s+level(\d+)').firstMatch(style);
    if (m == null) return null;
    final level = (int.tryParse(m.group(1)!) ?? 1) - 1;
    // Determine ordered vs bullet: look at the marker span text.
    // If marker contains a digit/letter+'.' it's ordered; if bullet glyph (·•◦▪) it's bullet.
    final marker = el.querySelector('span[style*="mso-list:Ignore"]')?.text ?? '';
    final cleaned = marker.replaceAll(RegExp(r'\s'), '');
    final ordered = RegExp(r'^[0-9a-zA-Z]+[.)]?$').hasMatch(cleaned);
    return _MsoInfo(level: level < 0 ? 0 : level, ordered: ordered);
  }

  static String _buildNestedList(List<_MsoListItem> items) {
    final out = StringBuffer();
    final stack = <String>[]; // stack of open tags ('ul' or 'ol')

    void openTo(int depth, String tag) {
      while (stack.length < depth + 1) {
        out.write('<$tag>');
        stack.add(tag);
      }
      // If at right depth but wrong tag, flip.
      while (stack.isNotEmpty && stack.length > depth + 1) {
        final t = stack.removeLast();
        out.write('</$t>');
      }
      if (stack.last != tag) {
        // Close + reopen at this depth with desired tag.
        final t = stack.removeLast();
        out.write('</$t>');
        out.write('<$tag>');
        stack.add(tag);
      }
    }

    for (final it in items) {
      final tag = it.ordered ? 'ol' : 'ul';
      openTo(it.level, tag);
      // Strip marker span before serializing inner content.
      final clone = it.p.clone(true);
      clone.querySelectorAll('span').toList().forEach((sp) {
        final st = sp.attributes['style'] ?? '';
        if (st.toLowerCase().contains('mso-list:ignore')) sp.remove();
      });
      out.write('<li>${clone.innerHtml}</li>');
    }
    while (stack.isNotEmpty) {
      out.write('</${stack.removeLast()}>');
    }
    return out.toString();
  }

  /// Replace `&nbsp;` runs at start/end of paragraphs (Word adds these as
  /// indent emulators) and trim duplicate spaces inside text nodes.
  static void _normalizeWhitespace(dom.Element root) {
    // Drop empty paragraph chains used as spacers.
    final paragraphs = root.querySelectorAll('p').toList();
    for (final p in paragraphs) {
      // If paragraph contains only NBSPs / whitespace, leave one <br>.
      final t = p.text.trim();
      if (t.isEmpty && p.children.isEmpty) {
        p.nodes.clear();
        p.append(dom.Element.tag('br'));
      }
    }
  }

  /// Drop empty `<span>` wrappers and `<font>` artifacts left after attr stripping.
  static void _pruneEmptyWrappers(dom.Element root) {
    bool changed;
    do {
      changed = false;
      final all = root.querySelectorAll('span, font').toList();
      for (final el in all) {
        if (el.attributes.isEmpty) {
          // Replace with children.
          final parent = el.parent;
          if (parent == null) continue;
          final idx = parent.nodes.indexOf(el);
          final kids = List<dom.Node>.from(el.nodes);
          parent.nodes.removeAt(idx);
          for (var i = 0; i < kids.length; i++) {
            parent.nodes.insert(idx + i, kids[i]);
          }
          changed = true;
        }
      }
    } while (changed);
  }
}

class _MsoInfo {
  _MsoInfo({required this.level, required this.ordered});
  final int level;
  final bool ordered;
}

class _MsoListItem {
  _MsoListItem({required this.p, required this.level, required this.ordered});
  final dom.Element p;
  final int level;
  final bool ordered;
}
