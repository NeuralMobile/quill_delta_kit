import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';
import 'package:test/test.dart';

void main() {
  final exp = const MarkdownExporter();
  final imp = MarkdownImporter();

  group('MarkdownExporter inline coverage', () {
    test('strike-through', () async {
      final md = await exp.export(Delta()
        ..insert('a ')
        ..insert('b', {'strike': true})
        ..insert('\n'));
      expect(md, 'a ~~b~~\n');
    });

    test('inline code wraps in backticks', () async {
      final md = await exp.export(Delta()
        ..insert('say ')
        ..insert('hello()', {'code': true})
        ..insert('\n'));
      expect(md, 'say `hello\\(\\)`\n');
    });

    test('bold + italic combined', () async {
      final md = await exp.export(Delta()
        ..insert('x', {'bold': true, 'italic': true})
        ..insert('\n'));
      expect(md, '***x***\n');
    });

    test('link with bold inner text', () async {
      final md = await exp.export(Delta()
        ..insert('here', {'bold': true, 'link': 'https://x.test'})
        ..insert('\n'));
      expect(md, '[**here**](https://x.test)\n');
    });

    test('escapes brackets and parens', () async {
      final md = await exp.export(Delta()..insert('a[b](c)\n'));
      expect(md, 'a\\[b\\]\\(c\\)\n');
    });

    test('escapes hash, plus, bang, pipe in plain text', () async {
      final md = await exp.export(Delta()..insert('# +!|<>\n'));
      expect(md, '\\# \\+\\!\\|\\<\\>\n');
    });
  });

  group('MarkdownExporter list coverage', () {
    test('three-level nested bullet', () async {
      final md = await exp.export(Delta()
        ..insert('a')
        ..insert('\n', {'list': 'bullet'})
        ..insert('b')
        ..insert('\n', {'list': 'bullet', 'indent': 1})
        ..insert('c')
        ..insert('\n', {'list': 'bullet', 'indent': 2}));
      expect(md, '- a\n  - b\n    - c\n');
    });

    test('ordered list de-nest resets', () async {
      final md = await exp.export(Delta()
        ..insert('a')
        ..insert('\n', {'list': 'ordered'})
        ..insert('b')
        ..insert('\n', {'list': 'ordered', 'indent': 1})
        ..insert('c')
        ..insert('\n', {'list': 'ordered', 'indent': 1})
        ..insert('d')
        ..insert('\n', {'list': 'ordered'}));
      expect(md, '1. a\n  1. b\n  2. c\n2. d\n');
    });

    test('checked + unchecked items', () async {
      final md = await exp.export(Delta()
        ..insert('done')
        ..insert('\n', {'list': 'checked'})
        ..insert('todo')
        ..insert('\n', {'list': 'unchecked'}));
      expect(md, '- [x] done\n- [ ] todo\n');
    });
  });

  group('MarkdownExporter block coverage', () {
    test('blockquote multiple lines', () async {
      final md = await exp.export(Delta()
        ..insert('a')
        ..insert('\n', {'blockquote': true})
        ..insert('b')
        ..insert('\n', {'blockquote': true}));
      expect(md, '> a\n> b\n');
    });

    test('all six headings', () async {
      for (var i = 1; i <= 6; i++) {
        final md = await exp.export(Delta()
          ..insert('H$i')
          ..insert('\n', {'header': i}));
        expect(md, '${'#' * i} H$i\n');
      }
    });

    test('code block without language', () async {
      final md = await exp.export(Delta()
        ..insert('plain')
        ..insert('\n', {'code-block': true}));
      expect(md, '```\nplain\n```\n');
    });

    test('code block multi-line', () async {
      final md = await exp.export(Delta()
        ..insert('a')
        ..insert('\n', {'code-block': true})
        ..insert('b')
        ..insert('\n', {'code-block': true})
        ..insert('c')
        ..insert('\n', {'code-block': true}));
      expect(md, '```\na\nb\nc\n```\n');
    });

    test('image embed', () async {
      final md = await exp.export(Delta()
        ..insert({'image': 'https://x.test/a.png'})
        ..insert('\n'));
      expect(md, contains('![](https://x.test/a.png)'));
    });

    test('divider embed', () async {
      final md = await exp.export(Delta()
        ..insert({'divider': true})
        ..insert('\n'));
      expect(md, contains('---'));
    });

    test('mixed document — heading, paragraph, list, code', () async {
      final md = await exp.export(Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('Body para.\n')
        ..insert('first')
        ..insert('\n', {'list': 'bullet'})
        ..insert('second')
        ..insert('\n', {'list': 'bullet'})
        ..insert('print')
        ..insert('\n', {'code-block': 'dart'}));
      expect(md,
          '# Title\n\nBody para.\n\n- first\n- second\n\n```dart\nprint\n```\n');
    });
  });

  group('MarkdownImporter coverage', () {
    test('all six headings', () async {
      for (var i = 1; i <= 6; i++) {
        final d = await imp.import('${'#' * i} H$i\n');
        expect(d.toJson(), [
          {'insert': 'H$i'},
          {
            'insert': '\n',
            'attributes': {'header': i}
          },
        ]);
      }
    });

    test('strike GFM', () async {
      final d = await imp.import('a ~~b~~\n');
      expect(d.toJson(), [
        {'insert': 'a '},
        {
          'insert': 'b',
          'attributes': {'strike': true}
        },
        {'insert': '\n'},
      ]);
    });

    test('inline code', () async {
      final d = await imp.import('say `hi`\n');
      final hasCode = d.operations.any((op) {
        final a = op.attributes;
        return a != null && a['code'] == true;
      });
      expect(hasCode, true);
    });

    test('autolink', () async {
      final d = await imp.import('see https://example.com\n');
      final linkOp = d.operations.firstWhere(
        (op) => op.attributes != null && op.attributes!['link'] != null,
        orElse: () => Operation.insert(''),
      );
      expect(linkOp.attributes?['link'], contains('example.com'));
    });

    test('blockquote', () async {
      final d = await imp.import('> quoted\n');
      final hasQuote = d.operations.any((op) {
        final a = op.attributes;
        return a != null && a['blockquote'] == true;
      });
      expect(hasQuote, true);
    });

    test('reference-style link', () async {
      final d = await imp.import('[ref][1]\n\n[1]: https://x.test\n');
      final linkOp = d.operations.firstWhere(
        (op) => op.attributes != null && op.attributes!['link'] != null,
        orElse: () => Operation.insert(''),
      );
      expect(linkOp.attributes?['link'], 'https://x.test');
    });
  });

  group('round-trip plain text fidelity', () {
    test('preserves exotic punctuation through both directions', () async {
      const text = 'Hello — world… "quoted" 🌍';
      final md = await exp.export(Delta()..insert('$text\n'));
      final back = await imp.import(md);
      final restored = back.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(restored.trim(), text);
    });

    test('multi-paragraph round-trip', () async {
      final delta = Delta()
        ..insert('Para one.\n')
        ..insert('Para two.\n')
        ..insert('Para three.\n');
      final md = await exp.export(delta);
      final back = await imp.import(md);
      final text = back.operations
          .where((op) => op.data is String)
          .map((op) => op.data as String)
          .join();
      expect(text, contains('Para one'));
      expect(text, contains('Para two'));
      expect(text, contains('Para three'));
    });
  });
}
