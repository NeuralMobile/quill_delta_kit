import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../options.dart';
import '../util/dom_serializer.dart';
import '../util/html_writer.dart';
import 'embed_adapter.dart';

/// Table round-trip via custom embed.
///
/// Stores tables as `{"insert":{"table": <serialized HTML>}}`. Round-trip
/// preserves rows, cols, rowspan, colspan, cell formatting, header rows,
/// captions.
class TableAdapter extends EmbedAdapter {
  TableAdapter({this.allowedCellTags = const {'p', 'div', 'br', 'strong', 'em', 'u', 's', 'code', 'a', 'span', 'sub', 'sup'}});

  final Set<String> allowedCellTags;

  @override
  String get type => 'table';

  @override
  String? get css => '''
.ql-html-doc table { border-collapse: collapse; }
.ql-html-doc table td, .ql-html-doc table th { border: 1px solid #ccc; padding: 4px 8px; }
''';

  @override
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  }) {
    final html = value is String ? value : value?.toString() ?? '';
    if (html.isEmpty) return;
    final fragment = html_parser.parseFragment(html);
    final table = fragment.querySelector('table');
    if (table == null) return;
    // Re-serialize through our serializer for canonical output (sorted attrs,
    // entity encoding, void-element handling) then write as raw.
    writer.raw(DomSerializer().serialize(table));
  }

  @override
  bool matches(dom.Element element) => element.localName == 'table';

  @override
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options) {
    _sanitize(element);
    final serialized = DomSerializer().serialize(element);
    return {
      'insert': {'table': serialized},
    };
  }

  void _sanitize(dom.Element root) {
    final stack = <dom.Element>[root];
    while (stack.isNotEmpty) {
      final el = stack.removeLast();
      el.attributes.removeWhere((key, value) {
        final k = key.toString().toLowerCase();
        if (k.startsWith('on')) return true;
        if (k == 'href' || k == 'src') {
          final v = value.toLowerCase().trim();
          if (v.startsWith('javascript:') || v.startsWith('data:text/html')) return true;
        }
        return false;
      });
      for (final child in List<dom.Element>.from(el.children)) {
        if (child.localName == 'script' || child.localName == 'style') {
          child.remove();
          continue;
        }
        stack.add(child);
      }
    }
  }
}
