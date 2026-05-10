import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Auto-grow with explicit min/max bounds. As the user types, the editor
/// grows up to maxHeight; below minHeight it stays the minimum size.
class AutoGrowDemo extends StatefulWidget {
  const AutoGrowDemo({super.key});

  @override
  State<AutoGrowDemo> createState() => _AutoGrowDemoState();
}

class _AutoGrowDemoState extends State<AutoGrowDemo> {
  final _controller = QuillController.basic();
  double _maxHeight = 240;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-grow')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Max height: ${_maxHeight.toInt()}px'),
            Slider(
              min: 120,
              max: 600,
              value: _maxHeight,
              onChanged: (v) => setState(() => _maxHeight = v),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: QuillDeltaEditor(
                controller: _controller,
                layout: EditorLayoutConfig.autoGrow(
                  minHeight: 80,
                  maxHeight: _maxHeight,
                  placeholder: 'Type to see the editor grow…',
                ),
                toolbar: const ToolbarConfig.top(
                  style: ToolbarStyle.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
