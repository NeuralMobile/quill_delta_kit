import 'package:html/dom.dart' as dom;
import 'package:quill_delta_html/src/util/dom_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('DomSerializer', () {
    test('zero attributes', () {
      final el = dom.Element.tag('p')..append(dom.Text('x'));
      expect(DomSerializer().serialize(el), '<p>x</p>');
    });

    test('one attribute', () {
      final el = dom.Element.tag('p')
        ..attributes['class'] = 'a'
        ..append(dom.Text('x'));
      expect(DomSerializer().serialize(el), '<p class="a">x</p>');
    });

    test('multiple attributes sort alphabetically', () {
      final el = dom.Element.tag('p')
        ..attributes['z'] = '1'
        ..attributes['a'] = '2'
        ..attributes['m'] = '3'
        ..append(dom.Text('x'));
      expect(DomSerializer().serialize(el), '<p a="2" m="3" z="1">x</p>');
    });

    test('void element no closing tag', () {
      final el = dom.Element.tag('div')
        ..append(dom.Element.tag('br'))
        ..append(dom.Element.tag('hr'))
        ..append(dom.Element.tag('img')..attributes['src'] = 'x');
      expect(DomSerializer().serialize(el), '<div><br><hr><img src="x"></div>');
    });

    test('skipRoot emits children only', () {
      final el = dom.Element.tag('div')
        ..append(dom.Element.tag('p')..append(dom.Text('a')))
        ..append(dom.Element.tag('p')..append(dom.Text('b')));
      expect(DomSerializer(skipRoot: true).serialize(el), '<p>a</p><p>b</p>');
    });

    test('attribute values are entity-encoded', () {
      final el = dom.Element.tag('a')..attributes['href'] = 'x?a=1&b="2"';
      expect(DomSerializer().serialize(el),
          '<a href="x?a=1&amp;b=&quot;2&quot;"></a>');
    });
  });
}
