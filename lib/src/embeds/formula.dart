import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../options.dart';
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
/// - `<math>...</math>` (MathML; the inner TeX/LaTeX is reconstructed via
///   `data-tex` if present, else MathML is preserved verbatim as the formula
///   value).
/// - KaTeX `<span class="katex">...</span>` (extracts `data-formula` or original
///   TeX from annotation).
class FormulaAdapter extends EmbedAdapter {
  FormulaAdapter({this.renderer});

  /// Optional pre-renderer. Receives the TeX string, returns HTML to embed
  /// alongside `data-formula` (e.g. KaTeX-rendered HTML). Pure Dart
  /// callers can plug `katex_dart` or similar.
  final String Function(String tex)? renderer;

  @override
  String get type => 'formula';

  @override
  String? get css => '''
.ql-formula { font-family: 'Cambria Math', 'STIX', serif; }
''';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final tex = value is String ? value : value?.toString() ?? '';
    final el = dom.Element.tag('span')
      ..attributes['class'] = 'ql-formula'
      ..attributes['data-formula'] = tex;
    if (renderer != null) {
      final rendered = renderer!(tex);
      if (rendered.trim().isNotEmpty) {
        final fragment = html_parser.parseFragment(rendered);
        for (final child in fragment.nodes) {
          el.append(child.clone(true));
        }
        parent.append(el);
        return;
      }
    }
    el.append(dom.Text(tex));
    parent.append(el);
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
    // 1. data-formula attr.
    final dataFormula = el.attributes['data-formula'];
    if (dataFormula != null && dataFormula.isNotEmpty) return dataFormula;

    // 2. Quill 1.x data-value attr.
    final dataValue = el.attributes['data-value'];
    if (dataValue != null && dataValue.isNotEmpty) return dataValue;

    // 3. MathML <math><semantics><annotation encoding="application/x-tex">TeX</annotation>
    final annotation = el.querySelector('annotation[encoding="application/x-tex"]');
    if (annotation != null && annotation.text.trim().isNotEmpty) {
      return annotation.text.trim();
    }

    // 4. KaTeX rendered HTML — look for `<annotation encoding="application/x-tex">` (KaTeX adds this).
    final katexAnnotation = el.querySelector('.katex annotation') ?? el.querySelector('annotation');
    if (katexAnnotation != null && katexAnnotation.text.trim().isNotEmpty) {
      return katexAnnotation.text.trim();
    }

    // 5. <math>: serialize verbatim so the consumer can re-render.
    if (el.localName == 'math') {
      return el.outerHtml;
    }

    // 6. Fallback: text content.
    return el.text.trim();
  }
}
