import 'whitespace.dart';

/// Streaming HTML writer used by the encoder pipeline.
///
/// Replaces the dom.Element + DomSerializer round-trip that the old encoder
/// used: encoder code calls [open]/[close]/[voidEl]/[text]/[raw] in document
/// order and the writer accumulates the final string.
///
/// Attribute output order: when [open] / [voidEl] are called with a Map, keys
/// are sorted alphabetically for canonical / diffable output (matches what
/// DomSerializer produced previously).
class HtmlWriter {
  final StringBuffer _buf = StringBuffer();

  /// HTML5 void elements emit without a closing slash: `<br>`, `<hr>`,
  /// `<img src="x">` etc.
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

  /// Write an opening tag. For void elements use [voidEl].
  void open(String name, [Map<String, String>? attrs]) {
    _buf.write('<');
    _buf.write(name);
    _writeAttrs(attrs);
    _buf.write('>');
  }

  /// Write a closing tag.
  void close(String name) {
    _buf.write('</');
    _buf.write(name);
    _buf.write('>');
  }

  /// Write a self-contained void element (`<br>`, `<hr>`, `<img>`, etc.).
  void voidEl(String name, [Map<String, String>? attrs]) {
    _buf.write('<');
    _buf.write(name);
    _writeAttrs(attrs);
    _buf.write('>');
  }

  /// Write text content with whitespace + entity encoding.
  void text(String s) {
    if (s.isEmpty) return;
    _buf.write(Ws.encodeText(s));
  }

  /// Write a raw HTML fragment without escaping. Caller is responsible for
  /// safety (used for already-sanitized HTML such as table payloads).
  void raw(String s) => _buf.write(s);

  /// Returns true if [name] is an HTML5 void element.
  static bool isVoid(String name) => _voidElements.contains(name);

  void _writeAttrs(Map<String, String>? attrs) {
    if (attrs == null || attrs.isEmpty) return;
    if (attrs.length == 1) {
      final entry = attrs.entries.first;
      _buf.write(' ');
      _buf.write(entry.key);
      _buf.write('="');
      _buf.write(Ws.encodeAttr(entry.value));
      _buf.write('"');
      return;
    }
    final keys = attrs.keys.toList()..sort();
    for (final k in keys) {
      _buf.write(' ');
      _buf.write(k);
      _buf.write('="');
      _buf.write(Ws.encodeAttr(attrs[k]!));
      _buf.write('"');
    }
  }

  @override
  String toString() => _buf.toString();
}
