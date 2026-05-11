import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// How strictly a format preserves the input.
enum ConverterFidelity {
  /// Round-trip is byte-for-byte identical at the Delta layer (e.g., HTML).
  lossless,

  /// Some attributes may be dropped/normalized (e.g., Markdown loses inline
  /// colors). Contract still asserts plain text survives.
  approximate,
}

/// Run the standard contract test suite for a converter pair.
void runConverterContract({
  required String label,
  required Future<String> Function(Delta delta) encode,
  required Future<Delta> Function(String text) decode,
  ConverterFidelity fidelity = ConverterFidelity.approximate,
  List<ContractFixture>? fixtures,
}) {
  final cases = fixtures ?? standardContractFixtures();

  group('contract: $label', () {
    test('encode + decode of empty delta is well-formed', () async {
      final empty = Delta()..insert('\n');
      final encoded = await encode(empty);
      expect(encoded, isA<String>());
      final back = await decode(encoded);
      expect(back, isA<Delta>());
    });

    for (final fx in cases) {
      group(fx.name, () {
        test('encode produces non-empty string', () async {
          final s = await encode(fx.delta);
          expect(s, isNotEmpty);
        });

        test('decode of encode returns a valid Delta', () async {
          final s = await encode(fx.delta);
          final back = await decode(s);
          expect(back.operations, isNotEmpty);
        });

        test('plain text survives round trip', () async {
          final s = await encode(fx.delta);
          final back = await decode(s);
          final expected = (fx.plainText ?? _plainTextOf(fx.delta));
          final actual = _plainTextOf(back);
          // Compare normalized: collapse whitespace, drop trailing newline.
          expect(_norm(actual), _norm(expected),
              reason: 'plain text must survive: ${fx.name}');
        });

        if (fidelity == ConverterFidelity.lossless) {
          test('lossless round trip — Delta equality', () async {
            final s = await encode(fx.delta);
            final back = await decode(s);
            expect(back.toJson(), fx.delta.toJson(),
                reason: 'lossless contract: ${fx.name}');
          });
        }
      });
    }
  });
}

String _plainTextOf(Delta d) {
  final buf = StringBuffer();
  for (final op in d.operations) {
    if (op.isInsert && op.data is String) {
      buf.write(op.data as String);
    }
  }
  return buf.toString();
}

String _norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
