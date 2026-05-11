import 'package:flutter/widgets.dart';

/// Pluggable preview builders for media embeds.
///
/// Lets callers inject auth headers (signed URLs, Bearer tokens), custom
/// loading states, error placeholders, or alternative players without
/// patching the editor itself.
///
/// Each builder receives the URL and a [MediaPreviewContext] carrying any
/// auxiliary attributes from the Delta op (alt text, width/height, etc.).
class MediaPreviewBuilders {
  const MediaPreviewBuilders({
    this.imageBuilder,
    this.videoBuilder,
    this.audioBuilder,
    this.formulaBuilder,
  });

  final MediaPreviewBuilder? imageBuilder;
  final MediaPreviewBuilder? videoBuilder;
  final MediaPreviewBuilder? audioBuilder;
  final MediaPreviewBuilder? formulaBuilder;

  /// Convenience: same builder for image / video / audio.
  factory MediaPreviewBuilders.uniform(MediaPreviewBuilder builder) =>
      MediaPreviewBuilders(
        imageBuilder: builder,
        videoBuilder: builder,
        audioBuilder: builder,
      );

  bool get isEmpty =>
      imageBuilder == null &&
      videoBuilder == null &&
      audioBuilder == null &&
      formulaBuilder == null;
}

typedef MediaPreviewBuilder = Widget Function(
  BuildContext context,
  String url,
  MediaPreviewContext meta,
);

/// Auxiliary metadata attached to an embed op.
class MediaPreviewContext {
  const MediaPreviewContext({
    required this.kind,
    this.width,
    this.height,
    this.alt,
    this.title,
    this.style,
    this.extra = const {},
  });

  /// 'image' / 'video' / 'audio' / 'formula' / unknown type.
  final String kind;
  final double? width;
  final double? height;
  final String? alt;
  final String? title;
  final String? style;

  /// Any sibling attributes that aren't first-class above (e.g. data-*).
  final Map<String, Object?> extra;

  static MediaPreviewContext fromAttrs(
    String kind,
    Map<String, dynamic>? attrs,
  ) {
    if (attrs == null) return MediaPreviewContext(kind: kind);
    double? d(Object? v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return MediaPreviewContext(
      kind: kind,
      width: d(attrs['width']),
      height: d(attrs['height']),
      alt: attrs['alt']?.toString(),
      title: attrs['title']?.toString(),
      style: attrs['style']?.toString(),
      extra: Map.fromEntries(
        attrs.entries.where((e) =>
            e.key != 'width' &&
            e.key != 'height' &&
            e.key != 'alt' &&
            e.key != 'title' &&
            e.key != 'style'),
      ),
    );
  }
}
