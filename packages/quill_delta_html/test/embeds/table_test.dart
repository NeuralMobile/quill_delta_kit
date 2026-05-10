import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('table adapter', () {
    test('basic table round-trip', () {
      const html = '<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>';
      final delta = c.decode(html);
      final ops = delta.toJson();
      expect(ops.first['insert'], isA<Map<String, dynamic>>());
      expect((ops.first['insert'] as Map)['table'], contains('<table>'));
      expect((ops.first['insert'] as Map)['table'], contains('<td>a</td>'));
      // Round-trip back.
      final reHtml = c.encode(delta);
      expect(reHtml, contains('<table>'));
      expect(reHtml, contains('<td>a</td>'));
      expect(reHtml, contains('<td>d</td>'));
    });

    test('table with header row + colspan/rowspan', () {
      const html = '<table>'
          '<thead><tr><th>H1</th><th colspan="2">H2</th></tr></thead>'
          '<tbody><tr><td>a</td><td rowspan="2">b</td><td>c</td></tr>'
          '<tr><td>d</td><td>e</td></tr></tbody>'
          '</table>';
      final delta = c.decode(html);
      final reHtml = c.encode(delta);
      expect(reHtml, contains('<th'));
      expect(reHtml, contains('colspan="2"'));
      expect(reHtml, contains('rowspan="2"'));
    });

    test('table with formatted cells', () {
      const html = '<table><tr><td><strong>bold</strong> <em>i</em></td></tr></table>';
      final delta = c.decode(html);
      final reHtml = c.encode(delta);
      expect(reHtml, contains('<strong>bold</strong>'));
      expect(reHtml, contains('<em>i</em>'));
    });

    test('table strips event handlers', () {
      const html = '<table><tr><td onclick="alert(1)">x</td></tr></table>';
      final delta = c.decode(html);
      final ops = delta.toJson();
      expect((ops.first['insert'] as Map)['table'], isNot(contains('onclick')));
    });

    test('table as block-level (no <p> wrapper)', () {
      // Encode a delta with a table embed -> HTML must NOT wrap table in <p>.
      final orig = deltaOf([
        {'insert': {'table': '<table><tr><td>x</td></tr></table>'}},
        {'insert': '\n'}
      ]);
      final html = c.encode(orig);
      expect(html, isNot(contains('<p><table')));
      expect(html, contains('<table'));
    });
  });
}
