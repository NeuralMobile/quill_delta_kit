import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Editor preloaded with image, video, audio embeds. Renders default
/// placeholders since no custom builders are supplied — see the auth
/// injection demo for a real network preview.
class MediaEmbedsDemo extends StatefulWidget {
  const MediaEmbedsDemo({super.key});

  @override
  State<MediaEmbedsDemo> createState() => _MediaEmbedsDemoState();
}

class _MediaEmbedsDemoState extends State<MediaEmbedsDemo> {
  late final QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(_doc),
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
      appBar: AppBar(title: const Text('Media embeds')),
      body: QuillDeltaEditor(
        controller: _controller,
        layout: const EditorLayoutConfig.expanded(),
        toolbar: const ToolbarConfig.top(),
      ),
    );
  }
}

const _doc = [
  {'insert': 'Mixed media\n'},
  {
    'insert': {'image': 'https://picsum.photos/640/360'}
  },
  {'insert': '\n'},
  {'insert': 'A short video:\n'},
  {
    'insert': {'video': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'}
  },
  {'insert': '\n'},
  {'insert': 'And a podcast:\n'},
  {
    'insert': {'audio': 'https://example.com/podcast.mp3'}
  },
  {'insert': '\n'},
];
