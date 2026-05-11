import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:test/test.dart';

void main() {
  group('schema/Attr', () {
    test('inline + block keys disjoint', () {
      expect(Attr.inlineKeys.intersection(Attr.blockKeys), isEmpty);
    });
    test('isInline / isBlock', () {
      expect(Attr.isInline('bold'), true);
      expect(Attr.isBlock('header'), true);
      expect(Attr.isInline('header'), false);
    });
  });

  group('CssColor', () {
    test('round-trips named -> hex', () {
      expect(CssColor.parse('red')!.toCss(), '#ff0000');
    });
    test('rgba alpha', () {
      expect(CssColor.parse('rgba(0, 0, 0, 0.5)')!.toCss(),
          'rgba(0, 0, 0, 0.502)');
    });
  });

  group('QuillSize', () {
    test('named -> px', () => expect(QuillSize.toCss('large'), '18px'));
    test('px -> bare numeric', () => expect(QuillSize.fromCss('14px'), '14'));
  });

  group('splitIntoLines', () {
    test('paragraph + bold split', () {
      final d = Delta()
        ..insert('a ')
        ..insert('b', {'bold': true})
        ..insert('\n');
      final lines = splitIntoLines(d);
      expect(lines.length, 1);
      expect(lines.first.ops.length, 2);
      expect(lines.first.ops.first.asText, 'a ');
      expect(lines.first.ops.last.asText, 'b');
    });
    test('header block attrs extracted', () {
      final d = Delta()
        ..insert('x')
        ..insert('\n', {'header': 1});
      final lines = splitIntoLines(d);
      expect(lines.length, 1);
      expect(lines.first.blockAttrs, {'header': 1});
    });
  });

  group('ConverterRegistry', () {
    test('throws when nothing registered', () async {
      final reg = ConverterRegistry();
      await expectLater(
        () => reg.importAuto('<p>a</p>'),
        throwsA(isA<ConverterNotFound>()),
      );
    });
  });

  group('options inheritance', () {
    test('HtmlOptions extends ConverterOptions', () {
      const o = HtmlOptions();
      expect(o, isA<ConverterOptions>());
      expect(o.unknownEmbedFallback, UnknownEmbedFallback.passthrough);
    });
    test('MarkdownOptions defaults', () {
      const o = MarkdownOptions();
      expect(o.flavour, MarkdownFlavour.gfm);
      expect(o.allowHtmlPassthrough, true);
    });
    test('DocxOptions defaults', () {
      const o = DocxOptions();
      expect(o.imageEmbed, DocxImageEmbed.embedded);
      expect(o.pageSize, DocxPageSize.a4);
    });
  });
}
