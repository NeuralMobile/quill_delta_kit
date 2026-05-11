import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:quill_delta_core/quill_delta_core.dart';
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
  late final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (e, st) {
    throw MalformedDocumentException(
      'docx',
      'Could not unzip .docx archive.',
      cause: e,
      causeStack: st,
    );
  }
  final docFile = archive.files.firstWhere(
    (f) => f.name == 'word/document.xml',
    orElse: () => throw const MalformedDocumentException(
      'docx',
      'Not a valid .docx: missing word/document.xml',
    ),
  );
  final xmlString =
      utf8.decode(docFile.content as List<int>, allowMalformed: true);
  final doc = XmlDocument.parse(xmlString);

  // Parse numbering.xml if present so list detection knows ordered vs bullet
  // per (numId, ilvl).
  final numberingFile =
      archive.files.where((f) => f.name == 'word/numbering.xml').firstOrNull;
  final numbering = numberingFile == null
      ? const _NumberingMap.empty()
      : _NumberingMap.parse(
          utf8.decode(numberingFile.content as List<int>, allowMalformed: true),
        );

  // Parse word/_rels/document.xml.rels (relationships table) so <a:blip>
  // r:embed=rId references resolve to media file paths.
  final relsFile = archive.files
      .where((f) => f.name == 'word/_rels/document.xml.rels')
      .firstOrNull;
  final relationships = relsFile == null
      ? const _Relationships.empty()
      : _Relationships.parse(
          utf8.decode(relsFile.content as List<int>, allowMalformed: true),
        );

  // Index every embedded media file by its path inside word/ so the blip
  // resolver can look them up by relationship target.
  final media = <String, List<int>>{};
  for (final f in archive.files) {
    if (f.name.startsWith('word/media/')) {
      media[f.name.substring('word/'.length)] = (f.content as List<int>);
    }
  }

  final body = doc.findAllElements('body', namespace: '*').firstOrNull;
  if (body == null) return '';

  final buf = StringBuffer();
  _writeBody(body, buf, numbering, _ImageContext(relationships, media));
  return buf.toString();
}

/// Bag passed through the body walker so individual run handlers can
/// resolve `<a:blip r:embed="rIdN"/>` references to data-URI <img> tags.
class _ImageContext {
  const _ImageContext(this.relationships, this.media);
  final _Relationships relationships;
  final Map<String, List<int>> media;
}

class _Relationships {
  const _Relationships(this.idToTarget);
  const _Relationships.empty() : idToTarget = const {};
  final Map<String, String> idToTarget;

  factory _Relationships.parse(String xml) {
    final doc = XmlDocument.parse(xml);
    final map = <String, String>{};
    for (final rel in doc.findAllElements('Relationship', namespace: '*')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id != null && target != null) map[id] = target;
    }
    return _Relationships(map);
  }
}

