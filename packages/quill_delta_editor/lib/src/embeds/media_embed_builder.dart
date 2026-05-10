import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'media_preview_builders.dart';

/// flutter_quill [EmbedBuilder] for image/video/audio that delegates to a
/// caller-supplied [MediaPreviewBuilder]. When no caller builder is set,
/// falls back to a styled placeholder so the embed is visible without any
/// network or platform plugin.
class MediaEmbedBuilder extends EmbedBuilder {
  MediaEmbedBuilder.image({MediaPreviewBuilder? customBuilder})
      : _kind = 'image',
        _customBuilder = customBuilder;

  MediaEmbedBuilder.video({MediaPreviewBuilder? customBuilder})
      : _kind = 'video',
        _customBuilder = customBuilder;

  MediaEmbedBuilder.audio({MediaPreviewBuilder? customBuilder})
      : _kind = 'audio',
        _customBuilder = customBuilder;

  final String _kind;
  final MediaPreviewBuilder? _customBuilder;

  @override
  String get key => _kind;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final url = node.value.data?.toString() ?? '';
    final attrs = _attrsFromNode(node);
    final meta = MediaPreviewContext.fromAttrs(_kind, attrs);
    if (_customBuilder != null) {
      return _customBuilder(context, url, meta);
    }
    return _Placeholder(kind: _kind, url: url, meta: meta);
  }

  Map<String, dynamic>? _attrsFromNode(Embed node) {
    // flutter_quill embeds don't carry sibling attributes directly on the
    // leaf node in a generic way — width/height/etc would live on the
    // op-level `attributes`. The parent's style usually has them, but the
    // public API doesn't expose siblings here. Return null; the builder
    // gets the URL and consumers can fetch metadata out-of-band.
    return null;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.kind,
    required this.url,
    required this.meta,
  });

  final String kind;
  final String url;
  final MediaPreviewContext meta;

  @override
  Widget build(BuildContext context) {
    final w = meta.width ?? double.infinity;
    final h = meta.height ?? _defaultHeight(kind);
    final icon = switch (kind) {
      'image' => Icons.image_outlined,
      'video' => Icons.videocam_outlined,
      'audio' => Icons.audiotrack_outlined,
      _ => Icons.attach_file,
    };
    return Container(
      constraints: BoxConstraints(maxWidth: w, minHeight: h),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(6),
        color: Colors.black.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url.isEmpty ? '<no $kind url>' : url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  double _defaultHeight(String k) => switch (k) { 'image' => 120, 'video' => 180, 'audio' => 56, _ => 56 };
}
