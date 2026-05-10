import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:quill_delta_core/quill_delta_core.dart';

import 'pdf_options.dart';

/// Delta -> PDF bytes (pure Dart writer via package:pdf).
///
/// Scope (v0.1):
///   - paragraphs (with align, indent)
///   - headings H1-H6
///   - blockquotes (italic + left padding)
///   - code blocks (monospace, light grey background)
///   - bullet + ordered lists (numbered per indent level)
///   - inline: bold, italic, underline, strike, color, font size, links
///   - dividers
///
/// Out of scope: tables, images, custom embeds, multi-column layout.
final class PdfExporter implements DeltaExporter<List<int>, PdfOptions> {
  const PdfExporter({PdfOptions? defaultOptions})
      : _defaultOptions = defaultOptions;

  final PdfOptions? _defaultOptions;

  @override
  String get format => 'pdf';

  @override
  String get mimeType => 'application/pdf';

  @override
  String get extension => 'pdf';

  @override
  PdfOptions get defaultOptions => _defaultOptions ?? const PdfOptions();

  @override
  Future<List<int>> export(Delta delta, {PdfOptions? options}) async {
    final opts = options ?? defaultOptions;
    final pageFormat = switch (opts.pageSize) {
      PdfPageSize.a4 => PdfPageFormat.a4,
      PdfPageSize.letter => PdfPageFormat.letter,
      PdfPageSize.legal => PdfPageFormat.legal,
    };

    final doc = pw.Document(compress: opts.compress);
    final widgets = _buildWidgets(delta);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (_) => widgets,
      ),
    );
    return doc.save();
  }
}

List<pw.Widget> _buildWidgets(Delta delta) {
  final lines = splitIntoLines(delta);
  final out = <pw.Widget>[];
  final orderedCounters = <int, int>{};

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final block = line.blockAttrs ?? const <String, dynamic>{};

    // Code block — group consecutive code lines into one container.
    if (block['code-block'] != null && block['code-block'] != false) {
      final codeBuf = StringBuffer();
      while (i < lines.length) {
        final l = lines[i];
        final cb = l.blockAttrs?['code-block'];
        if (cb == null || cb == false) break;
        for (final op in l.ops) {
          if (op.isText) codeBuf.write(op.asText);
        }
        codeBuf.write('\n');
        i++;
      }
      out.add(pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          codeBuf.toString().trimRight(),
          style: pw.TextStyle(
            font: pw.Font.courier(),
            fontSize: 10,
          ),
        ),
      ));
      continue;
    }

    // Header.
    final header = block['header'];
    if (header is num) {
      final level = header.toInt().clamp(1, 6);
      out.add(_buildParagraph(
        line.ops,
        block,
        baseFontSize: _headerFontSize(level),
        bold: true,
        topPadding: 12,
      ));
      i++;
      orderedCounters.clear();
      continue;
    }

    // Blockquote.
    if (block['blockquote'] != null && block['blockquote'] != false) {
      final children = <pw.Widget>[];
      while (i < lines.length) {
        final l = lines[i];
        final bb = l.blockAttrs ?? const <String, dynamic>{};
        if (bb['blockquote'] == null || bb['blockquote'] == false) break;
        children.add(_buildParagraph(l.ops, bb, italic: true));
        i++;
      }
      out.add(pw.Container(
        margin: const pw.EdgeInsets.only(left: 16),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.grey, width: 2),
          ),
        ),
        padding: const pw.EdgeInsets.only(left: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: children,
        ),
      ));
      orderedCounters.clear();
      continue;
    }

    // List item.
    if (block['list'] != null) {
      final type = block['list'].toString();
      final indent =
          (block['indent'] is num) ? (block['indent'] as num).toInt() : 0;
      String marker;
      switch (type) {
        case 'ordered':
          final n = (orderedCounters[indent] ??= 0) + 1;
          orderedCounters[indent] = n;
          marker = '$n. ';
          break;
        case 'checked':
          marker = '☑ ';
          break;
        case 'unchecked':
          marker = '☐ ';
          break;
        default:
          marker = '• ';
      }
      orderedCounters.removeWhere((k, _) => k > indent);
      out.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: 16.0 * indent),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(marker),
            pw.Expanded(child: _buildParagraph(line.ops, block)),
          ],
        ),
      ));
      i++;
      continue;
    }

    // Block-level divider/hr.
    if (line.ops.length == 1 && line.ops.first.isEmbed) {
      final embed = line.ops.first.asEmbed;
      if (embed.isNotEmpty &&
          (embed.keys.first == 'divider' || embed.keys.first == 'hr')) {
        out.add(pw.Divider());
        i++;
        orderedCounters.clear();
        continue;
      }
    }

    // Plain paragraph.
    if (line.ops.isEmpty) {
      out.add(pw.SizedBox(height: 8));
    } else {
      out.add(_buildParagraph(line.ops, block));
    }
    orderedCounters.clear();
    i++;
  }
  return out;
}

