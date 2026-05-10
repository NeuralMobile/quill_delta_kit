import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'converter_options.dart';

/// Abstract importer: converts [TIn] source data into a [Delta].
///
/// Type parameters:
/// - [TIn]   — native Dart type for the source data. [String] for text
///             formats (HTML, Markdown), [List<int>] for binary formats
///             (Docx, PDF), or a typed model class for strongly-typed
///             intermediate representations.
/// - [TOpts] — the [ConverterOptions] subclass that controls the conversion.
///
/// All conversion is async-only so implementors can spawn an isolate for
/// heavy parsing, fetch remote resources, or cross a platform channel
/// without blocking the main thread.
abstract class DeltaImporter<TIn, TOpts extends ConverterOptions> {
  const DeltaImporter();

  /// Short canonical name. Lower-case, no spaces. Examples: 'html',
  /// 'markdown', 'docx', 'pdf'.
  String get format;

  /// MIME types this importer accepts.
  Set<String> get mimeTypes;

  /// File extensions this importer claims, without leading dot.
  Set<String> get extensions;

  /// Options used when the caller passes none.
  TOpts get defaultOptions;

  /// Convert [input] to a [Delta]. When [options] is omitted,
  /// [defaultOptions] is used.
  ///
  /// Throws [FormatException] if [input] cannot be parsed.
  Future<Delta> import(TIn input, {TOpts? options});
}
