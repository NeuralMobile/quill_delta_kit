// Quill Delta <-> Markdown round-trip example.
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';

void main() async {
  // Markdown -> Delta.
  final delta = await MarkdownImporter().import(
    '# Hello\n\nThis is **bold** and *italic*.\n',
  );
  print('Delta: ${delta.toJson()}');

  // Delta -> Markdown.
  final reverse = Delta()
    ..insert('Title\n', {'header': 1})
    ..insert('Line one.\n');
  final md = await const MarkdownExporter().export(reverse);
  print('Markdown:\n$md');
}
