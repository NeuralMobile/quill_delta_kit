import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:test/test.dart';

/// Build a Delta from a list of op JSON maps.
Delta deltaOf(List<Map<String, dynamic>> ops) => Delta.fromJson(ops);

/// Re-push every op into a fresh Delta so adjacent same-attr inserts merge.
Delta normalize(Delta d) {
  final out = Delta();
  for (final op in d.toList()) {
    if (!op.isInsert) continue;
    out.insert(op.data, op.attributes);
  }
  return out;
}

/// Default fragment-only codec for terse goldens.
QuillHtmlCodec frag({List<EmbedAdapter> adapters = const []}) => QuillHtmlCodec(
      adapters: adapters,
      options: const QuillHtmlOptions(wrapDocument: false),
    );

void expectDeltasEqual(Delta actual, Delta expected, {Object? reason}) {
  expect(actual.toJson(), expected.toJson(), reason: reason?.toString());
}
