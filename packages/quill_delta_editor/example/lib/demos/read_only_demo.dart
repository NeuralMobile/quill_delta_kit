import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Read-only viewer with no toolbar. Document is preloaded with a sample
/// rich-text Delta — selection still works, editing does not.
class ReadOnlyDemo extends StatefulWidget {
  const ReadOnlyDemo({super.key});

  @override
  State<ReadOnlyDemo> createState() => _ReadOnlyDemoState();
}

class _ReadOnlyDemoState extends State<ReadOnlyDemo> {
  late final QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(_sample),
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
      appBar: AppBar(title: const Text('Read-only viewer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: QuillDeltaEditor(
            controller: _controller,
            layout: const EditorLayoutConfig.expanded(readOnly: true),
            toolbar: const ToolbarConfig.none(),
          ),
        ),
      ),
    );
  }
}

const _sample = [
  {'insert': 'Project Update'},
  {
    'insert': '\n',
    'attributes': {'header': 1}
  },
  {'insert': 'This document is rendered in '},
  {
    'insert': 'read-only',
    'attributes': {'bold': true}
  },
  {'insert': ' mode. You can select text but not edit it.\n\n'},
  {'insert': 'Highlights'},
  {
    'insert': '\n',
    'attributes': {'header': 2}
  },
  {'insert': 'Shipped converter abstraction'},
  {
    'insert': '\n',
    'attributes': {'list': 'bullet'}
  },
  {'insert': 'Added markdown + docx + pdf'},
  {
    'insert': '\n',
    'attributes': {'list': 'bullet'}
  },
  {'insert': 'StringBuffer encoder, ~17% faster round trip'},
  {
    'insert': '\n',
    'attributes': {'list': 'bullet'}
  },
];
