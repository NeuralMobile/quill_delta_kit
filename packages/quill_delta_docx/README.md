# quill_delta_docx

Bidirectional Quill `Delta` ↔ `.docx` (Office Open XML) conversion.

* **`.docx` → Delta**: paragraphs, runs (bold/italic/underline/strike/
  color/size), headings, bullet / ordered / checked lists (via
  `numbering.xml`), hyperlinks, embedded images (resolved through
  `word/_rels/document.xml.rels` + `word/media/`)
* **Delta → `.docx`**: writes a valid OOXML package — `[Content_Types]`,
  `_rels/.rels`, `word/document.xml`,
  `word/_rels/document.xml.rels`, `word/styles.xml`, `word/numbering.xml`
* **Sync entry points** — `DocxImporter.importSync` /
  `DocxExporter.exportSync`
* Out of scope for v0.1: tables, comments, track changes, footnotes,
  embedded objects, themes, fontTable, multi-section

## Quickstart

```dart
import 'dart:io';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';

// .docx -> Delta.
final bytes = await File('input.docx').readAsBytes();
final delta = await DocxImporter().import(bytes);

// Delta -> .docx.
final out = await const DocxExporter().export(delta);
await File('output.docx').writeAsBytes(out);
```

## Options

```dart
const opts = DocxOptions(
  pageSize: DocxPageSize.a4,              // .letter, .legal
  imageEmbed: DocxImageEmbed.embedded,    // .dataUri, .externalOrPlaceholder
  defaultFontFamily: 'Calibri',
  defaultFontSizePt: 11,
);
final exporter = DocxExporter(defaultOptions: opts);
```

## How it works

The importer pivots through HTML — every `quill_delta_html` embed adapter
applies automatically (image, video, audio, etc.). The exporter is
native; it walks `splitIntoLines` output directly into OOXML.
