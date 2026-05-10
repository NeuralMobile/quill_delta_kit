import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

/// Builds the XML body of `word/document.xml` plus a hyperlink relationship
/// table from a Quill [Delta].
///
/// Scope (v0.1):
///   - paragraphs (with align, header style, code-block monospace, blockquote
///     indent)
///   - runs with bold / italic / underline / strike / color / size
///   - bullet + ordered lists (numId 1 = bullet, 2 = ordered; ilvl from
///     `indent` block attr)
///   - hyperlinks (anchor or external URL via relationship id)
///   - line break (within run)
///
/// Out of scope: tables, images, comments, track changes, footnotes,
/// embedded objects.
class OoxmlBuildResult {
  OoxmlBuildResult({required this.bodyXml, required this.hyperlinks});

  /// Inner content of `<w:body>` — does not include the body element itself
  /// or the document/xml prolog.
  final String bodyXml;

  /// Hyperlink relationships needed in `word/_rels/document.xml.rels`.
  /// Map of relationship id -> external URL.
  final Map<String, String> hyperlinks;
}

OoxmlBuildResult buildOoxmlBody(Delta delta) {
  final lines = splitIntoLines(delta);
  final buf = StringBuffer();
  final hyperlinks = <String, String>{};
  var nextRelId = 1000;

  String addHyperlink(String url) {
    final id = 'rId$nextRelId';
    nextRelId++;
    hyperlinks[id] = url;
    return id;
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final block = line.blockAttrs ?? const <String, dynamic>{};

    // List paragraph: write each as <w:p> with numPr.
    if (block['list'] != null) {
      final type = block['list'].toString();
      final indent = (block['indent'] is num) ? (block['indent'] as num).toInt() : 0;
      final numId = type == 'ordered' ? 2 : 1;
      buf.write('<w:p><w:pPr><w:pStyle w:val="ListParagraph"/>');
      buf.write('<w:numPr>');
      buf.write('<w:ilvl w:val="$indent"/>');
      buf.write('<w:numId w:val="$numId"/>');
      buf.write('</w:numPr></w:pPr>');
      _writeRuns(line.ops, buf, addHyperlink);
      buf.write('</w:p>');
      i++;
      continue;
    }

    // Code block.
    if (block['code-block'] != null && block['code-block'] != false) {
      while (i < lines.length) {
        final l = lines[i];
        final cb = l.blockAttrs?['code-block'];
        if (cb == null || cb == false) break;
        buf.write('<w:p><w:pPr><w:pStyle w:val="HTMLCode"/></w:pPr>');
        _writeRuns(l.ops, buf, addHyperlink, monospace: true);
        buf.write('</w:p>');
        i++;
      }
      continue;
    }

    // Header.
    final header = block['header'];
    if (header is num) {
      final level = header.toInt().clamp(1, 6);
      buf.write('<w:p><w:pPr><w:pStyle w:val="Heading$level"/>');
      _writePPrInner(buf, block);
      buf.write('</w:pPr>');
      _writeRuns(line.ops, buf, addHyperlink);
      buf.write('</w:p>');
      i++;
      continue;
    }

    // Blockquote.
    if (block['blockquote'] != null && block['blockquote'] != false) {
      while (i < lines.length) {
        final l = lines[i];
        final bb = l.blockAttrs ?? const <String, dynamic>{};
        if (bb['blockquote'] == null || bb['blockquote'] == false) break;
        buf.write('<w:p><w:pPr><w:pStyle w:val="Quote"/>');
        _writePPrInner(buf, bb);
        buf.write('</w:pPr>');
        _writeRuns(l.ops, buf, addHyperlink);
        buf.write('</w:p>');
        i++;
      }
      continue;
    }

    // Plain paragraph.
    buf.write('<w:p>');
    final hasPPr =
        block['align'] != null || block['indent'] != null || block['direction'] != null || block['line-height'] != null;
    if (hasPPr) {
      buf.write('<w:pPr>');
      _writePPrInner(buf, block);
      buf.write('</w:pPr>');
    }
    _writeRuns(line.ops, buf, addHyperlink);
    buf.write('</w:p>');
    i++;
  }

  return OoxmlBuildResult(bodyXml: buf.toString(), hyperlinks: hyperlinks);
}

void _writePPrInner(StringBuffer buf, Map<String, dynamic> block) {
  final align = block['align']?.toString();
  if (align != null) {
    final mapped = switch (align) {
      'center' => 'center',
      'right' => 'right',
      'justify' => 'both',
      _ => null,
    };
    if (mapped != null) buf.write('<w:jc w:val="$mapped"/>');
  }
  final indent = block['indent'];
  if (indent is num && indent > 0) {
    // OOXML twentieths of a point; 720 = 0.5 inch ~ 1 indent level.
    final twips = (indent * 720).toInt();
    buf.write('<w:ind w:left="$twips"/>');
  }
  final dir = block['direction']?.toString();
  if (dir == 'rtl') buf.write('<w:bidi/>');
}

