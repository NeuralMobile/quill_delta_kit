import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('complex documents', () {
    test('long mixed doc', () {
      final original = deltaOf([
        {'insert': 'My Article'},
        {'insert': '\n', 'attributes': {'header': 1}},
        {'insert': 'Intro paragraph with '},
        {'insert': 'bold', 'attributes': {'bold': true}},
        {'insert': ', '},
        {'insert': 'italic', 'attributes': {'italic': true}},
        {'insert': ', '},
        {'insert': 'colored', 'attributes': {'color': '#ff0000'}},
        {'insert': ', and a '},
        {'insert': 'link', 'attributes': {'link': 'https://example.com'}},
        {'insert': '.\n'},
        {'insert': 'Subheader'},
        {'insert': '\n', 'attributes': {'header': 2}},
        {'insert': 'one'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'two'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'three nested'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'Quote line'},
        {'insert': '\n', 'attributes': {'blockquote': true}},
        {'insert': 'def f():'},
        {'insert': '\n', 'attributes': {'code-block': 'python'}},
        {'insert': '    return 1'},
        {'insert': '\n', 'attributes': {'code-block': 'python'}},
        {
          'insert': {'image': 'https://x/img.png'},
          'attributes': {'width': '300', 'style': 'margin: auto'}
        },
        {'insert': '\n'},
        {'insert': {'audio': 'https://x/a.mp3'}},
        {'insert': '\n'},
        {'insert': {'divider': true}},
        {'insert': '\n'},
        {'insert': 'After divider.\n'},
        {'insert': 'task1'},
        {'insert': '\n', 'attributes': {'list': 'checked'}},
        {'insert': 'task2'},
        {'insert': '\n', 'attributes': {'list': 'unchecked'}}
      ]);

      final html = c.encode(original);
      final back = c.decode(html);
      expect(normalize(back).toJson(), normalize(original).toJson(),
          reason: 'html=\n$html');
    });

    test('deep nested formatting', () {
      final original = deltaOf([
        {
          'insert': 'x',
          'attributes': {
            'bold': true,
            'italic': true,
            'underline': true,
            'strike': true,
            'color': '#0000ff',
            'background': '#ffff00',
            'font': 'monospace',
            'size': '14',
            'link': 'https://x',
            'script': 'super'
          }
        },
        {'insert': '\n'}
      ]);
      final back = c.decode(c.encode(original));
      expect(normalize(back).toJson(), normalize(original).toJson());
    });

    test('table-like multiline content (no actual table)', () {
      // Quill doesn't support tables natively; ensure plain content survives.
      final original = deltaOf([
        for (var row = 0; row < 5; row++)
          ...[
            {'insert': 'Row $row col 1\t', 'attributes': {'bold': true}},
            {'insert': 'Row $row col 2'},
            {'insert': '\n'}
          ]
      ]);
      final back = c.decode(c.encode(original));
      expect(normalize(back).toJson(), normalize(original).toJson());
    });

    test('huge whitespace doc', () {
      final original = deltaOf([
        {'insert': '  leading spaces\n'},
        {'insert': 'middle\nlines\n'},
        {'insert': 'trailing spaces   \n'},
        {'insert': '\n\n\n'},
        {'insert': 'after blank lines\n'},
      ]);
      final back = c.decode(c.encode(original));
      expect(normalize(back).toJson(), normalize(original).toJson());
    });
  });
}
