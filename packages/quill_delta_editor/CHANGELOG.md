## 0.1.0 - 2026-05-11

Initial release.

* `QuillDeltaEditor` — Flutter wrapper around `flutter_quill` 11.5 with
  the converter family bundled in
* **Drop-in flutter_quill parity.** Sealed ergonomic presets
  (`EditorLayoutConfig`, `ToolbarConfig`) layered on top of pass-through
  `editorConfig` / `editorConfigBuilder` and `toolbarConfig` /
  `toolbarConfigBuilder` that reach every raw flutter_quill knob
  (customStyles, contextMenuBuilder, magnifierConfiguration, embedButtons,
  iconTheme, dialogTheme, custom link/header dialogs, …)
* `QuillSimpleToolbarConfigCopyWithX.copyWith` extension — fills a gap in
  flutter_quill 11.5
* Layout presets: scrollable, auto-grow, fixed-height, expanded
* Toolbar placement: top, bottom, floating, selection-anchored
  (cross-platform iOS-style — works on web), no-toolbar, custom
* Selection toolbar overlay uses `RenderEditor.getEndpointsForSelection`
  directly so it shows on the web (flutter_quill's built-in
  `showToolbar` is `kIsWeb`-gated)
* Document import toolbar button (`buildImportDocumentButton`) — sealed
  `ImportSource` family (`ImportSource.bytes(...)` /
  `ImportSource.text(...)`)
* `QuillDocumentImporter` for replace + insert-at-cursor workflows
* `MediaEmbedBuilder` for image/video/audio with byte-cache eliminating
  base64 decode flicker on rebuild
* Sealed `EditorLayoutConfig` and `ToolbarConfig` for exhaustive
  pattern-matching in custom code paths
