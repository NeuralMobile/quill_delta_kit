/// Shared test contract that every concrete [DeltaImporter] / [DeltaExporter]
/// pair should pass.
///
/// Format packages consume this in their own `test/` directory:
///
/// ```dart
/// import 'package:quill_delta_core/quill_delta_core_test_contract.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   runConverterContract(
///     label: 'quill_delta_html',
///     encode: (delta) async => HtmlExporter().export(delta),
///     decode: (text) async => HtmlImporter().import(text),
///     fidelity: ConverterFidelity.lossless, // or .approximate
///   );
/// }
/// ```
///
/// The contract guarantees only structural sanity (output is non-empty,
/// decode returns a Delta, basic text survives). Formats that need stricter
/// goldens (HTML's byte-for-byte round trip) layer additional tests on top.
library quill_delta_core_test_contract;

export 'src/contract/converter_contract.dart';
export 'src/contract/fixtures.dart';
