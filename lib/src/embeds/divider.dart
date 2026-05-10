import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

class DividerAdapter extends EmbedAdapter {
  @override
  String get type => 'divider';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    parent.append(dom.Element.tag('hr'));
  }

  @override
  bool matches(dom.Element element) => element.localName == 'hr';

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    return {
      'insert': {'divider': true},
    };
  }
}
