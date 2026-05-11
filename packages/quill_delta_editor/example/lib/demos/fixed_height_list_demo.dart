import 'package:flutter/material.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Many independent fixed-height editors inside a scrollable list. Each
/// editor scrolls internally; the outer list scrolls between them.
class FixedHeightListDemo extends StatefulWidget {
  const FixedHeightListDemo({super.key});

  @override
  State<FixedHeightListDemo> createState() => _FixedHeightListDemoState();
}

class _FixedHeightListDemoState extends State<FixedHeightListDemo> {
  final _controllers = List.generate(6, (_) => QuillController.basic());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fixed-height list')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _controllers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note ${i + 1}',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  QuillDeltaEditor(
                    controller: _controllers[i],
                    layout: EditorLayoutConfig.fixed(
                      height: 180,
                      placeholder: 'Note ${i + 1} body…',
                    ),
                    toolbar: const ToolbarConfig.bottom(
                      style: ToolbarStyle.minimal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
