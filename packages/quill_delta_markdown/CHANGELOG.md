## 0.1.1 - 2026-05-14

Two correctness fixes around plain-prose round-trips:

* `MarkdownImporter`: GFM blank-line paragraph separators (`\n\n`) no
  longer produce empty Quill paragraph ops. Previously `**Bold**\n\nP`
  imported with a leading `\n\n` on the second op (one extra blank line),
  and `## H\n\nP` produced a bare `{insert:'\n'}` op between the heading
  and the paragraph. Both now collapse to the minimum ops needed to
  represent the visible content; vertical spacing is the host editor's
  job via `DefaultStyles` / CSS.
* `MarkdownExporter`: no longer backslash-escapes hyphens (`-`),
  parentheses (`(` `)`), or curly braces (`{` `}`) in inline text. These
  characters are only structural at line-start (list markers) or inside
  `[text](url)` link targets — block writers handle line-start markers
  explicitly, and the matching `]` escape already disambiguates link
  targets, so escaping them in plain prose corrupted text across
  successive saves (`plan-o-gram` → `plan\-o\-gram` → `plan\\-o\\-gram`
  ...). `\`, `` ` ``, `*`, `_`, `[`, `]`, `#`, `+`, `!`, `|`, `<`, `>`
  are still escaped.

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
