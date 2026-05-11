import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

/// Loom: `loom.com/embed/<id>`, `loom.com/share/<id>`.
class LoomAdapter extends EmbedAdapter {
  @override
  String get type => 'loom';

  static final _re = RegExp(r'loom\.com', caseSensitive: false);

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value is String ? value : value?.toString() ?? '';
    final attrs = <String, String>{
      'allowfullscreen': '',
      'frameborder': '0',
      'src': _toEmbed(url),
    };
    _applySiblings(attrs, siblingAttrs);
    writer.open('iframe', attrs);
    writer.close('iframe');
  }

  static String _toEmbed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isNotEmpty && segs.first == 'embed') return url;
    if (segs.length >= 2 && segs.first == 'share') {
      return 'https://www.loom.com/embed/${segs[1]}';
    }
    return url;
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'iframe') return false;
    final src = element.attributes['src'] ?? '';
    return _re.hasMatch(src);
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    return {
      'insert': {'loom': element.attributes['src']!}
    };
  }
}

/// Spotify: `open.spotify.com/embed/...`.
class SpotifyAdapter extends EmbedAdapter {
  @override
  String get type => 'spotify';

  static final _re = RegExp(r'(open\.)?spotify\.com', caseSensitive: false);

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value is String ? value : value?.toString() ?? '';
    final attrs = <String, String>{
      'allow': 'autoplay; clipboard-write; encrypted-media; picture-in-picture',
      'frameborder': '0',
      'src': _toEmbed(url),
    };
    _applySiblings(attrs, siblingAttrs);
    writer.open('iframe', attrs);
    writer.close('iframe');
  }

  static String _toEmbed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.path.startsWith('/embed/')) return url;
    return url.replaceFirst(RegExp(r'spotify\.com/'), 'spotify.com/embed/');
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'iframe') return false;
    return _re.hasMatch(element.attributes['src'] ?? '');
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    return {
      'insert': {'spotify': element.attributes['src']!}
    };
  }
}

/// SoundCloud: `w.soundcloud.com/player/...` or `soundcloud.com/...`.
class SoundCloudAdapter extends EmbedAdapter {
  @override
  String get type => 'soundcloud';

  static final _re = RegExp(r'soundcloud\.com', caseSensitive: false);

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value is String ? value : value?.toString() ?? '';
    final attrs = <String, String>{
      'allow': 'autoplay',
      'frameborder': '0',
      'scrolling': 'no',
      'src': url,
    };
    _applySiblings(attrs, siblingAttrs);
    writer.open('iframe', attrs);
    writer.close('iframe');
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'iframe') return false;
    return _re.hasMatch(element.attributes['src'] ?? '');
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    return {
      'insert': {'soundcloud': element.attributes['src']!}
    };
  }
}

/// Twitter / X: `twitter.com/...`, `x.com/...`. Often delivered as oEmbed.
/// Stored as a `tweet` embed with the canonical tweet URL.
class TweetAdapter extends EmbedAdapter {
  @override
  String get type => 'tweet';

  static final _re = RegExp(r'(twitter|x)\.com', caseSensitive: false);

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value is String ? value : value?.toString() ?? '';
    writer.open('blockquote', {
      'class': 'twitter-tweet',
      'data-tweet-url': url,
    });
    writer.open('a', {'href': url});
    writer.text(url);
    writer.close('a');
    writer.close('blockquote');
  }

  @override
  bool matches(dom.Element element) {
    final cls = element.attributes['class'] ?? '';
    if (element.localName == 'blockquote' &&
        cls.split(' ').contains('twitter-tweet')) return true;
    if (element.localName == 'iframe') {
      final src = element.attributes['src'] ?? '';
      return _re.hasMatch(src) && src.contains('/embed');
    }
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final url = element.attributes['data-tweet-url'] ??
        element.querySelector('a')?.attributes['href'] ??
        element.attributes['src'] ??
        '';
    if (url.isEmpty) return null;
    return {
      'insert': {'tweet': url}
    };
  }
}

/// CodePen: `codepen.io/<user>/embed/<id>`.
class CodePenAdapter extends EmbedAdapter {
  @override
  String get type => 'codepen';

  static final _re = RegExp(r'codepen\.io', caseSensitive: false);

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value is String ? value : value?.toString() ?? '';
    final attrs = <String, String>{
      'allowfullscreen': '',
      'frameborder': '0',
      'src': _toEmbed(url),
    };
    _applySiblings(attrs, siblingAttrs);
    writer.open('iframe', attrs);
    writer.close('iframe');
  }

  static String _toEmbed(String url) {
    if (url.contains('/embed/')) return url;
    return url.replaceFirst('/pen/', '/embed/');
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'iframe') return false;
    return _re.hasMatch(element.attributes['src'] ?? '');
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    return {
      'insert': {'codepen': element.attributes['src']!}
    };
  }
}

void _applySiblings(Map<String, String> attrs, Map<String, dynamic>? siblings) {
  if (siblings == null) return;
  for (final entry in siblings.entries) {
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
