# quill_delta_core

Core types and Delta utilities for the `quill_delta_*` converter family.
Pure Dart. Zero HTML / binary dependencies.

## What's inside

| Type | Purpose |
|---|---|
| `Attr` | Quill attribute schema constants |
| `CssColor`, `QuillSize` | CSS canonicalisation helpers |
| `splitIntoLines`, `Line`, `InlineOp` | Delta → line-by-line walker |
| `DeltaImporter`, `DeltaExporter` | Multi-format converter abstractions |
| `SyncDeltaImporter`, `SyncDeltaExporter` | Sync-capable variants |
| `HtmlPivotImporter` | Base for non-HTML importers that pivot through HTML |
| `ConverterRegistry` | Format / MIME / extension routing |
| `HtmlOptions`, `MarkdownOptions`, `DocxOptions` | Per-format options |
| `DeltaConversionException` family | Typed error hierarchy |

You usually pull this in transitively via one of the format packages
(`quill_delta_html`, `quill_delta_markdown`, `quill_delta_docx`,
`quill_delta_pdf`). Use this package directly if you're writing your own
converter.

## Minimal converter

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

final class CsvExporter
    implements DeltaExporter<String, ConverterOptions>,
               SyncDeltaExporter<String, ConverterOptions> {
  const CsvExporter();
  @override String get format => 'csv';
  @override String get mimeType => 'text/csv';
  @override String get extension => 'csv';
  @override ConverterOptions get defaultOptions =>
      const _DefaultCsvOptions();
  @override Future<String> export(Delta delta, {ConverterOptions? options}) async =>
      exportSync(delta, options: options);
  @override String exportSync(Delta delta, {ConverterOptions? options}) {
    final buf = StringBuffer();
    for (final line in splitIntoLines(delta)) {
      buf.writeln(line.ops.map((o) => o.isText ? o.asText : '').join(','));
    }
    return buf.toString();
  }
}

class _DefaultCsvOptions extends ConverterOptions {
  const _DefaultCsvOptions();
}
```

## Errors

Every error raised by an importer / exporter is a subtype of
`DeltaConversionException`. Catch the supertype, dispatch on the leaf:

```dart
try {
  await registry.importAuto(bytes, filename: 'doc.pdf');
} on UnsupportedFormatException catch (e) {
  // PDF import not yet implemented.
} on MalformedDocumentException catch (e) {
  // .docx archive corrupt; .html unparseable; etc.
} on DeltaConversionException catch (e) {
  // Other conversion failures.
}
```
