import 'package:quill_delta_html/src/css/color.dart';
import 'package:quill_delta_html/src/css/size.dart';
import 'package:quill_delta_html/src/css/style_parser.dart';
import 'package:test/test.dart';

void main() {
  group('CssColor', () {
    test('parse #rgb', () {
      final c = CssColor.parse('#f00')!;
      expect(c.toCss(), '#ff0000');
    });
    test('parse #rrggbb', () {
      final c = CssColor.parse('#abcdef')!;
      expect(c.toCss(), '#abcdef');
    });
    test('parse rgb()', () {
      final c = CssColor.parse('rgb(255, 0, 128)')!;
      expect(c.toCss(), '#ff0080');
    });
    test('parse rgba()', () {
      final c = CssColor.parse('rgba(255, 0, 0, 0.5)')!;
      expect(c.toCss(), 'rgba(255, 0, 0, 0.502)');
    });
    test('parse hsl()', () {
      final c = CssColor.parse('hsl(0, 100%, 50%)')!;
      expect(c.toCss(), '#ff0000');
    });
    test('parse named', () {
      expect(CssColor.parse('red')!.toCss(), '#ff0000');
      expect(CssColor.parse('transparent')!.toCss(), 'rgba(0, 0, 0, 0)');
    });
    test('parseArgb (flutter_quill)', () {
      final c = CssColor.parseArgb('#ffff0000')!; // opaque red
      expect(c.toCss(), '#ff0000');
    });
    test('toArgbHex round-trip', () {
      final c = CssColor.parse('rgba(255, 0, 0, 0.5)')!;
      expect(c.toArgbHex(), '#80ff0000');
    });
    test('parse bad input -> null', () {
      expect(CssColor.parse('not-a-color'), isNull);
      expect(CssColor.parse(''), isNull);
    });
  });

  group('QuillSize', () {
    test('named -> CSS', () {
      expect(QuillSize.toCss('small'), '10px');
      expect(QuillSize.toCss('large'), '18px');
      expect(QuillSize.toCss('huge'), '32px');
    });
    test('numeric -> CSS px', () {
      expect(QuillSize.toCss('14'), '14px');
      expect(QuillSize.toCss('14px'), '14px');
    });
    test('em/rem preserved', () {
      expect(QuillSize.toCss('1.5em'), '1.5em');
    });
    test('CSS -> Delta named match', () {
      expect(QuillSize.fromCss('18px'), 'large');
    });
    test('CSS px -> bare numeric', () {
      expect(QuillSize.fromCss('14px'), '14');
    });
    test('em preserved on decode', () {
      expect(QuillSize.fromCss('1.5em'), '1.5em');
    });
  });

  group('StyleMap', () {
    test('parse + canonical serialize', () {
      final s = StyleMap.parse('color:red;background-color: blue; font-size:14px;');
      expect(s['color'], 'red');
      expect(s['background-color'], 'blue');
      expect(s.toCss(), 'background-color: blue; color: red; font-size: 14px');
    });
    test('case-insensitive keys', () {
      final s = StyleMap.parse('COLOR: red');
      expect(s['color'], 'red');
    });
    test('ignores empty entries', () {
      final s = StyleMap.parse('; color: red ; ;');
      expect(s.props.length, 1);
    });

    test('parse(null) -> empty StyleMap', () {
      final s = StyleMap.parse(null);
      expect(s.isEmpty, true);
      expect(s['color'], isNull);
    });

    test("parse('') -> empty StyleMap", () {
      final s = StyleMap.parse('');
      expect(s.isEmpty, true);
    });
  });
}
