## 0.1.1 - 2026-05-11

* Bump `archive` constraint to `^4.0.0` (track latest stable).
* Widen `xml` constraint to `>=6.5.0 <8.0.0` (xml 7 supported; xml 6 still
  resolves transitively through `package:pdf`).

## 0.1.0 - 2026-05-11

Initial release.

* `.docx` → `Delta` import: paragraphs, runs (bold/italic/underline/
  strike/color/size), headings, bullet/ordered/checked lists (via
  `numbering.xml`), hyperlinks, embedded images (via
  `word/_rels/document.xml.rels` + `word/media/`)
* `Delta` → `.docx` export: full OOXML package
  (`[Content_Types].xml`, `_rels/.rels`, `word/document.xml`,
  `word/_rels/document.xml.rels`, `word/styles.xml`,
  `word/numbering.xml`)
* Sync entry points (`importSync` / `exportSync`)
* Out of scope for v0.1: tables, comments, track changes, footnotes,
  embedded objects, themes
