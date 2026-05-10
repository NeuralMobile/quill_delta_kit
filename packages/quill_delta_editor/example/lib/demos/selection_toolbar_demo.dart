import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// iOS-style selection-context toolbar. Toolbar pops up when text is
/// selected and disappears when the selection collapses.
class SelectionToolbarDemo extends StatefulWidget {
  const SelectionToolbarDemo({super.key});

  @override
  State<SelectionToolbarDemo> createState() => _SelectionToolbarDemoState();
}

class _SelectionToolbarDemoState extends State<SelectionToolbarDemo> {
  late final QuillController _controller;
  SelectionAnchor _anchor = SelectionAnchor.above;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(const [
        {'insert': 'Try selecting some text.\n'},
        {'insert': 'A floating toolbar will appear above (or below) '},
        {'insert': 'the selection', 'attributes': {'bold': true}},
        {'insert': ' — like the iOS context menu.\n\n'},
        {'insert':
          'Tap somewhere with no selection to dismiss it. Drag-select '
          'across multiple lines to keep it open.\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selection toolbar (iOS-style)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<SelectionAnchor>(
              segments: const [
                ButtonSegment(
                  value: SelectionAnchor.above,
                  label: Text('Above'),
                ),
                ButtonSegment(
                  value: SelectionAnchor.below,
                  label: Text('Below'),
                ),
              ],
              selected: {_anchor},
              onSelectionChanged: (s) => setState(() => _anchor = s.first),
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
                  layout: const EditorLayoutConfig.expanded(),
                  toolbar: ToolbarConfig.selection(
                    anchor: _anchor,
                    style: ToolbarStyle.minimal,
                    backgroundColor:
                        Theme.of(context).colorScheme.inverseSurface,
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
