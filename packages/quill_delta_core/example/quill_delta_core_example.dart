// Minimal usage of `quill_delta_core`'s building blocks.
//
// Demonstrates:
// * Splitting a Delta into lines with `splitIntoLines`.
// * Registering a custom format in a `ConverterRegistry`.
// * Catching the typed `DeltaConversionException` family.
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

void main() async {
  final delta = Delta()
    ..insert('Hello\n', {'header': 1})
    ..insert('World\n');

  // Walk lines + block attrs.
  for (final line in splitIntoLines(delta)) {
    print('block=${line.blockAttrs} ops=${line.ops.length}');
  }

  // Register a tiny no-op exporter and round-trip through the registry.
  final reg = ConverterRegistry(exporters: [const _PlainTextExporter()]);
  final exporter = reg.exporter<String, ConverterOptions>('text');
  print(await exporter.export(delta));

  // Catch typed errors.
  try {
    reg.importer<String, ConverterOptions>('csv');
  } on ConverterNotFound catch (e) {
    print('caught: $e');
  }
}

final class _PlainTextExporter
    implements DeltaExporter<String, ConverterOptions> {
  const _PlainTextExporter();
  @override
  String get format => 'text';
  @override
  String get mimeType => 'text/plain';
  @override
  String get extension => 'txt';
  @override
  ConverterOptions get defaultOptions => const _TextOptions();
  @override
  Future<String> export(Delta delta, {ConverterOptions? options}) async {
    final buf = StringBuffer();
    for (final line in splitIntoLines(delta)) {
      for (final op in line.ops) {
        if (op.isText) buf.write(op.asText);
      }
      buf.writeln();
    }
    return buf.toString();
  }
}

class _TextOptions extends ConverterOptions {
  const _TextOptions();
}
