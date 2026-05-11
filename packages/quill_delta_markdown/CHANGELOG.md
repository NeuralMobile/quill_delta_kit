## 0.1.0 - 2026-05-11

Initial release.

* `Delta` → Markdown via a native walker (no HTML pivot on the export
  side; format-specific decisions for fenced code, GFM tables, task lists)
* Markdown → `Delta` via `package:markdown` and the HTML pivot
* CommonMark and GitHub-Flavoured Markdown dialects
* Reference-list / inline / drop-data-uri image strategies
* Sync entry points (`importSync` / `exportSync`) — implements
  `SyncDeltaImporter` / `SyncDeltaExporter`
* `MarkdownEmbedAdapter` interface for format-native embed customisation
