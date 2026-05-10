import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Editor inside a scrollable form alongside other inputs.
///
/// Uses [EditorLayoutConfig.autoGrow] so the page's [ListView] owns the
/// scroll and the editor sizes itself to its content (clamped by maxHeight).
class ScrollableFormDemo extends StatefulWidget {
  const ScrollableFormDemo({super.key});

  @override
  State<ScrollableFormDemo> createState() => _ScrollableFormDemoState();
}

class _ScrollableFormDemoState extends State<ScrollableFormDemo> {
  final _title = TextEditingController(text: 'My note');
  late final QuillController _body = QuillController.basic();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scrollable form')),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Body', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: QuillDeltaEditor(
                controller: _body,
                layout: const EditorLayoutConfig.autoGrow(
                  minHeight: 120,
                  maxHeight: 400,
                  placeholder: 'Write your note…',
                ),
                toolbar: const ToolbarConfig.top(
                  style: ToolbarStyle.compact,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Title="${_title.text}", body length='
                    '${_body.document.length}',
                  ),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