void _writeRuns(
  List<InlineOp> ops,
  StringBuffer buf,
  String Function(String url) addHyperlink, {
  bool monospace = false,
}) {
  for (final op in ops) {
    if (op.isEmbed) {
      _writeEmbed(op, buf);
      continue;
    }
    final attrs = op.attributes ?? const <String, dynamic>{};
    final link = attrs['link']?.toString();
    if (link != null && link.isNotEmpty) {
      final relId = addHyperlink(link);
      buf.write('<w:hyperlink r:id="$relId">');
      _writeRun(op.asText, attrs, buf, monospace: monospace);
      buf.write('</w:hyperlink>');
    } else {
      _writeRun(op.asText, attrs, buf, monospace: monospace);
    }
  }
}

void _writeRun(
  String text,
  Map<String, dynamic> attrs,
  StringBuffer buf, {
  bool monospace = false,
}) {
  buf.write('<w:r>');
  final hasRpr = monospace ||
      _truthy(attrs['bold']) ||
      _truthy(attrs['italic']) ||
      _truthy(attrs['underline']) ||
      _truthy(attrs['strike']) ||
      _truthy(attrs['code']) ||
      attrs['color'] != null ||
      attrs['size'] != null ||
      attrs['font'] != null;
  if (hasRpr) {
    buf.write('<w:rPr>');
    if (monospace || _truthy(attrs['code'])) {
      buf.write('<w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/>');
    }
    if (_truthy(attrs['bold'])) buf.write('<w:b/>');
    if (_truthy(attrs['italic'])) buf.write('<w:i/>');
    if (_truthy(attrs['underline'])) {
      buf.write('<w:u w:val="single"/>');
    }
    if (_truthy(attrs['strike'])) buf.write('<w:strike/>');
    final color = attrs['color']?.toString();
    if (color != null && color.isNotEmpty) {
      final hex = _toHex6(color);
      if (hex != null) buf.write('<w:color w:val="$hex"/>');
    }
    final size = attrs['size']?.toString();
    if (size != null && size.isNotEmpty) {
      final px = _toPx(size);
      if (px != null) {
        // OOXML stores half-points. Approx px-> pt: pt = px * 0.75.
        final halfPt = (px * 0.75 * 2).round();
        buf.write('<w:sz w:val="$halfPt"/>');
      }
    }
    final font = attrs['font']?.toString();
    if (font != null && font.isNotEmpty) {
      final escaped = _escapeAttr(font);
      buf.write('<w:rFonts w:ascii="$escaped" w:hAnsi="$escaped"/>');
    }
    buf.write('</w:rPr>');
  }
  // Split on \n: each becomes a <w:br/>.
  final parts = text.split('\n');
  for (var i = 0; i < parts.length; i++) {
    if (i > 0) buf.write('<w:br/>');
    if (parts[i].isNotEmpty) {
      buf.write('<w:t xml:space="preserve">');
      buf.write(_escapeText(parts[i]));
      buf.write('</w:t>');
    }
  }
  buf.write('</w:r>');
}

void _writeEmbed(InlineOp op, StringBuffer buf) {
  final embed = op.asEmbed;
  if (embed.isEmpty) return;
  final type = embed.keys.first;
  // Best-effort: emit nothing for unknown embeds (preserves surrounding text);
  // dividers as a thin paragraph separator.
  if (type == 'divider' || type == 'hr') {
    buf.write(
      '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" '
      'w:space="1" w:color="auto"/></w:pBdr></w:pPr></w:p>',
    );
  }
}

bool _truthy(Object? v) => v == true || v == 'true' || v == 1;

String? _toHex6(String css) {
  // Accept #rgb, #rrggbb, rgb(...), rgba(...), named.
  final c = CssColor.parse(css) ?? CssColor.parseArgb(css);
  if (c == null) return null;
  String h(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '${h(c.r)}${h(c.g)}${h(c.b)}';
}

double? _toPx(String css) {
  final s = QuillSize.toCss(css);
  final m = RegExp(r'^([0-9]+(?:\.[0-9]+)?)px$').firstMatch(s);
  if (m == null) return null;
  return double.tryParse(m.group(1)!);
}

String _escapeText(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _escapeAttr(String s) => _escapeText(s).replaceAll('"', '&quot;');
