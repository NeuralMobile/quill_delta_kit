import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  final c = frag();

  group('iframe handling', () {
    test('YouTube watch URL -> embed iframe', () {
      final html = c.encode(deltaOf([
        {
          'insert': {'video': 'https://www.youtube.com/watch?v=abc123'}
        },
        {'insert': '\n'}
      ]));
      expect(html, contains('https://www.youtube.com/embed/abc123'));
      expect(html, contains('<iframe'));
    });

    test('YouTube short URL -> embed', () {
      final html = c.encode(deltaOf([
        {
          'insert': {'video': 'https://youtu.be/abc123'}
        },
        {'insert': '\n'}
      ]));
      expect(html, contains('youtube.com/embed/abc123'));
    });

    test('Vimeo URL -> player.vimeo.com', () {
      final html = c.encode(deltaOf([
        {
          'insert': {'video': 'https://vimeo.com/12345'}
        },
        {'insert': '\n'}
      ]));
      expect(html, contains('player.vimeo.com/video/12345'));
    });

    test('YouTube iframe decoded -> typed video', () {
      const html = '<iframe src="https://www.youtube.com/embed/xyz"></iframe>';
      final ops = c.decode(html).toJson();
      expect(ops.first['insert']['video'], 'https://www.youtube.com/embed/xyz');
    });

    test('CKEditor oembed -> typed video', () {
      const html =
          '<figure class="media"><oembed url="https://vimeo.com/789"></oembed></figure>';
      final ops = c.decode(html).toJson();
      expect(ops.first['insert']['video'], 'https://vimeo.com/789');
    });

    test('Generic iframe round-trip via custom embed', () {
      final original = deltaOf([
        {
          'insert': {
            'iframe': {
              'src': 'https://example.com/widget',
              'width': '400',
              'height': '300'
            }
          }
        }
      ]);
      final html = c.encode(original);
      expect(html, contains('<iframe'));
      expect(html, contains('src="https://example.com/widget"'));
      final back = c.decode(html);
      expect(back.toJson().first['insert']['iframe']['src'],
          'https://example.com/widget');
    });
  });
}
