import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

/// Generic iframe round-trip via flutter_quill custom embed wrapper.
/// Runs LAST in dispatch order so provider-specific adapters (YouTube/Vimeo) win.
class IframeAdapter extends EmbedAdapter {
  @override
  String get type => 'iframe';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final m = value is Map ? value : <String, dynamic>{};
    final node = dom.Element.tag('iframe');
    final src = m['src']?.toString() ?? '';
    if (src.isEmpty) return;
    if (!options.iframePolicy.isUrlAllowed(src)) return;

    node.attributes['src'] = src;
    for (final entry in m.entries) {
      final k = entry.key.toString();
      if (k == 'src') continue;
      if (!options.iframePolicy.allowedAttrs.contains(k)) continue;
      final v = entry.value?.toString() ?? '';
      if (v.isEmpty && k != 'allowfullscreen') continue;
      node.attributes[k] = v;
    }
    if (options.iframePolicy.requireSandbox && !node.attributes.containsKey('sandbox')) {
      node.attributes['sandbox'] = options.iframePolicy.defaultSandbox.join(' ');
    }
    parent.append(node);
  }

  @override
  bool matches(dom.Element element) => element.localName == 'iframe';

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final src = element.attributes['src'] ?? '';
    if (src.isEmpty) return null;
    if (!options.iframePolicy.isUrlAllowed(src)) return null;
    final data = <String, String>{'src': src};
    for (final entry in element.attributes.entries) {
      final k = entry.key.toString();
      if (k == 'src') continue;
      if (!options.iframePolicy.allowedAttrs.contains(k)) continue;
      data[k] = entry.value;
    }
    return {
      'insert': {'iframe': data},
    };
  }
}
