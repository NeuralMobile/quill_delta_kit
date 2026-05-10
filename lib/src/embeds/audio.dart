import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

class AudioAdapter extends EmbedAdapter {
  @override
  String get type => 'audio';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final url = value is String ? value : (value as Map?)?['source']?.toString() ?? '';
    final node = dom.Element.tag('audio')
      ..attributes['controls'] = ''
      ..attributes['src'] = url;
    if (siblingAttrs != null) {
      for (final entry in siblingAttrs.entries) {
        final v = entry.value?.toString() ?? '';
        if (v.isEmpty) continue;
        if (entry.key == 'style' || entry.key == 'title' || entry.key == 'preload') {
          node.attributes[entry.key] = v;
        }
      }
    }
    parent.append(node);
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName == 'audio') return true;
    if (element.localName == 'iframe') {
      final src = (element.attributes['src'] ?? '').toLowerCase().split('?').first;
      return src.endsWith('.mp3') || src.endsWith('.wav') || src.endsWith('.m4a') || src.endsWith('.ogg');
    }
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    var src = element.attributes['src'];
    if (src == null && element.localName == 'audio') {
      final source = element.querySelector('source');
      src = source?.attributes['src'];
    }
    if (src == null || src.isEmpty) return null;
    final attrs = <String, dynamic>{};
    for (final entry in element.attributes.entries) {
      final k = entry.key.toString();
      if (k == 'src' || k == 'controls') continue;
      if (k == 'style' || k == 'title' || k == 'preload') {
        attrs[k] = entry.value;
      }
    }
    return {
      'insert': {'audio': src},
      if (attrs.isNotEmpty) 'attributes': attrs,
    };
  }
}
