import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';
import 'package:test/test.dart';

class _MentionAdapter extends MarkdownEmbedAdapter {
  @override
  String get type => 'mention';

  @override
  RegExp get pattern => RegExp(r'@(\w+)');

  @override
  void encodeMarkdown({
    required StringBuffer buf,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required MarkdownOptions options,
  }) {
    final v = value is Map ? value : const <String, dynamic>{};
    final char = v['denotationChar']?.toString() ?? '@';
    buf.write('$char${v['value']}');
  }

  @override
  Map<String, dynamic>? decodeMarkdown(
    String matched,
    MarkdownOptions options,
  ) =>
      {
        'insert': {
          'mention': {'value': matched, 'denotationChar': '@'},
        }
      };
}

void main() {
  group('MarkdownEmbedAdapter', () {
    test('format-native adapter preempts built-in encoding', () async {
      final reg = MarkdownEmbedRegistry(adapters: [_MentionAdapter()]);
      final exp = MarkdownExporter(embedRegistry: reg);
      final md = await exp.export(Delta()
        ..insert({
          'mention': {'value': 'alice', 'denotationChar': '@'}
        })
        ..insert('\n'));
      expect(md, '@alice\n');
    });

    test('without registry falls back to HTML comment passthrough', () async {
      final exp = const MarkdownExporter();
      final md = await exp.export(Delta()
        ..insert({
          'mention': {'value': 'alice'}
        })
        ..insert('\n'));
      expect(md, contains('<!-- mention -->'));
    });

    test('registry firstMatchIn returns first hit by start index', () {
      final reg = MarkdownEmbedRegistry(adapters: [_MentionAdapter()]);
      final hit =
          reg.firstMatchIn('hello @bob and @carol', const MarkdownOptions());
      expect(hit, isNotNull);
      expect(hit!.start, 6);
      expect(hit.end, 10);
      expect((hit.op['insert'] as Map)['mention'], isNotNull);
    });

    test('registry forType returns null for unknown type', () {
      final reg = MarkdownEmbedRegistry();
      expect(reg.forType('nope'), isNull);
    });

    test('EmbedAdapterBase exposes type and customSubType', () {
      final a = _MentionAdapter();
      expect(a.type, 'mention');
      expect(a.customSubType, isNull);
    });
  });
}
