import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('provider adapters', () {
    test('Loom share -> embed canonicalize', () {
      final html = c.encode(deltaOf([
        {'insert': {'loom': 'https://www.loom.com/share/abc123'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('https://www.loom.com/embed/abc123'));
    });

    test('Loom decode iframe -> typed', () {
      const html = '<iframe src="https://www.loom.com/embed/xyz"></iframe>';
      expect(c.decode(html).toJson().first['insert'], {'loom': 'https://www.loom.com/embed/xyz'});
    });

    test('Spotify watch -> embed', () {
      final html = c.encode(deltaOf([
        {'insert': {'spotify': 'https://open.spotify.com/track/abc'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('open.spotify.com/embed/track/abc'));
    });

    test('Spotify decode', () {
      const html = '<iframe src="https://open.spotify.com/embed/track/abc"></iframe>';
      expect(c.decode(html).toJson().first['insert']['spotify'], isNotEmpty);
    });

    test('SoundCloud round-trip', () {
      final orig = deltaOf([
        {'insert': {'soundcloud': 'https://w.soundcloud.com/player/?url=...'}},
        {'insert': '\n'}
      ]);
      final back = c.decode(c.encode(orig));
      expect(back.toJson().first['insert']['soundcloud'], 'https://w.soundcloud.com/player/?url=...');
    });

    test('CodePen pen -> embed', () {
      final html = c.encode(deltaOf([
        {'insert': {'codepen': 'https://codepen.io/user/pen/abc'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('codepen.io/user/embed/abc'));
    });

    test('Tweet via blockquote', () {
      final html = c.encode(deltaOf([
        {'insert': {'tweet': 'https://twitter.com/u/status/1'}},
        {'insert': '\n'}
      ]));
      expect(html, contains('class="twitter-tweet"'));
      expect(html, contains('data-tweet-url="https://twitter.com/u/status/1"'));
    });

    test('Tweet decode', () {
      const html = '<blockquote class="twitter-tweet" data-tweet-url="https://x.com/u/status/2">'
          '<a href="https://x.com/u/status/2">x</a></blockquote>';
      expect(
        c.decode(html).toJson().first['insert']['tweet'],
        'https://x.com/u/status/2',
      );
    });
  });
}
