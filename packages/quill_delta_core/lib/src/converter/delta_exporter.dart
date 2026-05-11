import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'converter_options.dart';

/// Abstract exporter: converts a [Delta] into [TOut] target data.
///
/// Type parameters:
/// - [TOut]  — native Dart type for the output data. [String] for text
///             formats, [List<int>] for binary formats.
/// - [TOpts] — the [ConverterOptions] subclass that controls the conversion.
abstract class DeltaExporter<TOut, TOpts extends ConverterOptions> {
  const DeltaExporter();

  /// Short canonical name. Must match the paired [DeltaImporter.format].
  String get format;

  /// Primary MIME type for the output data.
  String get mimeType;

  /// Primary file extension without leading dot.
  String get extension;

  /// Options used when the caller passes none.
  TOpts get defaultOptions;

  /// Convert [delta] to [TOut]. When [options] is omitted, [defaultOptions]
  /// is used.
  ///
  /// Throws [ExportException] when serialisation fails.
  Future<TOut> export(Delta delta, {TOpts? options});
}
