// Quill Delta <-> DOCX round-trip example.
//
// Writes a sample document to `out.docx`, then reads it back into a Delta
// to demonstrate the import side.
// Run with `dart run example/quill_delta_docx_example.dart`.
import 'dart:io';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';

void main() async {
  final delta = Delta()
    ..insert('Heading\n', {'header': 1})
    ..insert('Body text with ')
    ..insert('bold', {'bold': true})
    ..insert(' and ')
    ..insert('italic', {'italic': true})
    ..insert(' runs.\n');

  // Delta -> .docx bytes.
  final bytes = await const DocxExporter().export(delta);
  await File('out.docx').writeAsBytes(bytes);
  print('Wrote out.docx (${bytes.length} bytes)');

  // .docx -> Delta.
  final roundtrip = await DocxImporter().import(bytes);
  print('Imported ${roundtrip.operations.length} ops');
}
