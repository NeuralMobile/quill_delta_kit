import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Demonstrates how to inject auth headers into media previews.
///
/// In real apps a Bearer token, signed S3 URL, or per-request signature
/// goes here. This demo shows: (a) the imageBuilder receives URL +
/// MediaPreviewContext, (b) you can wrap any widget the way the rest of
/// your app does (Image.network with headers, NetworkImage with provider,
/// signed-URL fetch, etc).
class AuthInjectionDemo extends StatefulWidget {
  const AuthInjectionDemo({super.key});

  @override
  State<AuthInjectionDemo> createState() => _AuthInjectionDemoState();
}

class _AuthInjectionDemoState extends State<AuthInjectionDemo> {
  late final QuillController _controller;

  // Mock token — your real app would pull this from secure storage / oauth.
  // Used in the comment in _AuthImage to show where it would go.
  // ignore: unused_field
  static const _bearerToken = 'mock-jwt-token';

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(const [
        {'insert': 'These previews receive the bearer token via headers:\n'},
        {'insert': {'image': 'https://api.private.example.com/img/42.jpg'}},
        {'insert': '\n'},
        {'insert': 'And here is a video clip:\n'},
        {'insert': {'video': 'https://api.private.example.com/v/playback.m3u8'}},
        {'insert': '\n'},
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
      appBar: AppBar(title: const Text('Auth-injected previews')),
      body: QuillDeltaEditor(
        controller: _controller,
        layout: const EditorLayoutConfig.expanded(),
        toolbar: const ToolbarConfig.none(),
        previewBuilders: MediaPreviewBuilders(
          imageBuilder: (ctx, url, meta) => _AuthImage(url: url, meta: meta),
          videoBuilder: (ctx, url, meta) => _AuthVideoPlaceholder(url: url),
          audioBuilder: (ctx, url, meta) => _AuthAudioPlaceholder(url: url),
        ),
      ),
    );
  }
}

class _AuthImage extends StatelessWidget {
  const _AuthImage({required this.url, required this.meta});
  final String url;
  final MediaPreviewContext meta;

  @override
  Widget build(BuildContext context) {
    // Real: Image.network(url, headers: {'Authorization': 'Bearer ${_AuthInjectionDemoState._bearerToken}'})
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Image.network(url, headers: {Authorization: Bearer …})',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthVideoPlaceholder extends StatelessWidget {
  const _AuthVideoPlaceholder({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline,
                color: Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(url,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _AuthAudioPlaceholder extends StatelessWidget {
  const _AuthAudioPlaceholder({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.audiotrack),
            const SizedBox(width: 8),
            Expanded(child: Text(url, overflow: TextOverflow.ellipsis)),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
