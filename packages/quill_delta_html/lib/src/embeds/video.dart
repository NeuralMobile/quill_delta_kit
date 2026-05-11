import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

const _directVideoExt = {'.mp4', '.webm', '.ogg', '.ogv', '.mov', '.m4v'};

bool _isDirectVideoUrl(String url) {
  final lower = url.toLowerCase().split('?').first;
  return _directVideoExt.any(lower.endsWith);
}

class VideoAdapter extends EmbedAdapter {
  @override
  String get type => 'video';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url =
        value is String ? value : (value as Map?)?['source']?.toString() ?? '';
    final isDirect = _isDirectVideoUrl(url);
    final isYoutube = _yt.hasMatch(url);
    final isVimeo = _vm.hasMatch(url);

    final String tag;
    final Map<String, String> attrs;
    if (isDirect) {
      tag = 'video';
      attrs = <String, String>{'controls': '', 'src': url};
    } else if (isYoutube || isVimeo) {
      tag = 'iframe';
      attrs = <String, String>{
        'src': isYoutube ? _toYouTubeEmbed(url) : _toVimeoEmbed(url),
        'frameborder': '0',
        'allowfullscreen': '',
      };
    } else {
      tag = 'iframe';
      attrs = <String, String>{
        'src': url,
        'frameborder': '0',
        'allowfullscreen': '',
      };
    }
    if (siblingAttrs != null) {
      for (final entry in siblingAttrs.entries) {
        final v = entry.value?.toString() ?? '';
        if (v.isEmpty) continue;
        if (entry.key == 'width' ||
            entry.key == 'height' ||
            entry.key == 'style' ||
            entry.key == 'title') {
          attrs[entry.key] = v;
        }
      }
    }
    writer.open(tag, attrs);
    writer.close(tag);
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName == 'video') return true;
    if (element.localName == 'iframe') {
      final src = element.attributes['src'] ?? '';
      return _yt.hasMatch(src) || _vm.hasMatch(src) || _isDirectVideoUrl(src);
    }
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    var src = element.attributes['src'];
    if (src == null && element.localName == 'video') {
      final source = element.querySelector('source');
      src = source?.attributes['src'];
    }
    if (src == null || src.isEmpty) return null;
    final attrs = <String, dynamic>{};
    for (final entry in element.attributes.entries) {
      final k = entry.key.toString();
      if (k == 'src' ||
          k == 'controls' ||
          k == 'frameborder' ||
          k == 'allowfullscreen') {
        continue;
      }
      if (k == 'width' || k == 'height' || k == 'style' || k == 'title') {
        attrs[k] = entry.value;
      }
    }
    return {
      'insert': {'video': src},
      if (attrs.isNotEmpty) 'attributes': attrs,
    };
  }

  static final _yt = RegExp(
    r'(youtube\.com|youtu\.be|youtube-nocookie\.com)',
    caseSensitive: false,
  );
  static final _vm = RegExp(r'vimeo\.com', caseSensitive: false);

  static String _toYouTubeEmbed(String url) {
    final id = _extractYouTubeId(url);
    if (id == null) return url;
    return 'https://www.youtube.com/embed/$id';
  }

  static String? _extractYouTubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      return segs.isEmpty ? null : segs.first;
    }
    if (uri.queryParameters['v'] != null) return uri.queryParameters['v'];
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return null;
    if (segs.first == 'embed' ||
        segs.first == 'shorts' ||
        segs.first == 'live') {
      return segs.length > 1 ? segs[1] : null;
    }
    return null;
  }

  static String _toVimeoEmbed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host.startsWith('player.')) return url;
    final id =
        uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
    if (id.isEmpty) return url;
    return 'https://player.vimeo.com/video/$id';
  }
}
