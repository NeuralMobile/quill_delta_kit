import 'package:quill_delta_core/quill_delta_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeltaConversionException hierarchy', () {
    test('every leaf class is a DeltaConversionException', () {
      expect(
        const ImportException('html', 'x'),
        isA<DeltaConversionException>(),
      );
      expect(
        const ExportException('html', 'x'),
        isA<DeltaConversionException>(),
      );
      expect(
        const MalformedDocumentException('html', 'x'),
        isA<DeltaConversionException>(),
      );
      expect(
        UnsupportedFormatException('pdf'),
        isA<DeltaConversionException>(),
      );
      expect(
        const ConverterNotFound('x'),
        isA<DeltaConversionException>(),
      );
    });

    test('MalformedDocumentException is an ImportException', () {
      expect(
        const MalformedDocumentException('docx', 'broken zip'),
        isA<ImportException>(),
      );
    });

    test('exposes format on typed errors', () {
      const e = ImportException('markdown', 'oops');
      expect(e.format, 'markdown');
      const e2 = MalformedDocumentException('docx', 'oops');
      expect(e2.format, 'docx');
      const e3 = ExportException('html', 'oops');
      expect(e3.format, 'html');
      expect(UnsupportedFormatException('pdf').format, 'pdf');
    });

    test('preserves wrapped cause + stack', () {
      final cause = StateError('inner');
      final st = StackTrace.current;
      final e = ImportException('html', 'wrap', cause: cause, causeStack: st);
      expect(e.cause, cause);
      expect(e.causeStack, st);
      expect(e.toString(), contains('cause:'));
      expect(e.toString(), contains('html'));
    });

    test('exhaustive switch over sealed class compiles', () {
      const errors = <DeltaConversionException>[
        ImportException('html', 'x'),
        ExportException('html', 'x'),
        MalformedDocumentException('html', 'x'),
        ConverterNotFound('x'),
      ];
      for (final e in errors) {
        final tag = switch (e) {
          MalformedDocumentException() => 'malformed',
          ImportException() => 'import',
          ExportException() => 'export',
          UnsupportedFormatException() => 'unsupported',
          ConverterNotFound() => 'notfound',
        };
        expect(tag.isNotEmpty, true);
      }
    });

    test('ConverterRegistry throws ConverterNotFound on unknown format', () {
      final reg = ConverterRegistry();
      expect(
        () => reg.importer<String, ConverterOptions>('does-not-exist'),
        throwsA(isA<ConverterNotFound>()),
      );
    });
  });
}
