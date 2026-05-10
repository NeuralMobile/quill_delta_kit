import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('inline decoder', () {
    test('plain', () {
      expect(c.decode('<p>hello</p>').toJson(), [
        {'insert': 'hello\n'}
      ]);
    });

    test('bold via <strong>', () {
      expect(c.decode('<p><strong>x</strong></p>').toJson(), [
        {'insert': 'x', 'attributes': {'bold': true}},
        {'insert': '\n'}
      ]);
    });

    test('bold via <b>', () {
      expect(c.decode('<p><b>x</b></p>').toJson(), [
        {'insert': 'x', 'attributes': {'bold': true}},
        {'insert': '\n'}
      ]);
    });

    test('italic via <em> + <i>', () {
      for (final t in ['em', 'i']) {
        expect(c.decode('<p><$t>x</$t></p>').toJson(), [
          {'insert': 'x', 'attributes': {'italic': true}},
          {'insert': '\n'}
        ]);
      }
    });

    test('underline via <u> + <ins>', () {
      for (final t in ['u', 'ins']) {
        expect(c.decode('<p><$t>x</$t></p>').toJson(), [
          {'insert': 'x', 'attributes': {'underline': true}},
          {'insert': '\n'}
        ]);
      }
    });

    test('strike via <s>, <del>, <strike>', () {
      for (final t in ['s', 'del', 'strike']) {
        expect(c.decode('<p><$t>x</$t></p>').toJson(), [
          {'insert': 'x', 'attributes': {'strike': true}},
          {'insert': '\n'}
        ]);
      }
    });

    test('script via <sup>/<sub>', () {
      expect(c.decode('<p><sup>x</sup></p>').toJson(), [
        {'insert': 'x', 'attributes': {'script': 'super'}},
        {'insert': '\n'}
      ]);
      expect(c.decode('<p><sub>x</sub></p>').toJson(), [
        {'insert': 'x', 'attributes': {'script': 'sub'}},
        {'insert': '\n'}
      ]);
    });

    test('link', () {
      expect(c.decode('<p><a href="https://x">x</a></p>').toJson(), [
        {'insert': 'x', 'attributes': {'link': 'https://x'}},
        {'insert': '\n'}
      ]);
    });

    test('inline color via style', () {
      final ops = c.decode('<p><span style="color: rgb(255,0,0)">x</span></p>').toJson();
      expect(ops, [
        {'insert': 'x', 'attributes': {'color': '#ff0000'}},
        {'insert': '\n'}
      ]);
    });

    test('inline background', () {
      expect(c.decode('<p><span style="background-color:#0f0">x</span></p>').toJson(), [
        {'insert': 'x', 'attributes': {'background': '#00ff00'}},
        {'insert': '\n'}
      ]);
    });

    test('font + size from style', () {
      expect(
        c.decode('<p><span style="font-family: Arial; font-size: 18px">x</span></p>').toJson(),
        [
          {'insert': 'x', 'attributes': {'font': 'Arial', 'size': 'large'}},
          {'insert': '\n'}
        ],
      );
    });

    test('legacy <font face size color>', () {
      final ops = c.decode('<p><font face="serif" size="14" color="red">x</font></p>').toJson();
      expect(ops, [
        {'insert': 'x', 'attributes': {'color': '#ff0000', 'font': 'serif', 'size': '14'}},
        {'insert': '\n'}
      ]);
    });

    test('font-weight: bold via style', () {
      expect(c.decode('<p><span style="font-weight: bold">x</span></p>').toJson(), [
        {'insert': 'x', 'attributes': {'bold': true}},
        {'insert': '\n'}
      ]);
    });

    test('font-weight 700 numeric', () {
      expect(c.decode('<p><span style="font-weight: 700">x</span></p>').toJson(), [
        {'insert': 'x', 'attributes': {'bold': true}},
        {'insert': '\n'}
      ]);
    });

    test('text-decoration underline', () {
      expect(c.decode('<p><span style="text-decoration: underline">x</span></p>').toJson(), [
        {'insert': 'x', 'attributes': {'underline': true}},
        {'insert': '\n'}
      ]);
    });

    test('text-decoration line-through', () {
      expect(c.decode('<p><span style="text-decoration: line-through">x</span></p>').toJson(), [
        {'insert': 'x', 'attributes': {'strike': true}},
        {'insert': '\n'}
      ]);
    });

    test('CKEditor highlight via <mark>', () {
      final ops = c.decode('<p><mark>x</mark></p>').toJson();
      expect(ops, [
        {'insert': 'x', 'attributes': {'background': '#ffff00'}},
        {'insert': '\n'}
      ]);
    });
  });
}
