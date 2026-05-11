# quill_delta_markdown

Bidirectional Quill `Delta` ↔ Markdown conversion.

* **Markdown → Delta** via `package:markdown` + HTML pivot through
  `quill_delta_html` (every HTML embed adapter applies automatically)
* **Delta → Markdown** via a native walker — fenced code, GFM tables,
  task lists, reference-link images
* **Dialect aware** — CommonMark and GitHub-Flavoured Markdown
* **Sync entry points** — `MarkdownImporter.importSync` /
  `MarkdownExporter.exportSync`

## Quickstart

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';

// Markdown -> Delta.
final delta = await MarkdownImporter().import('# Hello\n\n**world**\n');

// Delta -> Markdown.
final md = await const MarkdownExporter().export(delta);
```

## Options

```dart
const opts = MarkdownOptions(
  flavour: MarkdownFlavour.gfm,           // or .commonmark
  hardLineBreak: false,                   // soft \n -> "  \n" if true
  imageStrategy: MarkdownImageStrategy.referenceList,
  fencedCodeBlockInfoString: true,        // "```dart" annotations
  tableAlignment: true,                   // GFM colon markers
);
final exporter = MarkdownExporter(defaultOptions: opts);
```

## Custom embed adapter (format-native)

```dart
class HashtagAdapter extends MarkdownEmbedAdapter {
  @override
  String get type => 'hashtag';

  @override
  String encode(Object? value, Map<String, dynamic>? attrs) =>
      '#${value?.toString() ?? ''}';
}

final registry = MarkdownEmbedRegistry(adapters: [HashtagAdapter()]);
final exporter = MarkdownExporter(embedRegistry: registry);
```