double _headerFontSize(int level) =>
    [24.0, 20.0, 16.0, 14.0, 12.0, 11.0][level - 1];

pw.Widget _buildParagraph(
  List<InlineOp> ops,
  Map<String, dynamic> block, {
  double? baseFontSize,
  bool bold = false,
  bool italic = false,
  double topPadding = 0,
}) {
  final spans = <pw.InlineSpan>[];
  for (final op in ops) {
    if (op.isEmbed) continue;
    final text = op.asText;
    if (text.isEmpty) continue;
    final attrs = op.attributes ?? const <String, dynamic>{};
    spans.add(_buildSpan(text, attrs,
        bold: bold, italic: italic, baseFontSize: baseFontSize));
  }
  if (spans.isEmpty) {
    return pw.SizedBox(height: baseFontSize ?? 11);
  }
  final align = block['align']?.toString();
  final textAlign = switch (align) {
    'center' => pw.TextAlign.center,
    'right' => pw.TextAlign.right,
    'justify' => pw.TextAlign.justify,
    _ => pw.TextAlign.left,
  };
  final indent = block['indent'];
  final indentPx =
      (indent is num && indent > 0) ? indent.toDouble() * 16 : 0.0;
  return pw.Padding(
    padding: pw.EdgeInsets.only(top: topPadding, left: indentPx, bottom: 4),
    child: pw.RichText(
      text: pw.TextSpan(children: spans),
      textAlign: textAlign,
    ),
  );
}

pw.InlineSpan _buildSpan(
  String text,
  Map<String, dynamic> attrs, {
  bool bold = false,
  bool italic = false,
  double? baseFontSize,
}) {
  final wantsBold = bold || _truthy(attrs['bold']);
  final wantsItalic = italic || _truthy(attrs['italic']);
  final underline = _truthy(attrs['underline']);
  final strike = _truthy(attrs['strike']);
  final code = _truthy(attrs['code']);
  final color = _parseColor(attrs['color']);
  final size = _parseSize(attrs['size']) ?? baseFontSize;

  pw.Font? font;
  pw.FontWeight? weight;
  pw.FontStyle? fontStyle;
  if (code) {
    font = pw.Font.courier();
  } else if (wantsBold && wantsItalic) {
    font = pw.Font.helveticaBoldOblique();
    weight = pw.FontWeight.bold;
    fontStyle = pw.FontStyle.italic;
  } else if (wantsBold) {
    font = pw.Font.helveticaBold();
    weight = pw.FontWeight.bold;
  } else if (wantsItalic) {
    font = pw.Font.helveticaOblique();
    fontStyle = pw.FontStyle.italic;
  }

  final decorations = <pw.TextDecoration>[];
  if (underline) decorations.add(pw.TextDecoration.underline);
  if (strike) decorations.add(pw.TextDecoration.lineThrough);

  final style = pw.TextStyle(
    font: font,
    fontSize: size,
    color: color,
    fontWeight: weight,
    fontStyle: fontStyle,
    decoration: decorations.isEmpty
        ? null
        : pw.TextDecoration.combine(decorations),
  );

  final link = attrs['link']?.toString();
  if (link != null && link.isNotEmpty) {
    return pw.WidgetSpan(
      child: pw.UrlLink(
        destination: link,
        child: pw.Text(
          text,
          style: style.copyWith(color: PdfColors.blue),
        ),
      ),
    );
  }
  return pw.TextSpan(text: text, style: style);
}

PdfColor? _parseColor(Object? raw) {
  if (raw == null) return null;
  final s = raw.toString();
  final c = CssColor.parse(s) ?? CssColor.parseArgb(s);
  if (c == null) return null;
  return PdfColor.fromInt(
    (c.a << 24) | (c.r << 16) | (c.g << 8) | c.b,
  );
}

double? _parseSize(Object? raw) {
  if (raw == null) return null;
  final css = QuillSize.toCss(raw.toString());
  final m = RegExp(r'^([0-9]+(?:\.[0-9]+)?)px$').firstMatch(css);
  if (m == null) return null;
  final px = double.parse(m.group(1)!);
  return px * 0.75; // px -> pt approx
}

bool _truthy(Object? v) => v == true || v == 'true' || v == 1;
