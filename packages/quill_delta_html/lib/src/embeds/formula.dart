import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/dom_serializer.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

/// Formula (KaTeX / LaTeX / MathML).
///
/// Encodes by default as `<span class="ql-formula" data-formula="...">`. If
/// [renderer] is provided, its HTML output is also injected so browsers that
/// don't have KaTeX loaded still see rendered math.
///
/// Decoder accepts:
/// - `<span class="ql-formula" data-formula="...">`
/// - `<span data-value="...">` (Quill 1.x convention)
/// - `<math>...</math>` (MathML)
/// - KaTeX `<span class="katex">...</span>`
class FormulaAdapter extends EmbedAdapter {
  FormulaAdapter({this.renderer});

  /// Optional pre-renderer. Receives the TeX string, returns HTML to embed
  /// alongside `data-formula` (e.g. KaTeX-rendered HTML).
  final String Function(String tex)? renderer;

  @override
  String get type => 'formula';

  @override
  String? get css => '''
.ql-formula { font-family: 'Cambria Math', 'STIX', serif; }
''';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final tex = value is String ? value : value?.toString() ?? '';
    writer.open('span', {
      'class': 'ql-formula',
      'data-formula': tex,
    });
    if (renderer != null) {
      final rendered = renderer!(tex);
      if (rendered.trim().isNotEmpty) {
        // Renderer output is HTML; emit verbatim. Caller is responsible for
        // safety (this is the same contract as before — renderer is trusted).
        writer.raw(rendered);
        writer.close('span');
        return;
      }
    }
    writer.text(tex);
    writer.close('span');
  }

  @override
  bool matches(dom.Element element) {
    final name = element.localName;
    if (name == 'math') return true;
    if (name == 'span') {
      final cls = (element.attributes['class'] ?? '').split(' ');
      if (cls.contains('ql-formula')) return true;
      if (cls.contains('katex')) return true;
      if (cls.contains('katex-display')) return true;
      if (element.attributes.containsKey('data-formula')) return true;
      if (element.attributes.containsKey('data-value')) return true;
    }
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final tex = _extractTex(element);
    return {
      'insert': {'formula': tex},
    };
  }

  String _extractTex(dom.Element el) {
    final dataFormula = el.attributes['data-formula'];
    if (dataFormula != null && dataFormula.isNotEmpty) return dataFormula;

    final dataValue = el.attributes['data-value'];
    if (dataValue != null && dataValue.isNotEmpty) return dataValue;

    final annotation =
        el.querySelector('annotation[encoding="application/x-tex"]');
    if (annotation != null && annotation.text.trim().isNotEmpty) {
      return annotation.text.trim();
    }

    final katexAnnotation =
        el.querySelector('.katex annotation') ?? el.querySelector('annotation');
    if (katexAnnotation != null && katexAnnotation.text.trim().isNotEmpty) {
      return katexAnnotation.text.trim();
    }

    if (el.localName == 'math') {
      return DomSerializer().serialize(el);
    }

    return el.text.trim();
  }
}
