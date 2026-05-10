# quill_delta_*

Multi-format converter family for [Quill](https://quilljs.com) Delta + a
Flutter editor wrapper around [`flutter_quill`](https://pub.dev/packages/flutter_quill).

## Packages

| Package | What it does |
|---|---|
| [`quill_delta_core`](packages/quill_delta_core/) | Shared abstractions: `DeltaImporter` / `DeltaExporter`, `ConverterRegistry`, `HtmlPivotImporter`, `EmbedAdapterBase`, CSS/whitespace helpers, line-splitter. Zero HTML/binary deps. |
| [`quill_delta_html`](packages/quill_delta_html/) | Lossless bidirectional Delta ↔ HTML. Adapter API for embeds. Cross-editor (CKEditor / TipTap / ProseMirror / Quill JS / Lexical) interop. |
| [`quill_delta_markdown`](packages/quill_delta_markdown/) | Delta ↔ Markdown. Importer pivots via HTML; exporter walks Delta lines natively. |
| [`quill_delta_docx`](packages/quill_delta_docx/) | Delta ↔ DOCX (OOXML). Image extraction, numbering.xml resolution, hyperlinks, tables, styles. |
| [`quill_delta_pdf`](packages/quill_delta_pdf/) | Delta → PDF via `package:pdf`. Importer stubbed (no robust pure-Dart PDF reader exists). |
| [`quill_delta_editor`](packages/quill_delta_editor/) | Flutter wrapper around `flutter_quill` with configurable toolbar (top/bottom/floating/selection/custom), layout modes (scrollable/autoGrow/fixed/expanded/readOnly), pluggable media preview builders, and a `QuillDocumentImporter` toolbar tool. |

## Quick start (HTML codec)

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';

final codec = QuillHtmlCodec();
final html = codec.encode(delta);
final back = codec.decode(html);
```

## Quick start (Flutter editor)

```dart
import 'package:quill_delta_editor/quill_delta_editor.dart';

QuillDeltaEditor(
  controller: controller,
  layout: const EditorLayoutConfig.autoGrow(maxHeight: 400),
  toolbar: const ToolbarConfig.top(style: ToolbarStyle.compact),
)
```

## Examples

Run the demo app showcasing every layout / toolbar / format / import path:

```sh
cd packages/quill_delta_editor/example
flutter run
```

10 demos: scrollable form, auto-grow, fixed-height list, read-only viewer,
media embeds, auth-injected previews, custom toolbar, corner floating toolbar,
selection toolbar (iOS-style), multi-format export, document import.

## Layout

```
.
├── packages/
│   ├── quill_delta_core/        # converter abstractions
│   ├── quill_delta_html/        # HTML codec + bench
│   ├── quill_delta_markdown/    # Markdown codec
│   ├── quill_delta_docx/        # DOCX codec
│   ├── quill_delta_pdf/         # PDF exporter
│   ├── quill_delta_editor/      # Flutter wrapper + example app
│   └── _e2e_tests/              # cross-package integration tests
├── docs/                        # design docs
├── tool/                        # publish helpers
├── pubspec.yaml                 # Dart 3.6 workspace root
└── README.md
```

Dart 3.6 native workspace. `dart pub get` at the repo root resolves all packages.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, test layout,
and the per-package publish flow.
