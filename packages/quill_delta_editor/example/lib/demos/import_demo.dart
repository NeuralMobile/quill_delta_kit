import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Import HTML / Markdown / Docx (and friends) into the editor via the
/// file picker, sample buttons, or a paste-from-clipboard text area.
class ImportDemo extends StatefulWidget {
  const ImportDemo({super.key});

  @override
  State<ImportDemo> createState() => _ImportDemoState();
}

class _ImportDemoState extends State<ImportDemo> {
  final _controller = QuillController.basic();
  final _importer = QuillDocumentImporter();
  final _pasteController = TextEditingController();
  String _status = 'Ready. Pick a file, paste text, or use a sample.';

  @override
  void dispose() {
    _controller.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'htm', 'md', 'markdown', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    final bytes = f.bytes;
    final name = f.name;
    if (bytes == null) {
      setState(() => _status = 'No bytes for ${f.name}');
      return;
    }
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
    try {
      if (ext == 'html' || ext == 'htm' || ext == 'md' || ext == 'markdown') {
        final format = (ext == 'html' || ext == 'htm') ? 'html' : 'markdown';
        await _importer.importText(
          controller: _controller,
          text: String.fromCharCodes(bytes),
          format: format,
        );
      } else {
        await _importer.importBytes(
          controller: _controller,
          bytes: bytes,
          filename: name,
        );
      }
      setState(() => _status =
          'Imported ${f.name} (${bytes.length} bytes) as $ext');
    } catch (e) {
      setState(() => _status = 'Failed to import ${f.name}: $e');
    }
  }

  Future<void> _importText(String label, String text, String format) async {
    try {
      await _importer.importText(
        controller: _controller,
        text: text,
        format: format,
      );
      setState(() => _status = 'Imported sample: $label');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    }
  }

  Future<void> _importPasted() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() => _status = 'Paste-area is empty.');
      return;
    }
    try {
      await _importer.importText(
        controller: _controller,
        text: text,
      );
      setState(() => _status = 'Imported pasted text (auto-detected).');
    } catch (e) {
      setState(() => _status = 'Failed to import pasted text: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import documents')),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Pick file'),
                  onPressed: _importFile,
                ),
                OutlinedButton(
                  onPressed: () => _importText(
                    'HTML',
                    _sampleHtml,
                    'html',
                  ),
                  child: const Text('Sample HTML'),
                ),
                OutlinedButton(
                  onPressed: () => _importText(
                    'Markdown',
                    _sampleMarkdown,
                    'markdown',
                  ),
                  child: const Text('Sample Markdown'),
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
                labelText: 'Paste HTML or Markdown here',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.upload),
                  tooltip: 'Import pasted text',
                  onPressed: _importPasted,
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
                    placeholder: 'Imported document appears here…',
                  ),
                  toolbar: const ToolbarConfig.top(
                    style: ToolbarStyle.compact,
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
