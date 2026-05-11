import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlOptions value semantics', () {
    test('default ctor equality + identical hashCodes', () {
      const a = HtmlOptions();
      const b = HtmlOptions();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('field difference breaks equality', () {
      const a = HtmlOptions();
      const b = HtmlOptions(wrapDocument: false);
      expect(a, isNot(equals(b)));
    });

    test('copyWith overrides only the requested field', () {
      const original = HtmlOptions();
      final updated = original.copyWith(wrapDocument: false);
      expect(updated.wrapDocument, false);
      expect(updated.preserveWhitespace, original.preserveWhitespace);
      expect(updated.canonicalColorFormat, original.canonicalColorFormat);
    });

    test('IframePolicy freezes collections passed in', () {
      final hosts = <String>{'a.test'};
      final policy = IframePolicy(allowedHosts: hosts);
      hosts.add('b.test');
      // Mutating the source set must NOT mutate the policy's view.
      expect(policy.allowedHosts, {'a.test'});
      // The policy's set itself is unmodifiable.
      expect(() => policy.allowedHosts.add('c.test'), throwsUnsupportedError);
    });

    test('IframePolicy equality and copyWith', () {
      final a = IframePolicy(allowedHosts: const {'x.test'});
      final b = IframePolicy(allowedHosts: const {'x.test'});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      final c = a.copyWith(allowedHosts: const {'y.test'});
      expect(c.allowedHosts, {'y.test'});
      expect(c, isNot(equals(a)));
    });
  });

  group('MarkdownOptions value semantics', () {
    test('equality + hashCode', () {
      const a = MarkdownOptions();
      const b = MarkdownOptions();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith narrows one field', () {
      const a = MarkdownOptions();
      final b = a.copyWith(flavour: MarkdownFlavour.commonmark);
      expect(b.flavour, MarkdownFlavour.commonmark);
      expect(b.allowHtmlPassthrough, a.allowHtmlPassthrough);
    });
  });

  group('DocxOptions value semantics', () {
    test('equality + hashCode', () {
      const a = DocxOptions();
      const b = DocxOptions();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith preserves other fields', () {
      const a = DocxOptions();
      final b = a.copyWith(pageSize: DocxPageSize.letter);
      expect(b.pageSize, DocxPageSize.letter);
      expect(b.defaultFontFamily, a.defaultFontFamily);
      expect(b.defaultFontSizePt, a.defaultFontSizePt);
    });
  });
}
