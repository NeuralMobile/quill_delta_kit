import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_docx/quill_delta_docx.dart';
import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';
import 'package:test/test.dart';

/// Asserts each text fragment that any reasonable consumer would expect to
/// survive a Delta -> format -> Delta round trip.
///
/// Three formats round-trip via Delta (html, markdown, docx). PDF is one-way
/// and has its own per-format whitespace tests.
void main() {
  String plain(Delta d) => d.operations.where((op) => op.data is String).map((op) => op.data as String).join();

  Future<Delta> viaHtml(Delta d) async {
    final html = await HtmlExporter(
      defaultOptions: const HtmlOptions(wrapDocument: false),
    ).export(d);
    return HtmlImporter(
      defaultOptions: const HtmlOptions(wrapDocument: false),
    ).import(html);
  }

  Future<Delta> viaMarkdown(Delta d) async {
    final md = await const MarkdownExporter().export(d);
    return MarkdownImporter().import(md);
  }

  Future<Delta> viaDocx(Delta d) async {
    final bytes = await const DocxExporter().export(d);
    return DocxImporter().import(bytes);
  }

  // Universally-preserved cases — html, markdown, docx all keep these.
  final universal = <String, String>{
    'NBSP': 'a b',
    'EN SPACE': 'a b',
    'EM SPACE': 'a b',
    'ZWSP': 'a​b',
    'ZWNJ': 'a‌b',
    'ZWJ': 'a‍b',
    'NARROW NBSP': 'a b',
    'IDEOGRAPHIC SPACE': 'a　b',
    'multi-space': 'a   b',
    'tab': 'a\tb',
  };

  group('cross-format whitespace preservation (universal cases)', () {
    for (final entry in universal.entries) {
      group(entry.key, () {
        final delta = Delta()..insert('${entry.value}\n');

        test('html round trip', () async {
          expect(plain(await viaHtml(delta)), contains(entry.value));
        });

        test('markdown round trip', () async {
          expect(plain(await viaMarkdown(delta)), contains(entry.value));
        });

        test('docx round trip', () async {
          expect(plain(await viaDocx(delta)), contains(entry.value));
        });
      });
    }
  });

  // Markdown-lossy cases: leading/trailing ASCII spaces are stripped by the
  // CommonMark parser. HTML and docx preserve them. Document the loss
  // explicitly so any future change to markdown's whitespace handling is
  // caught by the test rather than silently regressing other formats.
  group('leading/trailing ASCII spaces — html + docx preserve, markdown strips', () {
    final cases = <String, String>{
      'leading-space': '   abc',
      'trailing-space': 'abc   ',
    };

    for (final entry in cases.entries) {
      group(entry.key, () {
        final delta = Delta()..insert('${entry.value}\n');

        test('html round trip preserves', () async {
          expect(plain(await viaHtml(delta)), contains(entry.value));
        });

        test('docx round trip preserves', () async {
          expect(plain(await viaDocx(delta)), contains(entry.value));
        });

        test('markdown round trip strips edge spaces (CommonMark)', () async {
          final back = plain(await viaMarkdown(delta));
          expect(back, contains('abc'));
          // The trimmed-edge whitespace is gone after markdown round trip.
          expect(back.contains(entry.value), false);
        });
      });
    }
  });

  group('whitespace inside code-block survives all three formats', () {
    final cases = <String, String>{
      'multi-space': 'a   b   c',
      'tab': 'def\tx():',
      'leading-space': '    indented',
      'NBSP': 'before after',
    };

    for (final entry in cases.entries) {
      group(entry.key, () {
        final delta = Delta()
          ..insert(entry.value)
          ..insert('\n', {'code-block': true});

        test('html', () async {
          expect(plain(await viaHtml(delta)), contains(entry.value));
        });

        test('markdown', () async {
          expect(plain(await viaMarkdown(delta)), contains(entry.value));
        });

        test('docx', () async {
          expect(plain(await viaDocx(delta)), contains(entry.value));
        });
      });
    }
  });

  group('whitespace inside formatted runs', () {
    test('multi-space inside bold survives html', () async {
      final delta = Delta()
        ..insert('a   b', {'bold': true})
        ..insert('\n');
      final back = await viaHtml(delta);
      final boldOp = back.operations.firstWhere(
        (op) => op.attributes != null && op.attributes!['bold'] == true,
        orElse: () => Operation.insert(''),
      );
      expect(boldOp.data, 'a   b');
    });

    test('multi-space inside bold survives docx', () async {
      final delta = Delta()
        ..insert('a   b', {'bold': true})
        ..insert('\n');
      final back = await viaDocx(delta);
      final boldOp = back.operations.firstWhere(
        (op) => op.attributes != null && op.attributes!['bold'] == true,
        orElse: () => Operation.insert(''),
      );
      expect(boldOp.data, 'a   b');
    });

    test('NBSP inside italic survives all three', () async {
      const text = 'a b';
      final delta = Delta()
        ..insert(text, {'italic': true})
        ..insert('\n');
      for (final via in [viaHtml, viaMarkdown, viaDocx]) {
        final back = await via(delta);
        expect(plain(back), contains(text));
      }
    });
  });
}
