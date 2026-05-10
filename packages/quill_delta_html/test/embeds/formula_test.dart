import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  group('formula adapter', () {
    final c = frag();

    test('encode raw TeX', () {
      final html = c.encode(deltaOf([
        {'insert': {'formula': 'e^{i\\pi}+1=0'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('class="ql-formula"'));
      expect(html, contains(r'data-formula="e^{i\pi}+1=0"'));
    });

    test('decode ql-formula', () {
      const html = '<p><span class="ql-formula" data-formula="x^2">x^2</span></p>';
      expect(c.decode(html).toJson().first['insert']['formula'], 'x^2');
    });

    test('decode Quill 1.x data-value', () {
      const html = '<p><span data-value="a+b">a+b</span></p>';
      expect(c.decode(html).toJson().first['insert']['formula'], 'a+b');
    });

    test('decode KaTeX with annotation', () {
      const html = '<p><span class="katex">'
          '<span class="katex-mathml">'
          '<math><semantics><mrow><mi>x</mi></mrow>'
          '<annotation encoding="application/x-tex">x</annotation>'
          '</semantics></math>'
          '</span></span></p>';
      // Decoder picks up the span.katex first (matches before <math> is reached).
      final ops = c.decode(html).toJson();
      expect(ops.first['insert']['formula'], 'x');
    });

    test('decode raw MathML', () {
      const html = '<p><math><mi>x</mi></math></p>';
      final ops = c.decode(html).toJson();
      // Contains <math> serialization.
      expect(ops.first['insert']['formula'], contains('<math'));
    });

    test('renderer hook injects rendered HTML', () {
      final cR = QuillHtmlCodec(
        adapters: [
          FormulaAdapter(renderer: (tex) => '<span class="rendered">[[$tex]]</span>'),
        ],
        options: const QuillHtmlOptions(wrapDocument: false),
      );
      final html = cR.encode(deltaOf([
        {'insert': {'formula': 'x^2'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('class="rendered"'));
      expect(html, contains('[[x^2]]'));
    });
  });
}
