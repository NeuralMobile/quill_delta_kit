## 0.1.0 - 2026-05-11

Initial release.

* Lossless `Delta` ↔ HTML round-trip — 450+ tests, including fuzz seeds
  and whitespace-torture (NBSP, ZWSP, ZWNJ, ZWJ, EN/EM/THIN/IDEOGRAPHIC
  SPACE, tabs, CR, surrogate-pair emoji)
* `QuillHtmlCodec` for legacy users; `HtmlImporter` / `HtmlExporter`
  implement the new sync interfaces
* Embed adapters: image, video, audio, divider, formula, mention, table,
  iframe (sandbox-aware), oembed, passthrough, plus URL sniffs for
  YouTube, Vimeo, Loom, Spotify, SoundCloud, CodePen, Twitter
* HTML5 streaming `HtmlWriter` — no intermediate DOM
* Public surface trimmed to `EmbedAdapter` base, `EmbedRegistry`, and
  configurable adapters (`FormulaAdapter`, `TableAdapter`,
  `PassthroughAdapter`); other built-ins reachable via
  `EmbedRegistry.defaults()`
