import 'dart:convert';
import 'dart:typed_data';

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

    // For images, decode `data:` URIs (the path docx imports take when
    // surfacing embedded media as base64 data URIs) and try the network
    // path otherwise. Decoding errors fall back to the textual placeholder.
    //
    // Caching note: bytes are kept in [_DataUriCache] so repeated rebuilds
    // (focus changes, scrolling) reuse the same [Uint8List] instance —
    // [MemoryImage] keys its [ImageCache] entry off `bytes.hashCode`
    // (identity for Uint8List), so a stable instance is what keeps the
    // image hot in Flutter's image cache. `gaplessPlayback: true` keeps
    // the previously-painted frame visible while any new decode happens,
    // eliminating the flicker reported during scroll/focus.
    if (kind == 'image' && url.isNotEmpty) {
      final memBytes = _DataUriCache.lookup(url);
      if (memBytes != null) {
        return _wrapImage(
          Image.memory(
            memBytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          maxWidth: w,
        );
      }
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return _wrapImage(
          Image.network(
            url,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          maxWidth: w,
        );
      }
    }

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
              url.isEmpty ? '<no $kind url>' : _truncate(url),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapImage(Widget child, {required double maxWidth}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: BoxConstraints(maxWidth: maxWidth.isFinite ? maxWidth : 600),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }

  /// Data URIs run thousands of chars long. Cap the textual fallback so it
  /// doesn't blow out the placeholder.
  static String _truncate(String s) =>
      s.length > 120 ? '${s.substring(0, 120)}…' : s;

  double _defaultHeight(String k) =>
      switch (k) { 'image' => 120, 'video' => 180, 'audio' => 56, _ => 56 };
}

/// Process-wide LRU-ish cache of decoded `data:` URI bytes keyed by the
/// full URI string.
///
/// Why this matters: `Image.memory(bytes)` internally creates a
/// [MemoryImage] whose cache key is `bytes.hashCode`. For [Uint8List]
/// hashCode is identity-based (not content) so decoding the same URI on
/// every rebuild produces a fresh `Uint8List` and misses Flutter's
/// [ImageCache], causing repeated decode work + visible flicker on focus
/// / scroll rebuilds. Holding a single byte buffer per URI lets the image
/// cache stay hot.
///
/// Capacity is bounded to [_maxEntries] entries; when full, the
/// oldest-inserted entry is evicted (insertion order in [LinkedHashMap],
/// which is the default Dart [Map]).
class _DataUriCache {
  _DataUriCache._();

  static const int _maxEntries = 64;
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  /// Return the cached byte buffer for [url] if present, otherwise decode
  /// from the URI, cache the result, and return it. Returns null when
  /// [url] is not a base64 data URI we can decode.
  static Uint8List? lookup(String url) {
    final hit = _cache[url];
    if (hit != null) return hit;
    final bytes = _decode(url);
    if (bytes == null) return null;
    if (_cache.length >= _maxEntries) {
      // Drop oldest insertion-order entry.
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = bytes;
    return bytes;
  }

  static Uint8List? _decode(String url) {
    if (!url.startsWith('data:')) return null;
    final comma = url.indexOf(',');
    if (comma == -1) return null;
    final header = url.substring(5, comma);
    if (!header.contains('base64')) return null;
    try {
      return base64.decode(url.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }
}
