import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

class VimeoAdapter extends EmbedAdapter {
  @override
  String get type => '__vimeo_sniff__';

  static final _re = RegExp(r'vimeo\.com', caseSensitive: false);

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {}

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'iframe') return false;
    final src = element.attributes['src'] ?? '';
    return _re.hasMatch(src);
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    return {
      'insert': {'video': element.attributes['src']!},
    };
  }
}
