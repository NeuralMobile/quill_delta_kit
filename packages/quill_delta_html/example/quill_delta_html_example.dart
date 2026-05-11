// Quill Delta <-> HTML round-trip example.
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';

void main() {
  final codec = QuillHtmlCodec();

  // Delta -> HTML.
  final delta = Delta()
    ..insert('Heading\n', {'header': 1})
    ..insert('Bold ', {'bold': true})
    ..insert('italic ', {'italic': true})
    ..insert('text.\n');
  final html = codec.encode(delta);
  print(html);

  // HTML -> Delta.
  final back = codec.decode(html);
  print(back.toJson());
}
