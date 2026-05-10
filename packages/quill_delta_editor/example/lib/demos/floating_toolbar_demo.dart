import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Floating toolbar in each of the 4 corner positions, switchable via
/// segmented control.
class FloatingToolbarDemo extends StatefulWidget {
  const FloatingToolbarDemo({super.key});

  @override
  State<FloatingToolbarDemo> createState() => _FloatingToolbarDemoState();
}

class _FloatingToolbarDemoState extends State<FloatingToolbarDemo> {
  final _controller = QuillController.basic();
  FloatingToolbarPosition _position = FloatingToolbarPosition.topRight;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floating toolbar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<FloatingToolbarPosition>(
              segments: const [
                ButtonSegment(
                  value: FloatingToolbarPosition.topCenter,
                  label: Text('TC'),
                ),
                ButtonSegment(
                  value: FloatingToolbarPosition.topRight,
                  label: Text('TR'),
                ),
                ButtonSegment(
                  value: FloatingToolbarPosition.bottomCenter,
                  label: Text('BC'),
                ),
                ButtonSegment(
                  value: FloatingToolbarPosition.bottomRight,
                  label: Text('BR'),
                ),
              ],
              selected: {_position},
              onSelectionChanged: (s) => setState(() => _position = s.first),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: QuillDeltaEditor(
                  controller: _controller,
                  layout: const EditorLayoutConfig.expanded(
                    placeholder: 'Type — toolbar floats above…',
                  ),
                  toolbar: ToolbarConfig.floating(
                    position: _position,
                    style: ToolbarStyle.minimal,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
