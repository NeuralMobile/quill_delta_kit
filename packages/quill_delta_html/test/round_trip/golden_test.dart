import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  /// Encode->decode->compare. Some normalizations are expected:
  /// - color values -> canonical CSS form
  /// - size: 'large' -> 'large' (named round-trips)
  /// - flutter_quill ARGB hex -> canonical rgba (lossy if alpha < 255 in alternate form)
  void rt(List<Map<String, dynamic>> input,
      [List<Map<String, dynamic>>? expectedAfter]) {
    final original = deltaOf(input);
    final html = c.encode(original);
    final out = c.decode(html);
    final expectedDelta =
        expectedAfter != null ? deltaOf(expectedAfter) : original;
    expect(normalize(out).toJson(), normalize(expectedDelta).toJson(),
        reason:
            'round-trip mismatch for $input\n   html: $html\n   out: ${out.toJson()}');
  }

  group('round-trip', () {
    test(
        'plain',
        () => rt([
              {'insert': 'hello\n'}
            ]));
    test(
        'bold',
        () => rt([
              {
                'insert': 'a',
                'attributes': {'bold': true}
              },
              {'insert': '\n'}
            ]));
    test(
        'multi-attr',
        () => rt([
              {
                'insert': 'x',
                'attributes': {'bold': true, 'italic': true, 'underline': true}
              },
              {'insert': '\n'}
            ]));
    test(
        'color',
        () => rt([
              {
                'insert': 'x',
                'attributes': {'color': '#ff0000'}
              },
              {'insert': '\n'}
            ]));
    test(
        'background',
        () => rt([
              {
                'insert': 'x',
                'attributes': {'background': '#00ff00'}
              },
              {'insert': '\n'}
            ]));
    test(
        'link',
        () => rt([
              {
                'insert': 'a',
                'attributes': {'link': 'https://example.com'}
              },
              {'insert': '\n'}
            ]));
    test(
        'h1',
        () => rt([
              {'insert': 'x'},
              {
                'insert': '\n',
                'attributes': {'header': 1}
              }
            ]));
    test(
        'list ordered',
        () => rt([
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {'list': 'ordered'}
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {'list': 'ordered'}
              }
            ]));
    test(
        'blockquote',
        () => rt([
              {'insert': 'q'},
              {
                'insert': '\n',
                'attributes': {'blockquote': true}
              }
            ]));
    test(
        'code-block',
        () => rt([
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {'code-block': true}
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {'code-block': true}
              }
            ]));
    test(
        'image',
        () => rt([
              {
                'insert': {'image': 'https://x/a.png'}
              },
              {'insert': '\n'}
            ]));
    test(
        'audio',
        () => rt([
              {
                'insert': {'audio': 'https://x/a.mp3'}
              },
              {'insert': '\n'}
            ]));
    test(
        'divider',
        () => rt([
              {
                'insert': {'divider': true}
              },
              {'insert': '\n'}
            ]));
    test(
        'formula',
        () => rt([
              {
                'insert': {'formula': 'a^2'}
              },
              {'insert': '\n'}
            ]));
    test(
        'mention',
        () => rt([
              {
                'insert': {
                  'mention': {'denotationChar': '@', 'id': '1', 'value': 'X'}
                }
              },
              {'insert': '\n'}
            ]));
    test(
        'script super',
        () => rt([
              {
                'insert': 'x',
                'attributes': {'script': 'super'}
              },
              {'insert': '\n'}
            ]));
    test(
        'mixed inline + block + embed',
        () => rt([
              {'insert': 'before '},
              {
                'insert': 'bold',
                'attributes': {'bold': true}
              },
              {'insert': ' middle\n'},
              {'insert': 'h1'},
              {
                'insert': '\n',
                'attributes': {'header': 1}
              },
              {
                'insert': {'image': 'https://x.png'}
              },
              {'insert': '\n'},
            ]));
    test(
        'align right',
        () => rt([
              {'insert': 'x'},
              {
                'insert': '\n',
                'attributes': {'align': 'right'}
              }
            ]));
    test(
        'rtl direction',
        () => rt([
              {'insert': 'x'},
              {
                'insert': '\n',
                'attributes': {'direction': 'rtl'}
              }
            ]));
    test(
        'indent 2',
        () => rt([
              {'insert': 'x'},
              {
                'insert': '\n',
                'attributes': {'indent': 2}
              }
            ]));
  });
}
