import 'package:html/dom.dart' as dom;

import 'whitespace.dart';

/// Serialize a `package:html` element tree using our whitespace-preserving
/// text encoder. Attributes are alpha-sorted for canonical output.
///
/// Void elements emit as `<x />`-less self-closing per HTML5.
class DomSerializer {
  DomSerializer({this.skipRoot = false});

  /// If true, do not emit the root element's open/close tags — only its children.
  final bool skipRoot;

  static const _voidElements = <String>{
    'area',
    'base',
    'br',
    'col',
    'embed',
    'hr',
    'img',
    'input',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  };

  String serialize(dom.Element root) {
    final out = StringBuffer();
    if (skipRoot) {
      for (final n in root.nodes) {
        _writeNode(n, out);
      }
    } else {
      _writeElement(root, out);
    }
    return out.toString();
  }

  void _writeNode(dom.Node node, StringBuffer out) {
    if (node is dom.Text) {
      out.write(Ws.encodeText(node.text));
    } else if (node is dom.Element) {
      _writeElement(node, out);
    } else if (node is dom.Comment) {
      out.write('<!--${node.data}-->');
    }
  }

  void _writeElement(dom.Element el, StringBuffer out) {
    final name = el.localName ?? '';
    out.write('<$name');
    final attrs = el.attributes;
    if (attrs.length == 1) {
      final entry = attrs.entries.first;
      out.write(' ${entry.key}="${Ws.encodeAttr(entry.value.toString())}"');
    } else if (attrs.length > 1) {
      final keys = attrs.keys.map((k) => k.toString()).toList()..sort();
      for (final k in keys) {
        out.write(' $k="${Ws.encodeAttr(attrs[k]?.toString() ?? '')}"');
      }
    }
    if (_voidElements.contains(name)) {
      out.write('>');
      return;
    }
    out.write('>');
    for (final n in el.nodes) {
      _writeNode(n, out);
    }
    out.write('</$name>');
  }
}
