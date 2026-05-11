# quill_delta_pdf

Quill `Delta` → PDF export. PDF → Delta import is **not** implemented in
v0.1 — the importer throws `UnsupportedFormatException` because PDF has
no native document model (it stores glyphs at page coordinates) and any
structural import would be lossy.

Pure Dart writer via `package:pdf`.

## Scope (v0.1)

* Paragraphs with align + indent
* Headings H1-H6
* Blockquotes (italic + left padding)
* Code blocks (monospace, light grey background)
* Bullet + ordered lists (per-indent counters)
* Inline: bold, italic, underline, strike, color, font size, links
* Horizontal dividers
* Page size: A4, Letter, Legal

Out of scope: tables, images, custom embeds, multi-column layout.

## Quickstart

```dart
import 'dart:io';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';

final delta = Delta()
  ..insert('Hello\n', {'header': 1})
  ..insert('World.\n');

final bytes = await const PdfExporter().export(delta);
await File('output.pdf').writeAsBytes(bytes);
```

## Options

```dart
const opts = PdfOptions(
  pageSize: PdfPageSize.letter,   // .a4 (default), .legal
  embedFonts: true,
  compress: true,
);
final exporter = PdfExporter(defaultOptions: opts);
```
