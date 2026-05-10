import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_markdown/quill_delta_markdown.dart';
import 'package:test/test.dart';

void main() {
  final exp = const MarkdownExporter();
  final imp = MarkdownImporter();

  group('MarkdownExporter goldens', () {
    test('plain paragraph', () async {
      final md = await exp.export(Delta()..insert('Hello\n'));
      expect(md, 'Hello\n');
    });

    test('bold + italic', () async {
      final md = await exp.export(Delta()
        ..insert('a ')
        ..insert('b', {'bold': true})
        ..insert(' ')
        ..insert('c', {'italic': true})
        ..insert('\n'));
      expect(md, 'a **b** *c*\n');
    });

    test('h1 + paragraph', () async {
      final md = await exp.export(Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('Body\n'));
      expect(md, '# Title\n\nBody\n');
    });

    test('code block with language', () async {
      final md = await exp.export(Delta()
        ..insert('print("x")')
        ..insert('\n', {'code-block': 'dart'}));
      expect(md, '```dart\nprint("x")\n```\n');
    });

    test('bullet list nested', () async {
      final md = await exp.export(Delta()
        ..insert('a')
        ..insert('\n', {'list': 'bullet'})
        ..insert('b')
        ..insert('\n', {'list': 'bullet', 'indent': 1}));
      expect(md, '- a\n  - b\n');
    });

    test('ordered list resets numbering by depth', () async {
      final md = await exp.export(Delta()
        ..insert('a')
        ..insert('\n', {'list': 'ordered'})
        ..insert('b')
        ..insert('\n', {'list': 'ordered'})
        ..insert('c')
        ..insert('\n', {'list': 'ordered', 'indent': 1}));
      expect(md, '1. a\n2. b\n  1. c\n');
    });

    test('link', () async {
      final md = await exp.export(Delta()
        ..insert('see ')
        ..insert('here', {'link': 'https://x.test'})
        ..insert('.\n'));
      expect(md, 'see [here](https://x.test).\n');
    });

    test('escapes markdown special characters in plain text', () async {
      final md = await exp.export(Delta()..insert('a*b_c\n'));
      expect(md, 'a\\*b\\_c\n');
    });
  });

  group('MarkdownImporter goldens', () {
    test('plain paragraph', () async {
      final d = await imp.import('Hello\n');
      expect(d.toJson(), [
        {'insert': 'Hello\n'},
      ]);
    });

    test('h1', () async {
      final d = await imp.import('# Title\n');
      expect(d.toJson(), [
        {'insert': 'Title'},
        {'insert': '\n', 'attributes': {'header': 1}},
      ]);
    });

    test('bold + italic', () async {
      final d = await imp.import('a **b** *c*\n');
      expect(d.toJson(), [
        {'insert': 'a '},
        {'insert': 'b', 'attributes': {'bold': true}},
        {'insert': ' '},
        {'insert': 'c', 'attributes': {'italic': true}},
        {'insert': '\n'},
      ]);
    });

    test('fenced code block', () async {
      final d = await imp.import('```dart\nprint("x")\n```\n');
      expect(d.toJson(), [
        {'insert': 'print("x")'},
        {'insert': '\n', 'attributes': {'code-block': 'dart'}},
      ]);
    });
  });

  group('format metadata', () {
    test('importer', () {
      expect(imp.format, 'markdown');
      expect(imp.extensions, contains('md'));
    });
    test('exporter', () {
      expect(exp.format, 'markdown');
      expect(exp.extension, 'md');
    });
  });
}
