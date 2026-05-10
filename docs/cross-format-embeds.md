# Cross-format embed adapters

## Problem

The HTML codec ships with rich embed adapters (`ImageAdapter`, `MentionAdapter`, `FormulaAdapter`, etc.) operating on `package:html` `dom.Element` for decode and `HtmlWriter` for encode. Non-HTML format packages currently use the **HTML pivot** — they convert their native format to HTML then run the HTML decoder, picking up every embed adapter for free. Symmetric on encode.

This works for 90% of cases but loses fidelity in two directions:

- **Render quality.** A `mention` in DOCX should ideally emit `<w:r>` with a custom `w:val` so Word renders it as a recognizable mention chip, not a plain `<span class="mention">` → text. Going through HTML loses the OOXML semantics.
- **Custom syntax.** A wiki-link `[[Page]]` in Markdown is more idiomatic than `<a href="/wiki/Page">Page</a>`. HTML pivot can't produce it.

## Decision

Per-format adapter hierarchies. There is no single useful Dart type that captures "an HTML DOM element OR a markdown AST node OR an OOXML element OR a PDF text run". Each format keeps its own adapter contract; the **metadata** (`type`, `customSubType`, options generic) lives in core via `EmbedAdapterBase<TOpts>`.

Concretely:

- `quill_delta_core` → `EmbedAdapterBase<TOpts>` (metadata only).
- `quill_delta_html` → `EmbedAdapter` (operates on `dom.Element` + `HtmlWriter`).
- `quill_delta_markdown` → `MarkdownEmbedAdapter` (operates on `StringBuffer` + `RegExp`).
- `quill_delta_docx` → `DocxEmbedAdapter` (operates on `StringBuffer` of OOXML + `XmlElement`). *Not implemented yet — same pattern.*
- `quill_delta_pdf` → would operate on `pw.Widget`/`pw.InlineSpan` builder. *Not implemented.*

Each format ships its own `*EmbedRegistry`. Adapters are passed into the format's exporter / importer via constructor, so consumers register only what they need:

```dart
final reg = MarkdownEmbedRegistry(adapters: [
  MyMentionMarkdownAdapter(),
  MyFormulaMarkdownAdapter(),
]);
final exporter = MarkdownExporter(embedRegistry: reg);
```

If the format-native registry returns null for a given embed type, the exporter falls back to its built-in handler (image, divider) and finally to `<!-- type -->` HTML passthrough when `allowHtmlPassthrough` is true.

## Why not a generic `EmbedAdapter<TWriteCtx, TReadCtx>`?

Two reasons:

1. **Decode shapes diverge.** HTML decoding is tree-walking on `dom.Element` with a CSS-selector-style match. Markdown decoding is line/regex driven (markdown isn't a tree until parsed). Docx decoding walks `XmlElement`. PDF "decoding" doesn't exist (importer is a stub) but would need OCR/text-extraction context. A `<TReadCtx>` parameter forces every adapter author to think about a unified API that is inherently format-coupled.
2. **Encode write surfaces diverge.** HTML and OOXML and Markdown are all "stream tag/text into a StringBuffer", but the *vocabulary* (tags, escapes, attribute syntax) is mutually incompatible. PDF encode writes `pw.Widget` trees, not strings. A generic write context doesn't shorten any adapter.

The shared concerns — `type` key, `customSubType`, option-bag generic — fit cleanly in a 5-line `EmbedAdapterBase<TOpts>` superclass. Anything more shared is artificial.

## Worked example: Markdown mention adapter

A simple mention adapter that emits `@username` in markdown and parses `@username` back into a `mention` Delta embed:

```dart
class MentionMarkdownAdapter extends MarkdownEmbedAdapter {
  @override String get type => 'mention';
  @override RegExp get pattern => RegExp(r'@(\w+)');

  @override
  void encodeMarkdown({required StringBuffer buf, required Object? value,
                       Map<String, dynamic>? siblingAttrs,
                       required MarkdownOptions options}) {
    final v = value is Map ? value : const <String, dynamic>{};
    final char = v['denotationChar']?.toString() ?? '@';
    buf.write('$char${v['value']}');
  }

  @override
  Map<String, dynamic>? decodeMarkdown(String matched, MarkdownOptions opts) {
    return {
      'insert': {
        'mention': {'value': matched, 'denotationChar': '@'},
      }
    };
  }
}
```

Wire it into the exporter:

```dart
final reg = MarkdownEmbedRegistry(adapters: [MentionMarkdownAdapter()]);
final exp = MarkdownExporter(embedRegistry: reg);
final md = await exp.export(Delta()
  ..insert({'mention': {'value': 'alice', 'denotationChar': '@'}})
  ..insert('\n'));
// md == '@alice\n'
```

The same registry can be wired into a future `MarkdownImporter.embedRegistry` so the importer scans each line via `firstMatchIn(...)` before falling back to default markdown parsing.

## What this PR does

- Adds `EmbedAdapterBase<TOpts>` to core.
- Adds `MarkdownEmbedAdapter` + `MarkdownEmbedRegistry` to the markdown package.
- Wires the registry into `MarkdownExporter._writeEmbed` so format-native adapters preempt the built-in handling.
- Test proves the round trip with a mention adapter.

## What this PR explicitly does not do

- DocxEmbedAdapter / PdfEmbedAdapter implementations. The pattern is identical; ship when a real consumer needs it.
- Markdown importer adapter integration. The hooks are present (`MarkdownEmbedRegistry.firstMatchIn` is ready to call from a custom inline pass) but `MarkdownImporter.import` still goes through the HTML pivot. Native-import path is a separate piece of work.
- Cross-format adapter discovery / DI. Each format takes adapters via constructor; there is no global registry. This is intentional — adapters are inherently format-typed.
