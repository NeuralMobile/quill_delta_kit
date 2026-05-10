import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('embed encoder', () {
    test('image basic', () {
      expect(
        c.encode(deltaOf([
          {'insert': {'image': 'https://x/a.png'}},
          {'insert': '\n'}
        ])),
        '<p><img src="https://x/a.png"></p>',
      );
    });

    test('image with width/height/style', () {
      final html = c.encode(deltaOf([
        {
          'insert': {'image': 'https://x/a.png'},
          'attributes': {'width': '100', 'height': '50', 'style': 'margin: auto'}
        },
        {'insert': '\n'}
      ]));
      expect(html, contains('width="100"'));
      expect(html, contains('height="50"'));
      expect(html, contains('style="margin: auto"'));
    });

    test('video direct file -> <video>', () {
      final html = c.encode(deltaOf([
        {'insert': {'video': 'https://x/v.mp4'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('<video'));
      expect(html, contains('src="https://x/v.mp4"'));
    });

    test('video youtube -> iframe with embed url', () {
      final html = c.encode(deltaOf([
        {'insert': {'video': 'https://www.youtube.com/watch?v=abc123'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('<iframe'));
      expect(html, contains('https://www.youtube.com/embed/abc123'));
    });

    test('audio (built-in)', () {
      final html = c.encode(deltaOf([
        {'insert': {'audio': 'https://x/a.mp3'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('<audio'));
      expect(html, contains('src="https://x/a.mp3"'));
    });

    test('divider <hr>', () {
      final html = c.encode(deltaOf([
        {'insert': {'divider': true}},
        {'insert': '\n'}
      ]));
      expect(html, contains('<hr>'));
    });

    test('formula', () {
      final html = c.encode(deltaOf([
        {'insert': {'formula': 'e=mc^2'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('class="ql-formula"'));
      expect(html, contains('data-formula="e=mc^2"'));
    });

    test('mention', () {
      final html = c.encode(deltaOf([
        {'insert': {'mention': {'id': '1', 'value': 'Alice', 'denotationChar': '@'}}},
        {'insert': '\n'}
      ]));
      expect(html, contains('class="mention"'));
      expect(html, contains('data-mention-id="1"'));
      expect(html, contains('data-mention-value="Alice"'));
      expect(html, contains('@Alice'));
    });

    test('flutter_quill custom audio wrapper', () {
      final html = c.encode(deltaOf([
        {'insert': {'custom': '{"audio":"https://x/a.mp3"}'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('<audio'));
      expect(html, contains('src="https://x/a.mp3"'));
    });

    test('unknown embed -> passthrough', () {
      final html = c.encode(deltaOf([
        {'insert': {'unknownembed': {'foo': 'bar'}}},
        {'insert': '\n'}
      ]));
      expect(html, contains('data-quill-unknown='));
    });

    test('wrapDocument=true wraps embeds in ql-html-doc div', () {
      final wrapped = QuillHtmlCodec();
      final html = wrapped.encode(deltaOf([
        {'insert': {'image': 'https://x/a.png'}},
        {'insert': '\n'}
      ]));
      expect(html, startsWith('<div class="ql-html-doc"'));
      expect(html, contains('<img src="https://x/a.png">'));
      expect(html, endsWith('</div>'));
    });

    test('wrapDocument=true wraps divider', () {
      final wrapped = QuillHtmlCodec();
      final html = wrapped.encode(deltaOf([
        {'insert': {'divider': true}},
        {'insert': '\n'}
      ]));
      expect(html, contains('class="ql-html-doc"'));
      expect(html, contains('<hr>'));
    });
  });
}
