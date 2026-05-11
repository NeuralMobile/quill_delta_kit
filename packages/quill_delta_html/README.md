# quill_delta_html

Lossless bidirectional Quill `Delta` ↔ HTML conversion.

* **Round-trip lossless**: `decode(encode(delta)) == delta` for every
  Delta the encoder produces. 450+ tests including fuzz seeds and
  whitespace-torture cases (NBSP, ZWSP, ZWNJ, ZWJ, EN/EM/THIN/IDEOGRAPHIC
  SPACE, tab, CR, surrogate-pair emoji).
* **Streaming**: encoder writes through `HtmlWriter` straight into a
  StringBuffer — no intermediate DOM tree.
* **Embed adapters**: image, video, audio, divider, formula, mention,
  table, iframe (sandbox-aware), oembed, passthrough. URL sniffs for
  YouTube, Vimeo, Loom, Spotify, SoundCloud, CodePen, Twitter.
* **Sync entry points**: `HtmlImporter.importSync` / `HtmlExporter.exportSync`.

## Quickstart

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';

final codec = QuillHtmlCodec();

// Delta -> HTML.
final delta = Delta()..insert('Hello, world.\n');
final html = codec.encode(delta);

// HTML -> Delta.
final back = codec.decode(html);
```

## With explicit options

```dart
final codec = QuillHtmlCodec(
  options: const HtmlOptions(
    wrapDocument: false,
    preserveWhitespace: true,
    canonicalColorFormat: ColorFormat.hex6,
  ),
);
```

## Custom embed adapter

```dart
class GistAdapter extends EmbedAdapter {
  @override String get type => 'gist';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value?.toString() ?? '';
    writer.open('script', {'src': '$url.js'});
    writer.close('script');
  }

  @override
  bool matches(dom.Element el) =>
      el.localName == 'script' &&
      (el.attributes['src'] ?? '').endsWith('.js') &&
      (el.attributes['src'] ?? '').contains('gist.github.com');

  @override
  Map<String, dynamic>? decode(dom.Element el, QuillHtmlOptions options) {
    final src = el.attributes['src'];
    return src == null
        ? null
        : {'insert': {'gist': src.replaceAll('.js', '')}};
  }
}

final codec = QuillHtmlCodec(
  registry: EmbedRegistry(user: [GistAdapter()]),
);
```

## Iframe sanitization

```dart
QuillHtmlCodec(
  options: QuillHtmlOptions(
    iframePolicy: IframePolicy(
      allowedSchemes: const {'https'},
      allowedHosts: const {'www.youtube.com', 'player.vimeo.com'},
      requireSandbox: true,
    ),
  ),
);
```
