import 'package:quill_delta_core/quill_delta_core_test_contract.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';

void main() {
  // Markdown is approximate fidelity: inline color/font/size are dropped
  // because Markdown has no canonical syntax for them. Plain text and
  // structural attributes (bold, italic, links, lists, code blocks) survive.
  runConverterContract(
    label: 'quill_delta_markdown',
    encode: (delta) => MarkdownExporter().export(delta),
    decode: (text) => MarkdownImporter().import(text),
    fidelity: ConverterFidelity.approximate,
  );
}
