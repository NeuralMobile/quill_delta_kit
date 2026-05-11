## 0.1.0 - 2026-05-11

Initial release.

* Quill attribute schema (`Attr`)
* CSS canonicalization (`CssColor`, `QuillSize`)
* Delta line splitter (`Line`, `InlineOp`, `splitIntoLines`)
* Multi-format converter abstractions (`DeltaImporter`, `DeltaExporter`,
  `SyncDeltaImporter`, `SyncDeltaExporter`, `HtmlPivotImporter`,
  `ConverterRegistry`)
* Per-format option bags (`HtmlOptions`, `MarkdownOptions`, `DocxOptions`)
  with `==`, `hashCode`, `copyWith`, and `@immutable`
* Typed exception hierarchy (`DeltaConversionException` + leaves:
  `ImportException`, `ExportException`, `MalformedDocumentException`,
  `UnsupportedFormatException`, `ConverterNotFound`)
* Shared test-contract suite consumed by format packages
