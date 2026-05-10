import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

/// Generic iframe round-trip via flutter_quill custom embed wrapper.
/// Runs LAST in dispatch order so provider-specific adapters (YouTube/Vimeo) win.
class IframeAdapter extends EmbedAdapter {
  @override
  String get type => 'iframe';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final m = value is Map ? value : <String, dynamic>{};
    final src = m['src']?.toString() ?? '';
    if (src.isEmpty) return;
    if (!options.iframePolicy.isUrlAllowed(src)) return;

    final attrs = <String, String>{'src': src};
    for (final entry in m.entries) {
      final k = entry.key.toString();
      if (k == 'src') continue;
      if (!options.iframePolicy.allowedAttrs.contains(k)) continue;
      final v = entry.value?.toString() ?? '';
      if (v.isEmpty && k != 'allowfullscreen') continue;
      attrs[k] = v;
    }
    if (options.iframePolicy.requireSandbox && !attrs.containsKey('sandbox')) {
      attrs['sandbox'] = options.iframePolicy.defaultSandbox.join(' ');
    }
    writer.open('iframe', attrs);
    writer.close('iframe');
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
