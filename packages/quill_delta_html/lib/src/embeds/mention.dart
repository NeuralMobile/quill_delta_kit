import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

/// Mention embed compatible with `quill-mention` JS module + TipTap mention + CKEditor mention.
class MentionAdapter extends EmbedAdapter {
  @override
  String get type => 'mention';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final m = value is Map ? value : <String, dynamic>{};
    final id = m['id']?.toString() ?? '';
    final v = m['value']?.toString() ?? '';
    final char = m['denotationChar']?.toString() ?? '@';
    writer.open('span', {
      'class': 'mention',
      'data-denotation-char': char,
      'data-mention-id': id,
      'data-mention-value': v,
    });
    writer.text('$char$v');
    writer.close('span');
  }

  @override
  bool matches(dom.Element element) {
    if (element.localName != 'span') return false;
    final cls = element.attributes['class'] ?? '';
    if (cls.split(' ').contains('mention')) return true;
    if (element.attributes['data-mention-id'] != null) return true;
    if (element.attributes['data-mention'] != null) return true;
    if (element.attributes['data-type'] == 'mention') return true;
    return false;
  }

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    final id = element.attributes['data-mention-id'] ??
        element.attributes['data-id'] ??
        '';
    var value = element.attributes['data-mention-value'] ??
        element.attributes['data-label'] ??
        '';
    final ckeditor = element.attributes['data-mention'];
    final char = element.attributes['data-denotation-char'] ??
        (ckeditor != null && ckeditor.isNotEmpty
            ? ckeditor.substring(0, 1)
            : '@');
    if (value.isEmpty) {
      value = element.text.startsWith(char)
          ? element.text.substring(char.length)
          : element.text;
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
