import 'package:quill_delta_core/quill_delta_core_test_contract.dart';
import 'package:quill_delta_html/quill_delta_html.dart';

void main() {
  // The HTML codec is lossless: every standard fixture must round-trip
  // exactly through encode + decode at the Delta level.
  runConverterContract(
    label: 'quill_delta_html',
    encode: (delta) async => HtmlExporter(
      defaultOptions: const HtmlOptions(wrapDocument: false),
    ).export(delta),
    decode: (text) async => HtmlImporter(
      defaultOptions: const HtmlOptions(wrapDocument: false),
    ).import(text),
    fidelity: ConverterFidelity.lossless,
  );
}
