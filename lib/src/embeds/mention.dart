import 'package:html/dom.dart' as dom;

import '../options.dart';
import 'embed_adapter.dart';

/// Mention embed compatible with `quill-mention` JS module + TipTap mention + CKEditor mention.
class MentionAdapter extends EmbedAdapter {
  @override
  String get type => 'mention';

  @override
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final m = value is Map ? value : <String, dynamic>{};
    final id = m['id']?.toString() ?? '';
    final v = m['value']?.toString() ?? '';
    final char = m['denotationChar']?.toString() ?? '@';
    final el = dom.Element.tag('span')
      ..attributes['class'] = 'mention'
      ..attributes['data-mention-id'] = id
      ..attributes['data-mention-value'] = v
      ..attributes['data-denotation-char'] = char;
    el.append(dom.Text('$char$v'));
    parent.append(el);
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'span') return false;
    final cls = element.attributes['class'] ?? '';
    if (cls.split(' ').contains('mention')) return true;
    if (element.attributes['data-mention-id'] != null) return true;
    if (element.attributes['data-mention'] != null) return true; // CKEditor
    if (element.attributes['data-type'] == 'mention') return true; // TipTap
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final id = element.attributes['data-mention-id'] ?? element.attributes['data-id'] ?? '';
    var value = element.attributes['data-mention-value'] ?? element.attributes['data-label'] ?? '';
    final ckeditor = element.attributes['data-mention'];
    final char = element.attributes['data-denotation-char'] ??
        (ckeditor != null && ckeditor.isNotEmpty ? ckeditor.substring(0, 1) : '@');
    if (value.isEmpty) {
      value = element.text.startsWith(char) ? element.text.substring(char.length) : element.text;
    }
    return {
      'insert': {
        'mention': {
          'id': id,
          'value': value,
          'denotationChar': char,
        }
      }
    };
  }
}
