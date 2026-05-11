// Quill Delta -> PDF export example.
//
// Writes a sample document to `out.pdf`. PDF -> Delta import is a stub in
// v0.1 and throws `UnsupportedFormatException`.
import 'dart:io';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_pdf/quill_delta_pdf.dart';

void main() async {
  final delta = Delta()
    ..insert('Title\n', {'header': 1})
    ..insert('A short paragraph with ')
    ..insert('bold', {'bold': true})
    ..insert(' and ')
    ..insert('italic', {'italic': true})
    ..insert(' inline runs.\n')
    ..insert('Line two.\n');

  final bytes = await const PdfExporter().export(delta);
  await File('out.pdf').writeAsBytes(bytes);
  print('Wrote out.pdf (${bytes.length} bytes)');
}
