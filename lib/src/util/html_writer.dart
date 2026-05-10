import 'whitespace.dart';

/// Streaming HTML writer with canonical attribute ordering.
class HtmlWriter {
  final StringBuffer _buf = StringBuffer();

  void openTag(String name, {Map<String, String>? attrs, bool selfClose = false}) {
    _buf.write('<$name');
    if (attrs != null && attrs.isNotEmpty) {
      final keys = attrs.keys.toList()..sort();
      for (final k in keys) {
        final v = attrs[k]!;
        _buf.write(' $k="${Ws.encodeAttr(v)}"');
      }
    }
    _buf.write(selfClose ? '/>' : '>');
  }

  void closeTag(String name) => _buf.write('</$name>');

  void text(String s) => _buf.write(Ws.encodeText(s));

  void raw(String s) => _buf.write(s);

  @override
  String toString() => _buf.toString();
}
