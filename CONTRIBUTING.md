# Contributing

This is a Dart 3.6 native workspace. The repository hosts five packages:

```
packages/
  quill_delta_core/      # zero-HTML shared abstractions
  quill_delta_html/      # HTML codec
  quill_delta_markdown/  # Markdown codec
  quill_delta_docx/      # DOCX codec
  quill_delta_pdf/       # PDF stub
```

## Local development

```bash
# resolve everything once at the workspace root
dart pub get

# run a package's tests
cd packages/quill_delta_html && dart test

# run all tests across the workspace
for pkg in packages/*/; do (cd "$pkg" && dart test); done
```

`resolution: workspace` and `path:` dependencies between packages mean every
edit is picked up immediately by every consumer in the monorepo without a
separate `pub get`.

## Running benchmarks

```bash
cd packages/quill_delta_html
dart run bench/encode_decode_bench.dart
```

## Publishing

Pub blocks publishing packages that carry `path:` dependencies. The
workspace layout uses path deps for development. Use `tool/publish.dart`
to swap them for caret-version constraints right before publish, then
restore the workspace state.

**Order matters** — publish in dependency order:

1. `quill_delta_core`
2. `quill_delta_html`
3. `quill_delta_markdown`
4. `quill_delta_docx`
5. `quill_delta_pdf` (stays `publish_to: none` until implemented)

For each package:

```bash
# 1. write a preview to inspect the swap
dart run tool/publish.dart quill_delta_core
diff packages/quill_delta_core/pubspec.yaml packages/quill_delta_core/pubspec.publish.yaml

# 2. apply (backs up pubspec.yaml -> pubspec.yaml.bak)
dart run tool/publish.dart quill_delta_core --apply

# 3. dry-run publish
(cd packages/quill_delta_core && dart pub publish --dry-run)

# 4. real publish
(cd packages/quill_delta_core && dart pub publish)

# 5. restore workspace state
dart run tool/publish.dart quill_delta_core --restore
```

When bumping a downstream package's version because core gained an API,
update the `version:` field in the downstream `pubspec.yaml` first; the
script reads it back when rewriting consumers.

## Test layout

- Per-package unit + integration tests in `packages/<pkg>/test/`.
- The shared converter contract suite in
  `packages/quill_delta_core/lib/quill_delta_core_test_contract.dart` is
  consumed by every format package's `test/contract_test.dart`. Add
  fixtures there when introducing cross-format expectations.

## Commit style

- Conventional Commits prefixes (`feat`, `fix`, `perf`, `chore`, `test`,
  `docs`).
- Use `!` for breaking changes (`feat!:`, `chore!:`).
- Imperative mood, lower-case subject.
