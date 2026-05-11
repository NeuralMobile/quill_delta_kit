## 0.1.0 - 2026-05-11

Initial release.

* `Delta` → PDF export (pure Dart via `package:pdf`)
  * Paragraphs with align + indent
  * Headings H1-H6
  * Blockquotes (italic + left padding)
  * Code blocks (monospace, light grey background)
  * Bullet + ordered lists (per-indent counters)
  * Inline: bold, italic, underline, strike, color, size, links
  * Horizontal dividers
* PDF → `Delta` import: stub — throws `UnsupportedFormatException`. PDF
  has no native document model so structural import is fundamentally
  lossy; planned for a later release.
* Page size: A4 / Letter / Legal
* Out of scope for v0.1: tables, images, custom embeds, multi-column
  layout
