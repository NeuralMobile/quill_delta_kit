import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Convert .docx bytes -> minimal HTML string.
///
/// Scope (first cut): paragraphs, runs (bold/italic/underline/strike),
/// headings (style names "Heading1"..."Heading6"), bullet/ordered lists
/// (via `<w:numPr>` numId+ilvl), basic colour/size, hyperlinks.
///
/// Out of scope: tables, images, comments, track changes, footnotes,
/// section properties, theme-aware fonts. Those land in follow-ups.
String docxToHtml(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final docFile = archive.files.firstWhere(
    (f) => f.name == 'word/document.xml',
    orElse: () => throw const FormatException(
      'Not a valid .docx: missing word/document.xml',
    ),
  );
  final xmlString = String.fromCharCodes(docFile.content as List<int>);
  final doc = XmlDocument.parse(xmlString);

  final body = doc.findAllElements('body', namespace: '*').firstOrNull;
  if (body == null) return '';

  final buf = StringBuffer();
  _writeBody(body, buf);
  return buf.toString();
}

void _writeBody(XmlElement body, StringBuffer buf) {
  // Track open list state across consecutive list paragraphs.
  String? openListTag;
  int openIndent = -1;

  void closeOpenList() {
    if (openListTag != null) {
      for (var d = openIndent; d >= 0; d--) {
        buf.write('</$openListTag>');
      }
      openListTag = null;
      openIndent = -1;
    }
  }

  for (final el in body.childElements) {
    final name = el.localName;
    if (name == 'p') {
      final listInfo = _detectList(el);
      if (listInfo != null) {
        final tag = listInfo.ordered ? 'ol' : 'ul';
        // If switching list type or starting fresh, open.
        if (openListTag == null) {
          for (var d = 0; d <= listInfo.indent; d++) {
            buf.write('<$tag>');
          }
          openListTag = tag;
          openIndent = listInfo.indent;
        } else if (openListTag != tag) {
          closeOpenList();
          for (var d = 0; d <= listInfo.indent; d++) {
            buf.write('<$tag>');
          }
          openListTag = tag;
          openIndent = listInfo.indent;
        } else if (listInfo.indent > openIndent) {
          for (var d = openIndent + 1; d <= listInfo.indent; d++) {
            buf.write('<$tag>');
          }
          openIndent = listInfo.indent;
        } else if (listInfo.indent < openIndent) {
          for (var d = openIndent; d > listInfo.indent; d--) {
            buf.write('</$tag>');
          }
          openIndent = listInfo.indent;
        }
        buf.write('<li>');
        _writeRuns(el, buf);
        buf.write('</li>');
      } else {
        closeOpenList();
        final styleName = _paragraphStyle(el);
        final tag = _headingTag(styleName) ?? 'p';
        buf.write('<$tag>');
        _writeRuns(el, buf);
        buf.write('</$tag>');
      }
    } else if (name == 'tbl') {
      closeOpenList();
      buf.write('<table>');
      for (final row in el.findElements('tr', namespace: '*')) {
        buf.write('<tr>');
        for (final cell in row.findElements('tc', namespace: '*')) {
          buf.write('<td>');
          for (final p in cell.findElements('p', namespace: '*')) {
            _writeRuns(p, buf);
            buf.write('<br>');
          }
          buf.write('</td>');
        }
        buf.write('</tr>');
      }
      buf.write('</table>');
    }
    // Sectionproperties etc. ignored.
  }
  closeOpenList();
}

void _writeRuns(XmlElement paragraph, StringBuffer buf) {
  for (final node in paragraph.children) {
    if (node is! XmlElement) continue;
    final n = node.localName;
    if (n == 'r') {
      _writeRun(node, buf);
    } else if (n == 'hyperlink') {
      // Hyperlinks wrap runs.
      final href = _hyperlinkTarget(node);
      if (href != null) {
        buf.write('<a href="${_escapeAttr(href)}">');
        for (final r in node.findElements('r', namespace: '*')) {
          _writeRun(r, buf);
        }
        buf.write('</a>');
      } else {
        for (final r in node.findElements('r', namespace: '*')) {
          _writeRun(r, buf);
        }
      }
    }
  }
}

