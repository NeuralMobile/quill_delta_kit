# quill_delta_html — Example App

Live demo of `quill_delta_html` paired with `flutter_quill ^11.0.0`.

## What it shows

3-pane live view:

| Pane | Content |
|---|---|
| **Editor** | `flutter_quill` editor with full toolbar |
| **Encoded HTML** | Live `codec.encode(delta)` output |
| **Round-trip Delta** | `codec.decode(codec.encode(delta))` re-serialized |

Top-right badge shows `lossless ✓` when round-trip equals original Delta after normalization, `mismatch ✗` otherwise.

## Sample loaders

Top bar exposes:

- **Δ Fixture chips** — load a Delta op list into the editor (Empty, Inline formats, Color + size, Headings, Lists, Checklist, Quote + Code, Align + RTL, Link + Script, Image + Video, Audio, Mention + Divider, Formula, Whitespace stress, Big mixed doc).
- **HTML in chips** — paste pre-canned editor outputs (Quill, TipTap, CKEditor, ProseMirror, Table) through `decode` and load the resulting Delta.

Edit anything to see the round-trip badge update in real time.

## Run

### CLI
```bash
cd example
flutter pub get
flutter run -d macos        # or chrome / ios / android
```

### VS Code / Cursor
Open `example/` as a workspace, hit **F5**, pick:

- `Flutter: Web (Chrome)` / `… Profile`
- `Flutter: macOS` / `… Profile` / `… Release`
- `Flutter: iOS Simulator` / `Flutter: iOS (Connected)`
- `Flutter: Android Emulator` / `Flutter: Android (Connected)`
- `Flutter: Pick Device`

Configs live in `.vscode/launch.json`. Build tasks in `.vscode/tasks.json` (Cmd+Shift+B).

### Android Studio / IntelliJ
Open `example/` as a project. Run configurations appear automatically:

- `Web (Chrome)`, `macOS`, `iOS Simulator`, `Android`

Configs live in `.idea/runConfigurations/`.

## Supported platforms

| Platform | Verified |
|---|---|
| Web (Chrome) | ✓ `flutter build web --release` |
| macOS | ✓ `flutter build macos --debug` |
| iOS | scaffolded |
| Android | scaffolded |

## Files

- `lib/main.dart` — app, codec wiring, 3-pane layout, status badge.
- `lib/fixtures.dart` — Delta + HTML test fixtures.
- `pubspec.yaml` — wires `flutter_quill ^11.0.0` and the local `quill_delta_html` package via path.

## Notes

- Codec is configured with all built-in adapters plus optional Loom/Spotify/CodePen/Tweet/Audio/Table adapters.
- `wrapDocument: true` so output includes `<div class="ql-html-doc" style="white-space: pre-wrap">…</div>`. Drop to false for fragment HTML.
- `IframePolicy` restricts iframes to `https`. Tighten `allowedHosts` for production.
