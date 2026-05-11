import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Two import paths:
///   1. Toolbar button — installs `buildImportDocumentButton(...)` on the
///      compact toolbar. Tapping it opens a file picker and INSERTS the
///      imported content at the editor's cursor (does not replace doc).
///   2. Side panel — picks a file or pastes text and REPLACES the entire
///      document.
class ImportDemo extends StatefulWidget {
  const ImportDemo({super.key});

  @override
  State<ImportDemo> createState() => _ImportDemoState();
}

class _ImportDemoState extends State<ImportDemo> {
  final _controller = QuillController.basic();
  final _importer = QuillDocumentImporter();
  final _pasteController = TextEditingController();
  String _status = 'Cursor-mode: tap the upload icon in the toolbar. '
      'Replace-mode: use the buttons below.';

  @override
  void dispose() {
    _controller.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<ImportSource?> _pickSource(BuildContext _) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'htm', 'md', 'markdown', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    final bytes = f.bytes;
    if (bytes == null) return null;
    final name = f.name;
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
    // Hand text formats over as text so the importer doesn't sniff bytes.
    if (ext == 'html' || ext == 'htm' || ext == 'md' || ext == 'markdown') {
      final format = (ext == 'html' || ext == 'htm') ? 'html' : 'markdown';
      return ImportSource.text(
        text: String.fromCharCodes(bytes),
        filename: name,
        format: format,
      );
    }
    return ImportSource.bytes(bytes: bytes, filename: name);
  }

  Future<void> _importFileReplace() async {
    final src = await _pickSource(context);
    if (src == null) return;
    try {
      switch (src) {
        case ImportSourceText():
          await _importer.importText(
            controller: _controller,
            text: src.text,
            format: src.format,
          );
        case ImportSourceBytes():
          await _importer.importBytes(
            controller: _controller,
            bytes: src.bytes,
            filename: src.filename,
          );
      }
      setState(() => _status = 'Replaced document from ${src.filename}');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    }
  }

  Future<void> _replaceFromText(
      String label, String text, String format) async {
    try {
      await _importer.importText(
        controller: _controller,
        text: text,
        format: format,
      );
      setState(() => _status = 'Replaced document from sample: $label');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    }
  }

  Future<void> _replaceFromPaste() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() => _status = 'Paste-area is empty.');
      return;
    }
    try {
      await _importer.importText(controller: _controller, text: text);
      setState(() => _status = 'Replaced document from pasted text.');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // The toolbar button: picks a file and inserts it at the cursor.
    final insertButton = buildImportDocumentButton(
      controller: _controller,
      pickSource: _pickSource,
      tooltip: 'Insert document at cursor…',
      onError: (e, st) =>
          setState(() => _status = 'Insert-at-cursor failed: $e'),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Import documents')),
      body: Column(
        children: [
          // Side panel: REPLACE-mode controls.
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Replace from file'),
                  onPressed: _importFileReplace,
                ),
                OutlinedButton(
                  onPressed: () =>
                      _replaceFromText('HTML', _sampleHtml, 'html'),
                  child: const Text('Replace from sample HTML'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _replaceFromText('Markdown', _sampleMarkdown, 'markdown'),
                  child: const Text('Replace from sample Markdown'),
                ),
                OutlinedButton(
                  onPressed: () => _controller.clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _pasteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Replace document with pasted HTML/Markdown',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: 'Replace from pasted text',
                  onPressed: _replaceFromPaste,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(_status, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: QuillDeltaEditor(
                  controller: _controller,
                  layout: const EditorLayoutConfig.expanded(
                    placeholder:
                        'Imported document appears here. Tap the upload '
                        'icon on the toolbar to inject content at the '
                        'cursor.',
                  ),
                  toolbar: ToolbarConfig.top(
                    style: ToolbarStyle.compact,
                    // Adds the import button to the right of the built-in
                    // formatting buttons. This is the new "tool" — same
                    // entry surface as bold/italic, just an action button.
                    customButtons: [insertButton],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _sampleHtml = '''
<h1>From the HTML importer</h1>
<p>Mixed inline: <strong>bold</strong>, <em>italic</em>,
<a href="https://example.com">link</a>, <code>code</code>.</p>
<ul>
  <li>list item one</li>
  <li>list item two</li>
</ul>
<blockquote>quoted text</blockquote>
<pre><code class="language-dart">void main() => print('hi');</code></pre>
''';

const _sampleMarkdown = '''
# From the Markdown importer

A paragraph with **bold**, *italic*, and a [link](https://example.com).

- item one
- item two

> blockquote line

```dart
void main() => print('hi');
```
''';
