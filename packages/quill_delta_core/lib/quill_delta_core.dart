/// Core types and Delta utilities for the quill_delta_* converter family.
///
/// Includes:
///   - Quill attribute schema (`Attr`)
///   - CSS canonicalization (`CssColor`, `QuillSize`)
///   - Delta line-splitting primitives (`Line`, `InlineOp`, `splitIntoLines`)
///   - Multi-format converter abstractions (`DeltaImporter`, `DeltaExporter`,
///     `ConverterRegistry`, `HtmlPivotImporter`)
///   - Per-format option bags (`HtmlOptions`, `MarkdownOptions`,
///     `DocxOptions`)
library quill_delta_core;

export 'src/converter/converter_options.dart';
export 'src/converter/converter_registry.dart' show ConverterRegistry, sniffMagicBytes, sniffExtension;
export 'src/converter/delta_exporter.dart';
export 'src/converter/delta_importer.dart';
export 'src/converter/embed_adapter_base.dart';
export 'src/converter/html_pivot_importer.dart';
export 'src/converter/options/docx_options.dart';
export 'src/converter/options/html_options.dart';
export 'src/converter/options/markdown_options.dart';
export 'src/css/color.dart';
export 'src/css/size.dart';
export 'src/delta/line_splitter.dart';
export 'src/errors.dart';
export 'src/schema/attributes.dart';
