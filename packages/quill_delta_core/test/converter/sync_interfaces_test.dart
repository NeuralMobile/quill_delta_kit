import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:test/test.dart';

class _FakeSyncImporter implements SyncDeltaImporter<String, HtmlOptions> {
  @override
  String get format => 'fake';
  @override
  Set<String> get mimeTypes => const {};
  @override
  Set<String> get extensions => const {};
  @override
  HtmlOptions get defaultOptions => const HtmlOptions();
  @override
  Future<Delta> import(String input, {HtmlOptions? options}) async =>
      importSync(input);
  @override
  Delta importSync(String input, {HtmlOptions? options}) =>
      Delta()..insert('x');
}

void main() {
  test('SyncDeltaImporter is a DeltaImporter subtype', () {
    final i = _FakeSyncImporter();
    expect(i, isA<DeltaImporter<String, HtmlOptions>>());
    expect(i.importSync('hi').toJson(), isNotEmpty);
  });
}
