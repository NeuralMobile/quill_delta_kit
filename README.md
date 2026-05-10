# quill_delta_html

Lossless, bidirectional [Quill](https://quilljs.com) Delta <-> HTML conversion. Pure Dart.

## Features

- **Bidirectional**: `Delta -> HTML` and `HTML -> Delta` from one schema. No drift.
- **Lossless**: whitespace, NBSP, ZWSP, multiple newlines, attribute order — all survive round-trip.
- **Cross-editor**: emits standards-first HTML (semantic tags + inline styles, no `ql-*` classes). Decodes output from CKEditor, TipTap, ProseMirror, Quill JS, Lexical.
- **flutter_quill 11.x**: matches latest Delta attribute set + `insert.custom` JSON wrapper.
- **Adapter API**: register custom embed codecs (audio, mention, iframe, oembed, ...).
- **Iframe smart-routing**: provider sniff (YouTube/Vimeo/Loom/...) -> typed `video` Delta op. Unknown iframes -> custom passthrough. Security policy strips XSS.

## Usage

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';

final codec = QuillHtmlCodec(
  adapters: [
    AudioAdapter(),
    IframeAdapter(),
    MentionAdapter(),
  ],
);

final html = codec.encode(delta);
final delta = codec.decode(html);
```

## Coverage matrix

See [docs/coverage.md](docs/coverage.md).
