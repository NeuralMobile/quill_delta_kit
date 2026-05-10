import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

/// CKEditor MediaEmbed: `<figure class="media"><oembed url="..."></oembed></figure>`
/// or with iframe child: `<figure class="media"><div data-oembed-url="..."><iframe ...></iframe></div></figure>`.
class OEmbedAdapter extends EmbedAdapter {
  @override
  String get type => '__oembed_sniff__';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {}

  @override
  bool matches(dom.Element element) {
    final name = element.localName;
    if (name == 'oembed') return true;
    if (name == 'figure') {
      final cls = element.attributes['class'] ?? '';
      if (cls.split(' ').contains('media')) return true;
    }
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    String? url;
    if (element.localName == 'oembed') {
      url = element.attributes['url'];
    } else {
      // Figure wrapper: look for <oembed> first, then nested data-oembed-url, then iframe.
      final oembed = element.querySelector('oembed');
      if (oembed != null) {
        url = oembed.attributes['url'];
      }
      url ??= element.querySelector('[data-oembed-url]')?.attributes['data-oembed-url'];
      url ??= element.querySelector('iframe')?.attributes['src'];
    }
    if (url == null || url.isEmpty) return null;
    return {
      'insert': {'video': url},
    };
  }
}