void _writeRun(XmlElement run, StringBuffer buf) {
  final rPr = run.findElements('rPr', namespace: '*').firstOrNull;
  final bold = rPr != null && _hasOnElement(rPr, 'b');
  final italic = rPr != null && _hasOnElement(rPr, 'i');
  final underline =
      rPr != null && rPr.findElements('u', namespace: '*').isNotEmpty;
  final strike = rPr != null &&
      (_hasOnElement(rPr, 'strike') || _hasOnElement(rPr, 'dstrike'));

  String? colorVal;
  String? sizeVal;
  if (rPr != null) {
    final col = rPr.findElements('color', namespace: '*').firstOrNull;
    final v = col?.attributes
        .firstWhere(
          (a) => a.localName == 'val',
          orElse: () => XmlAttribute(XmlName('val'), ''),
        )
        .value;
    if (v != null && v.isNotEmpty && v != 'auto') colorVal = '#$v';
    final sz = rPr.findElements('sz', namespace: '*').firstOrNull;
    final szVal = sz?.attributes
        .firstWhere(
          (a) => a.localName == 'val',
          orElse: () => XmlAttribute(XmlName('val'), ''),
        )
        .value;
    if (szVal != null && szVal.isNotEmpty) {
      // OOXML stores size in half-points.
      final hp = int.tryParse(szVal);
      if (hp != null) sizeVal = '${(hp / 2).toStringAsFixed(0)}px';
    }
  }

  final styleParts = <String>[];
  if (colorVal != null) styleParts.add('color: $colorVal');
  if (sizeVal != null) styleParts.add('font-size: $sizeVal');
  final hasStyle = styleParts.isNotEmpty;

  final wrappers = <String>[];
  if (bold) wrappers.add('strong');
  if (italic) wrappers.add('em');
  if (underline) wrappers.add('u');
  if (strike) wrappers.add('s');

  if (hasStyle) {
    buf.write('<span style="${styleParts.join('; ')}">');
  }
  for (final w in wrappers) {
    buf.write('<$w>');
  }
  for (final t in run.findElements('t', namespace: '*')) {
    buf.write(_escapeText(t.innerText));
  }
  for (final br in run.findElements('br', namespace: '*')) {
    // Type may be page/column/textWrapping; treat all as <br>.
    // Avoid using br for that — keep it simple.
    final _ = br;
    buf.write('<br>');
  }
  for (final w in wrappers.reversed) {
    buf.write('</$w>');
  }
  if (hasStyle) buf.write('</span>');
}

bool _hasOnElement(XmlElement parent, String name) {
  final el = parent.findElements(name, namespace: '*').firstOrNull;
  if (el == null) return false;
  // <w:b/> or <w:b w:val="true"/> means bold; <w:b w:val="false"/> means off.
  final val = el.attributes
      .where((a) => a.localName == 'val')
      .map((a) => a.value)
      .firstOrNull;
  return val == null || val == '1' || val == 'true' || val == 'on';
}

String? _paragraphStyle(XmlElement p) {
  final pPr = p.findElements('pPr', namespace: '*').firstOrNull;
  if (pPr == null) return null;
  final pStyle = pPr.findElements('pStyle', namespace: '*').firstOrNull;
  if (pStyle == null) return null;
  return pStyle.attributes
      .where((a) => a.localName == 'val')
      .map((a) => a.value)
      .firstOrNull;
}

String? _headingTag(String? styleName) {
  if (styleName == null) return null;
  final m = RegExp(r'^Heading([1-6])$').firstMatch(styleName);
  if (m != null) return 'h${m.group(1)}';
  return null;
}

class _ListInfo {
  _ListInfo({required this.ordered, required this.indent});
  final bool ordered;
  final int indent;
}

_ListInfo? _detectList(XmlElement p) {
  final pPr = p.findElements('pPr', namespace: '*').firstOrNull;
  if (pPr == null) return null;
  final numPr = pPr.findElements('numPr', namespace: '*').firstOrNull;
  if (numPr == null) return null;
  final ilvl = numPr.findElements('ilvl', namespace: '*').firstOrNull;
  final numId = numPr.findElements('numId', namespace: '*').firstOrNull;
  if (numId == null) return null;
  final indentStr = ilvl?.attributes
      .where((a) => a.localName == 'val')
      .map((a) => a.value)
      .firstOrNull;
  final indent = int.tryParse(indentStr ?? '0') ?? 0;
  // Without parsing numbering.xml we can't know if numId references an
  // ordered or bullet list. Heuristic: if the paragraph has a "ListNumber"
  // or "ListParagraph" pStyle, default to bullet; consumer can override
  // by examining numbering.xml in a richer pass.
  final styleName = _paragraphStyle(p);
  final ordered = styleName != null &&
      (styleName.contains('Number') || styleName.contains('Ordered'));
  return _ListInfo(ordered: ordered, indent: indent);
}

String? _hyperlinkTarget(XmlElement hyperlink) {
  // Two forms: r:id reference (resolved via .rels) or anchor.
  // Without parsing _rels we can't resolve r:id; emit anchor when present
  // and for r:id callers can extend later.
  for (final a in hyperlink.attributes) {
    if (a.localName == 'anchor' && a.value.isNotEmpty) return '#${a.value}';
  }
  return null;
}

String _escapeText(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _escapeAttr(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('"', '&quot;');

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