void _writeBody(
  XmlElement body,
  StringBuffer buf,
  _NumberingMap numbering,
  _ImageContext images,
) {
  // Open <ul>/<ol> stack and parallel <li>-open tracker, mirrors the
  // BlockEncoder algorithm in quill_delta_html so nested lists emit valid
  // HTML (`<li>...<ul>...</ul></li>`) rather than sibling lists.
  final openLists = <String>[];
  final liOpen = <bool>[];
  String? listTagFamily; // 'ul' or 'ol'

  void closeOpenList() {
    while (openLists.isNotEmpty) {
      if (liOpen.last) buf.write('</li>');
      buf.write('</${openLists.last}>');
      openLists.removeLast();
      liOpen.removeLast();
      if (liOpen.isNotEmpty && liOpen.last) {
        buf.write('</li>');
        liOpen[liOpen.length - 1] = false;
      }
    }
    listTagFamily = null;
  }

  for (final el in body.childElements) {
    final name = el.localName;
    if (name == 'p') {
      final listInfo = _detectList(el, numbering);
      if (listInfo != null) {
        final tag = listInfo.ordered ? 'ol' : 'ul';

        if (listTagFamily != null && listTagFamily != tag) {
          closeOpenList();
        }
        listTagFamily = tag;

        final targetDepth = listInfo.indent + 1;
        // De-nest if needed.
        while (openLists.length > targetDepth) {
          if (liOpen.last) buf.write('</li>');
          buf.write('</${openLists.last}>');
          openLists.removeLast();
          liOpen.removeLast();
          if (liOpen.isNotEmpty && liOpen.last) {
            buf.write('</li>');
            liOpen[liOpen.length - 1] = false;
          }
        }
        // Nest deeper if needed.
        while (openLists.length < targetDepth) {
          if (openLists.isNotEmpty && !liOpen.last) {
            buf.write('<li>');
            liOpen[liOpen.length - 1] = true;
          }
          buf.write('<$tag>');
          openLists.add(tag);
          liOpen.add(false);
        }
        // Close any previously open <li> at this depth before fresh one.
        if (liOpen.last) {
          buf.write('</li>');
          liOpen[liOpen.length - 1] = false;
        }
        buf.write('<li>');
        _writeRuns(el, buf, images);
        liOpen[liOpen.length - 1] = true;
      } else {
        closeOpenList();
        final styleName = _paragraphStyle(el);
        final tag = _headingTag(styleName) ?? 'p';
        buf.write('<$tag>');
        _writeRuns(el, buf, images);
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
            _writeRuns(p, buf, images);
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

void _writeRuns(
  XmlElement paragraph,
  StringBuffer buf,
  _ImageContext images,
) {
  for (final node in paragraph.children) {
    if (node is! XmlElement) continue;
    final n = node.localName;
    if (n == 'r') {
      _writeRun(node, buf, images);
    } else if (n == 'hyperlink') {
      // Hyperlinks wrap runs.
      final href = _hyperlinkTarget(node);
      if (href != null) {
        buf.write('<a href="${_escapeAttr(href)}">');
        for (final r in node.findElements('r', namespace: '*')) {
          _writeRun(r, buf, images);
        }
        buf.write('</a>');
      } else {
        for (final r in node.findElements('r', namespace: '*')) {
          _writeRun(r, buf, images);
        }
      }
    }
  }
}

void _writeRun(XmlElement run, StringBuffer buf, _ImageContext images) {
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
      // OOXML stores size in half-points -> points (hp/2) -> pixels (* 4/3).
      // Symmetric inverse of DocxExporter's `(px * 0.75 * 2).round()`.
      final hp = int.tryParse(szVal);
      if (hp != null) {
        final px = (hp / 2.0) * 4.0 / 3.0;
        final rounded = px.round();
        sizeVal = '${rounded}px';
      }
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
  // <w:drawing> nodes carry images (and other DrawingML content). We pull
  // out picture-bearing blips and emit <img src="data:...">.
  for (final drawing in run.findElements('drawing', namespace: '*')) {
    _writeDrawingImage(drawing, buf, images);
  }
  for (final w in wrappers.reversed) {
    buf.write('</$w>');
  }
  if (hasStyle) buf.write('</span>');
}

/// Walk a `<w:drawing>` looking for the first `<a:blip r:embed="..."/>`,
/// resolve the embed id through the document's relationships, and emit an
/// `<img>` tag with a data-URI src. Width/height come from the optional
/// `<wp:extent>` element (EMU units; 9525 EMU = 1 px at 96 DPI).
void _writeDrawingImage(
  XmlElement drawing,
  StringBuffer buf,
  _ImageContext images,
) {
  XmlElement? blip;
  for (final candidate in drawing.descendants.whereType<XmlElement>()) {
    if (candidate.localName == 'blip') {
      blip = candidate;
      break;
    }
  }
  if (blip == null) return;
  final embedId = blip.attributes
      .where((a) => a.localName == 'embed')
      .map((a) => a.value)
      .firstOrNull;
  if (embedId == null) return;
  final target = images.relationships.idToTarget[embedId];
  if (target == null) return;
  final bytes = images.media[target];
  if (bytes == null) return;
  final mime = _mimeFromPath(target);
  final dataUri = 'data:$mime;base64,${base64.encode(bytes)}';

  String? width;
  String? height;
  for (final ext in drawing.descendants.whereType<XmlElement>()) {
    if (ext.localName != 'extent') continue;
    final cx = int.tryParse(ext.getAttribute('cx') ?? '');
    final cy = int.tryParse(ext.getAttribute('cy') ?? '');
    if (cx != null) width = (cx / 9525).round().toString();
    if (cy != null) height = (cy / 9525).round().toString();
    break;
  }

  buf.write('<img src="${_escapeAttr(dataUri)}"');
  if (width != null) buf.write(' width="$width"');
  if (height != null) buf.write(' height="$height"');
  buf.write('>');
}

String _mimeFromPath(String path) {
  final i = path.lastIndexOf('.');
  if (i == -1 || i == path.length - 1) return 'application/octet-stream';
  final ext = path.substring(i + 1).toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'svg':
      return 'image/svg+xml';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    case 'tif':
    case 'tiff':
      return 'image/tiff';
    default:
      return 'application/octet-stream';
  }
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

_ListInfo? _detectList(XmlElement p, _NumberingMap numbering) {
  final pPr = p.findElements('pPr', namespace: '*').firstOrNull;
  if (pPr == null) return null;
  final numPr = pPr.findElements('numPr', namespace: '*').firstOrNull;
  if (numPr == null) return null;
  final ilvl = numPr.findElements('ilvl', namespace: '*').firstOrNull;
  final numIdEl = numPr.findElements('numId', namespace: '*').firstOrNull;
  if (numIdEl == null) return null;
  final indentStr = ilvl?.attributes
      .where((a) => a.localName == 'val')
      .map((a) => a.value)
      .firstOrNull;
  final indent = int.tryParse(indentStr ?? '0') ?? 0;
  final numIdStr = numIdEl.attributes
      .where((a) => a.localName == 'val')
      .map((a) => a.value)
      .firstOrNull;
  final numId = int.tryParse(numIdStr ?? '');

  // Resolve via numbering.xml when available.
  if (numId != null) {
    final fmt = numbering.formatFor(numId, indent);
    if (fmt != null) {
      return _ListInfo(ordered: fmt == _NumFmt.ordered, indent: indent);
    }
  }
  // Fall back to pStyle heuristic when numbering.xml is absent.
  final styleName = _paragraphStyle(p);
  final ordered = styleName != null &&
      (styleName.contains('Number') || styleName.contains('Ordered'));
  return _ListInfo(ordered: ordered, indent: indent);
}

enum _NumFmt { bullet, ordered }

class _NumberingMap {
  const _NumberingMap._(this._numIdToAbstract, this._abstractToFmt);
  const _NumberingMap.empty()
      : _numIdToAbstract = const {},
        _abstractToFmt = const {};

  final Map<int, int> _numIdToAbstract;
  // abstractNumId -> ilvl -> format
  final Map<int, Map<int, _NumFmt>> _abstractToFmt;

  factory _NumberingMap.parse(String xml) {
    final doc = XmlDocument.parse(xml);
    final numIdToAbstract = <int, int>{};
    for (final num in doc.findAllElements('num', namespace: '*')) {
      final numIdStr = num.attributes
          .where((a) => a.localName == 'numId')
          .map((a) => a.value)
          .firstOrNull;
      final numId = int.tryParse(numIdStr ?? '');
      if (numId == null) continue;
      final abs = num.findElements('abstractNumId', namespace: '*').firstOrNull;
      final absVal = abs?.attributes
          .where((a) => a.localName == 'val')
          .map((a) => a.value)
          .firstOrNull;
      final absId = int.tryParse(absVal ?? '');
      if (absId != null) numIdToAbstract[numId] = absId;
    }
    final abstractToFmt = <int, Map<int, _NumFmt>>{};
    for (final abs in doc.findAllElements('abstractNum', namespace: '*')) {
      final absIdStr = abs.attributes
          .where((a) => a.localName == 'abstractNumId')
          .map((a) => a.value)
          .firstOrNull;
      final absId = int.tryParse(absIdStr ?? '');
      if (absId == null) continue;
      final levelMap = <int, _NumFmt>{};
      for (final lvl in abs.findElements('lvl', namespace: '*')) {
        final ilvlStr = lvl.attributes
            .where((a) => a.localName == 'ilvl')
            .map((a) => a.value)
            .firstOrNull;
        final ilvl = int.tryParse(ilvlStr ?? '');
        if (ilvl == null) continue;
        final numFmt = lvl.findElements('numFmt', namespace: '*').firstOrNull;
        final fmtVal = numFmt?.attributes
            .where((a) => a.localName == 'val')
            .map((a) => a.value)
            .firstOrNull;
        if (fmtVal == null) continue;
        levelMap[ilvl] = fmtVal == 'bullet' ? _NumFmt.bullet : _NumFmt.ordered;
      }
      abstractToFmt[absId] = levelMap;
    }
    return _NumberingMap._(numIdToAbstract, abstractToFmt);
  }

  _NumFmt? formatFor(int numId, int ilvl) {
    final abs = _numIdToAbstract[numId];
    if (abs == null) return null;
    return _abstractToFmt[abs]?[ilvl];
  }
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
