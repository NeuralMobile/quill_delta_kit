import 'dart:convert';

import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

/// Last-resort adapter: encode any unknown embed type as a
/// `<span data-quill-unknown="<base64-json>">`, decode such spans back to
/// their original Delta op. Survives unknown editors.
class PassthroughAdapter extends EmbedAdapter {
  @override
  String get type => '__passthrough__';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final payload = jsonEncode({
      'data': value,
      if (siblingAttrs != null) 'attributes': siblingAttrs,
    });
    final encoded = base64Url.encode(utf8.encode(payload));
    writer.open('span', {'data-quill-unknown': encoded});
    writer.close('span');
  }

  @override
  bool matches(dom.Element element) =>
      element.localName == 'span' &&
      element.attributes.containsKey('data-quill-unknown');

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final encoded = element.attributes['data-quill-unknown'];
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final json = utf8.decode(base64Url.decode(encoded));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return {
        'insert': decoded['data'],
        if (decoded['attributes'] != null) 'attributes': decoded['attributes'],
      };
    } on FormatException {
      return null;
    }
  }
}
