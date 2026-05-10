import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';
import 'package:test/test.dart';

/// Whitespace handling in markdown is fundamentally lossier than HTML or
/// docx: CommonMark collapses runs of ASCII spaces in normal paragraphs
/// and strips leading/trailing whitespace. These tests capture the actual
/// behaviour so regressions are caught even when the loss is expected.
///
/// Truly significant whitespace (NBSP, ZWSP, ZWNJ, ZWJ, etc.) survives
/// because the markdown source carries the bytes verbatim and the renderer
/// does not collapse them.
void main() {
  final exp = const MarkdownExporter();
  final imp = MarkdownImporter();

  String _plain(Delta d) => d.operations
      .where((op) => op.data is String)
      .map((op) => op.data as String)
      .join();

  group('exporter — significant unicode spaces survive verbatim', () {
    final cases = <String, String>{
      'NBSP': 'a b',
      'EN SPACE': 'a b',
      'EM SPACE': 'a b',
      'THIN SPACE': 'a b',
      'ZWSP': 'a​b',
      'ZWNJ': 'a‌b',
      'ZWJ': 'a‍b',
      'NARROW NBSP': 'a b',
      'IDEOGRAPHIC SPACE': 'a　b',
    };
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final md = await exp.export(Delta()..insert('${entry.value}\n'));
        // Source markdown contains the literal codepoint.
        expect(md, contains(entry.value));
      });
    }
  });

  group('exporter — ASCII space handling', () {
    test('multiple internal spaces survive in source markdown', () async {
      final md = await exp.export(Delta()..insert('a   b\n'));
      expect(md, contains('a   b'));
    });

    test('leading spaces survive in source markdown', () async {
      final md = await exp.export(Delta()..insert('   abc\n'));
      expect(md, contains('   abc'));
    });

    test('trailing spaces survive in source markdown', () async {
      final md = await exp.export(Delta()..insert('abc   \n'));
      // Trailing whitespace before newline.
      expect(md, contains('abc   '));
    });

    test('tab character survives in source markdown', () async {
      final md = await exp.export(Delta()..insert('a\tb\n'));
      expect(md, contains('a\tb'));
    });
  });

  group('round trip — significant unicode spaces preserved', () {
    final cases = <String, String>{
      'NBSP': 'a b',
      'EN SPACE': 'a b',
      'EM SPACE': 'a b',
      'ZWSP': 'a​b',
      'ZWNJ': 'a‌b',
      'ZWJ': 'a‍b',
      'NARROW NBSP': 'a b',
      'IDEOGRAPHIC SPACE': 'a　b',
    };
    for (final entry in cases.entries) {
      test('${entry.key} survives encode + decode', () async {
        final delta = Delta()..insert('${entry.value}\n');
        final md = await exp.export(delta);
        final back = await imp.import(md);
        // Round-tripped plain text contains the original codepoint.
        expect(_plain(back), contains(entry.value));
      });
    }
  });

  group('round trip — ASCII whitespace via HTML pivot', () {
    test('multiple internal spaces preserved through round trip', () async {
      // Although CommonMark would collapse spaces in pure markdown rendering,
      // our HTML pivot path preserves them via the decoder's text node.
      final md = await exp.export(Delta()..insert('a   b\n'));
      final back = await imp.import(md);
      expect(_plain(back), contains('a   b'));
    });

    test('leading spaces preserved through round trip', () async {
      final md = await exp.export(Delta()..insert('   abc\n'));
      final back = await imp.import(md);
      expect(_plain(back), contains('abc'));
    });
  });

  group('code block preserves whitespace verbatim', () {
    test('multiple spaces in code-block survive round trip', () async {
      final delta = Delta()
        ..insert('a   b')
        ..insert('\n', {'code-block': true});
      final md = await exp.export(delta);
      final back = await imp.import(md);
      expect(_plain(back), contains('a   b'));
    });

    test('leading whitespace in code-block survives round trip', () async {
      final delta = Delta()
        ..insert('   indented')
        ..insert('\n', {'code-block': true});
      final md = await exp.export(delta);
      final back = await imp.import(md);
      expect(_plain(back), contains('   indented'));
    });

    test('tab in code-block survives round trip', () async {
      final delta = Delta()
        ..insert('a\tb')
        ..insert('\n', {'code-block': true});
      final md = await exp.export(delta);
      final back = await imp.import(md);
      expect(_plain(back), contains('a\tb'));
    });
  });
}
