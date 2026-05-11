import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:test/test.dart';

import '_helpers.dart';

void main() {
  group('security', () {
    test('default policy rejects javascript: iframe src', () {
      final c = frag();
      const html = '<iframe src="javascript:alert(1)"></iframe>';
      final ops = c.decode(html).toJson();
      expect(ops.where((o) => o['insert'] is Map).toList(), isEmpty,
          reason: 'iframe with javascript: must not produce embed op');
    });

    test('default policy rejects data: iframe src', () {
      final c = frag();
      const html =
          '<iframe src="data:text/html,<script>alert(1)</script>"></iframe>';
      final ops = c.decode(html).toJson();
      expect(ops.where((o) => o['insert'] is Map).toList(), isEmpty);
    });

    test('strict allowedHosts blocks unknown host', () {
      final c = QuillHtmlCodec(
        options: QuillHtmlOptions(
          wrapDocument: false,
          iframePolicy: IframePolicy(
            allowedSchemes: const {'https'},
            allowedHosts: const {
              'youtube.com',
              'www.youtube.com',
              'vimeo.com',
              'player.vimeo.com'
            },
          ),
        ),
      );
      const html = '<iframe src="https://malicious.example/widget"></iframe>';
      // YouTubeAdapter / VimeoAdapter would still match by URL pattern, but generic
      // IframeAdapter is policy-gated. Malicious URL doesn't match yt/vimeo regex,
      // so falls to IframeAdapter which rejects it.
      final ops = c.decode(html).toJson();
      expect(ops.where((o) => o['insert'] is Map).toList(), isEmpty);
    });

    test('script-tag content is not interpreted as Delta', () {
      final c = frag();
      const html = '<p>before<script>alert(1)</script>after</p>';
      // package:html removes <script> from body context; we should not crash and not
      // run anything dangerous (we never eval). Result: 'before' + 'after'.
      final ops = c.decode(html).toJson();
      final text = ops.map((o) => o['insert']).whereType<String>().join();
      expect(text.contains('alert(1)'), false);
    });

    test('encoded HTML chars survive through escape -> decode', () {
      final c = frag();
      final input = [
        {'insert': '<script>alert(1)</script>\n'}
      ];
      final html = c.encode(deltaOf(input));
      // Encoded as escaped text, not as a real script tag.
      expect(html, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
      final back = c.decode(html).toJson();
      expect(back, [
        {'insert': '<script>alert(1)</script>\n'}
      ]);
    });

    test('img onerror attribute does not survive', () {
      final c = frag();
      const html = '<img src="x" onerror="alert(1)">';
      final ops = c.decode(html).toJson();
      // Image survives; onerror is dropped (not in allowlist).
      expect(ops.first['insert']['image'], 'x');
      final attrs = ops.first['attributes'] as Map?;
      expect(attrs == null || !attrs.containsKey('onerror'), true);
    });
  });
}
