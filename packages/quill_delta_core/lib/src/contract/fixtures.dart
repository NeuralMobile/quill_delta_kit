import 'package:dart_quill_delta/dart_quill_delta.dart';

/// One named Delta input used by the converter contract.
class ContractFixture {
  const ContractFixture(this.name, this.delta, {this.plainText});

  final String name;
  final Delta delta;

  /// The plain-text content that every format must preserve through
  /// encode + decode (modulo trailing newline normalization). When null,
  /// the contract derives it from inserted strings in [delta].
  final String? plainText;
}

/// Standard fixture set. Every format runs against these.
List<ContractFixture> standardContractFixtures() => [
      ContractFixture(
        'plain paragraph',
        Delta()..insert('Hello world\n'),
        plainText: 'Hello world',
      ),
      ContractFixture(
        'bold + italic inline',
        Delta()
          ..insert('This is ')
          ..insert('bold', {'bold': true})
          ..insert(' and ')
          ..insert('italic', {'italic': true})
          ..insert('.\n'),
        plainText: 'This is bold and italic.',
      ),
      ContractFixture(
        'h1 heading',
        Delta()
          ..insert('Title')
          ..insert('\n', {'header': 1}),
        plainText: 'Title',
      ),
      ContractFixture(
        'bullet list',
        Delta()
          ..insert('one')
          ..insert('\n', {'list': 'bullet'})
          ..insert('two')
          ..insert('\n', {'list': 'bullet'}),
        plainText: 'one two',
      ),
      ContractFixture(
        'ordered list nested',
        Delta()
          ..insert('a')
          ..insert('\n', {'list': 'ordered'})
          ..insert('b')
          ..insert('\n', {'list': 'ordered', 'indent': 1})
          ..insert('c')
          ..insert('\n', {'list': 'ordered'}),
        plainText: 'a b c',
      ),
      ContractFixture(
        'code block',
        Delta()
          ..insert('print("hi")')
          ..insert('\n', {'code-block': true}),
        plainText: 'print("hi")',
      ),
      ContractFixture(
        'link',
        Delta()
          ..insert('see ')
          ..insert('site', {'link': 'https://example.com'})
          ..insert('.\n'),
        plainText: 'see site.',
      ),
      ContractFixture(
        'blockquote',
        Delta()
          ..insert('quoted')
          ..insert('\n', {'blockquote': true}),
        plainText: 'quoted',
      ),
    ];
