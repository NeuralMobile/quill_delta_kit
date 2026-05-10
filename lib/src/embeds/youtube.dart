import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

/// Detects YouTube iframes and promotes to typed `video` Delta op.
/// Encode side handled by VideoAdapter (this adapter only sniffs on decode).
class YouTubeAdapter extends EmbedAdapter {
  @override
  String get type => '__youtube_sniff__';

  static final _re = RegExp(
    r'(youtube\.com|youtu\.be|youtube-nocookie\.com)',
    caseSensitive: false,
  );

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    // No-op: video adapter handles encoding.
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'iframe') return false;
    final src = element.attributes['src'] ?? '';
    return _re.hasMatch(src);
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final src = element.attributes['src']!;
    return {
      'insert': {'video': src},
    };
  }
}
