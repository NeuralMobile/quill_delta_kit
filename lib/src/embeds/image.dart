import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

class ImageAdapter extends EmbedAdapter {
  @override
  String get type => 'image';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final img = dom.Element.tag('img');
    img.attributes['src'] = value is String ? value : (value as Map?)?['source']?.toString() ?? '';
    if (siblingAttrs != null) {
      for (final entry in siblingAttrs.entries) {
        final k = entry.key;
        final v = entry.value?.toString() ?? '';
        if (v.isEmpty) continue;
        if (k == 'width' || k == 'height' || k == 'alt' || k == 'title') {
          img.attributes[k] = v;
        } else if (k == 'style') {
          img.attributes['style'] = v;
        } else {
          // Preserve unknown attrs prefixed with data- so round-trip survives.
          img.attributes['data-quill-$k'] = v;
        }
      }
    }
    parent.append(img);
  }

  @override
  bool matches(dom.Element element) => element.localName == 'img';

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final src = element.attributes['src'] ?? '';
    final attrs = <String, dynamic>{};
    for (final entry in element.attributes.entries) {
      final key = entry.key.toString();
      if (key == 'src') continue;
      final value = entry.value;
      if (key == 'width' || key == 'height' || key == 'alt' || key == 'title' || key == 'style') {
        attrs[key] = value;
      } else if (key.startsWith('data-quill-')) {
        attrs[key.substring('data-quill-'.length)] = value;
      }
    }
    return {
      'insert': {'image': src},
      if (attrs.isNotEmpty) 'attributes': attrs,
    };
  }
}
