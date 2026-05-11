# quill_delta_editor

Flutter wrapper around `flutter_quill` bundled with the `quill_delta_*`
multi-format converter family.

* **True drop-in replacement** for `flutter_quill`'s `QuillEditor` —
  sealed ergonomic presets (`EditorLayoutConfig`, `ToolbarConfig`) plus
  raw `editorConfig` / `toolbarConfig` pass-through that reaches every
  flutter_quill knob (`customStyles`, `contextMenuBuilder`,
  `magnifierConfiguration`, `iconTheme`, `dialogTheme`, custom link /
  header dialog styles, embed buttons, …)
* **Bundled converters** — HTML / Markdown / DOCX import + export from a
  single dependency
* **Cross-platform selection toolbar** — works on web, where
  flutter_quill's built-in toolbar is `kIsWeb`-gated
* **Document import toolbar button** — sealed `ImportSource` family
  (`ImportSource.bytes(...)` / `ImportSource.text(...)`)
* **Image cache** for data-URI embeds — eliminates flicker on focus /
  scroll

## Quickstart

```dart
import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final _controller = QuillController.basic();

  @override
  Widget build(BuildContext context) => QuillDeltaEditor(controller: _controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Layout presets

```dart
QuillDeltaEditor(
  controller: ctrl,
  layout: const EditorLayoutConfig.autoGrow(minHeight: 80, maxHeight: 400),
);
// .scrollable(...), .fixed(height: ...), .expanded(...)
```

## Toolbar presets

```dart
QuillDeltaEditor(
  controller: ctrl,
  toolbar: const ToolbarConfig.top(style: ToolbarStyle.compact),
);
// .bottom(...), .floating(position: ...), .selection(...), .none(),
// .custom(builder: ...)
```

## Drop-in flutter_quill parity

When the preset doesn't expose the knob you need, drop down to raw
flutter_quill config:

```dart
QuillDeltaEditor(
  controller: ctrl,
  layout: const ScrollableLayout(),
  // Layered override: keep preset defaults, swap individual fields.
  editorConfigBuilder: (preset) => preset.copyWith(
    customStyles: myStyles,
    contextMenuBuilder: myMenu,
    customLinkPrefixes: const ['app://'],
    magnifierConfiguration: TextMagnifierConfiguration.disabled,
  ),
  toolbarConfigBuilder: (preset) => preset.copyWith(
    showSubscript: true,
    showDirection: true,
    iconTheme: myIconTheme,
  ),
);
```

Full override (replaces preset wholly):

```dart
QuillDeltaEditor(
  controller: ctrl,
  editorConfig: const QuillEditorConfig(
    padding: EdgeInsets.all(16),
    scrollable: true,
    customStyles: ...,
  ),
  toolbarConfig: const QuillSimpleToolbarConfig(
    showBoldButton: true,
    showSubscript: true,
  ),
);
```

## Document import button

```dart
QuillDeltaEditor(
  controller: ctrl,
  toolbar: ToolbarConfig.top(
    customButtons: [
      buildImportDocumentButton(
        controller: ctrl,
        pickSource: (context) async {
          // Show file picker, return ImportSource.bytes/text.
          return ImportSource.bytes(bytes: pickedBytes, filename: 'doc.docx');
        },
      ),
    ],
  ),
);
```

## Custom media preview

```dart
QuillDeltaEditor(
  controller: ctrl,
  previewBuilders: MediaPreviewBuilders(
    imageBuilder: (ctx, url, meta) => Image.network(
      url,
      headers: {'Authorization': 'Bearer $token'},
    ),
  ),
);
```
