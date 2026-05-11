/// Typed exception hierarchy for the quill_delta_* converter family.
///
/// Every error raised inside an importer, exporter, or the
/// [ConverterRegistry] is a subtype of [DeltaConversionException]. Wrapper
/// integrations can therefore catch a single supertype and dispatch on the
/// concrete leaf class for user-friendly messaging.
library;

/// Base type for every conversion error. Sealed: leaf classes enumerate
/// every error category we raise (catching new ones is a compile error in
/// exhaustive switches).
sealed class DeltaConversionException implements Exception {
  const DeltaConversionException(this.message, {this.cause, this.causeStack});

  /// Human-readable description of the problem.
  final String message;

  /// Original exception that triggered this one, when wrapping. `null` when
  /// this exception is the root cause.
  final Object? cause;

  /// Stack trace associated with [cause], if available.
  final StackTrace? causeStack;

  @override
  String toString() {
    final base = '$runtimeType: $message';
    return cause == null ? base : '$base (cause: $cause)';
  }
}

/// Raised by a [DeltaImporter] when it cannot parse its input.
///
/// Use [MalformedDocumentException] for structural errors (broken markup,
/// truncated ZIP, invalid OOXML, …). Use [ImportException] directly for
/// anything else (network failure, I/O error, plugin missing on platform).
class ImportException extends DeltaConversionException {
  const ImportException(this.format, super.message,
      {super.cause, super.causeStack});

  /// The format identifier (`'html'`, `'markdown'`, `'docx'`, …) the
  /// importer was working on.
  final String format;

  @override
  String toString() {
    final base = '$runtimeType($format): $message';
    return cause == null ? base : '$base (cause: $cause)';
  }
}

/// Raised by a [DeltaImporter] when the input is recognisably the right
/// format but structurally invalid (broken HTML, truncated ZIP, malformed
/// OOXML, …).
final class MalformedDocumentException extends ImportException {
  const MalformedDocumentException(
    super.format,
    super.message, {
    super.cause,
    super.causeStack,
  });
}

/// Raised by a [DeltaExporter] when serialisation fails.
final class ExportException extends DeltaConversionException {
  const ExportException(this.format, super.message,
      {super.cause, super.causeStack});

  /// Target format identifier.
  final String format;

  @override
  String toString() {
    final base = '$runtimeType($format): $message';
    return cause == null ? base : '$base (cause: $cause)';
  }
}

/// Raised when an operation requested is recognised but not implemented for
/// the given format (e.g. PDF import in `v0.1`, OOXML field codes the
/// importer does not yet understand).
final class UnsupportedFormatException extends DeltaConversionException {
  UnsupportedFormatException(
    this.format, [
    String? message,
  ]) : super(message ?? 'Format "$format" is not supported.');

  /// The format identifier whose operation is unsupported.
  final String format;

  @override
  String toString() => '$runtimeType($format): $message';
}

/// Raised by the [ConverterRegistry] when no importer or exporter matches
/// the requested format / MIME / extension / magic bytes.
final class ConverterNotFound extends DeltaConversionException {
  const ConverterNotFound(super.message);
}
