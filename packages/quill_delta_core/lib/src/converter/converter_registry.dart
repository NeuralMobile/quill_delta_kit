import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../errors.dart';
import 'converter_options.dart';
import 'delta_exporter.dart';
import 'delta_importer.dart';

/// Manages a collection of [DeltaImporter]s and [DeltaExporter]s.
///
/// Type erasure: the maps store `DeltaImporter<dynamic, dynamic>` because
/// Dart's runtime generics are erased anyway. [importAuto] performs an
/// explicit input-type check before dispatching, so no ClassCastException
/// can leak.
class ConverterRegistry {
  ConverterRegistry({
    List<DeltaImporter<dynamic, dynamic>> importers = const [],
    List<DeltaExporter<dynamic, dynamic>> exporters = const [],
  }) {
    for (final i in importers) {
      registerImporter(i);
    }
    for (final e in exporters) {
      registerExporter(e);
    }
  }

  final Map<String, DeltaImporter<dynamic, dynamic>> _importers = {};
  final Map<String, DeltaExporter<dynamic, dynamic>> _exporters = {};
  final Map<String, String> _mimeToFormat = {};
  final Map<String, String> _extToFormat = {};

  void registerImporter(DeltaImporter<dynamic, dynamic> importer) {
    _importers[importer.format.toLowerCase()] = importer;
    for (final m in importer.mimeTypes) {
      _mimeToFormat[m.toLowerCase()] = importer.format;
    }
    for (final e in importer.extensions) {
      _extToFormat[e.toLowerCase()] = importer.format;
    }
  }

  void registerExporter(DeltaExporter<dynamic, dynamic> exporter) {
    _exporters[exporter.format.toLowerCase()] = exporter;
  }

  /// Look up an importer by [format] name. Caller supplies type parameters
  /// matching what was registered; mismatch throws at runtime when [import]
  /// is called.
  DeltaImporter<TIn, TOpts> importer<TIn, TOpts extends ConverterOptions>(
    String format,
  ) {
    final found = _importers[format.toLowerCase()];
    if (found == null) {
      throw ConverterNotFound('No importer for format "$format"');
    }
    return found as DeltaImporter<TIn, TOpts>;
  }

  /// Look up an exporter by [format] name.
  DeltaExporter<TOut, TOpts> exporter<TOut, TOpts extends ConverterOptions>(
    String format,
  ) {
    final found = _exporters[format.toLowerCase()];
    if (found == null) {
      throw ConverterNotFound('No exporter for format "$format"');
    }
    return found as DeltaExporter<TOut, TOpts>;
  }

  /// Auto-import [input] without the caller specifying which format it is.
  ///
  /// Detection order:
  ///   1. Explicit [format] hint.
  ///   2. Explicit [mime] hint.
  ///   3. [filename] extension.
  ///   4. Magic-byte sniff (binary inputs).
  ///   5. Content sniff for [String] inputs (looks for HTML/Markdown).
  ///
  /// [input] must be [String] or [List<int>] / [Uint8List]; other types
  /// throw [ArgumentError]. Uses each importer's [defaultOptions]; for
  /// custom options call [importer] then [DeltaImporter.import] directly.
  Future<Delta> importAuto(
    Object input, {
    String? format,
    String? filename,
    String? mime,
  }) async {
    final resolvedFormat = format?.toLowerCase() ?? _resolveFormat(input, filename: filename, mime: mime);

    if (resolvedFormat == null) {
      throw ConverterNotFound(
        'Cannot determine format for input '
        '(mime=$mime, filename=$filename, '
        'type=${input.runtimeType}).',
      );
    }

    final found = _importers[resolvedFormat];
    if (found == null) {
      throw ConverterNotFound('No importer registered for format "$resolvedFormat"');
    }

    if (input is String) {
      return (found as DeltaImporter<String, ConverterOptions>).import(input);
    } else if (input is List<int>) {
      return (found as DeltaImporter<List<int>, ConverterOptions>).import(input);
    } else {
      throw ArgumentError.value(
        input,
        'input',
        'importAuto accepts String or List<int>; got ${input.runtimeType}.',
      );
    }
  }

  String? _resolveFormat(Object input, {String? filename, String? mime}) {
    if (mime != null) {
      final f = _mimeToFormat[mime.toLowerCase()];
      if (f != null) return f;
    }
    if (filename != null) {
      final ext = _extensionOf(filename);
      if (ext != null) {
        final f = _extToFormat[ext];
        if (f != null) return f;
      }
    }
    if (input is List<int> && input.isNotEmpty) {
      final detected = sniffMagicBytes(input);
      if (detected != null) {
        if (_importers.containsKey(detected)) return detected;
      }
    }
    if (input is String) {
      final f = _sniffTextFormat(input);
      if (f != null && _importers.containsKey(f)) return f;
    }
    return null;
  }

  static String? _extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return null;
    return filename.substring(dot + 1).toLowerCase();
  }

  static String? _sniffTextFormat(String text) {
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.length >= 16 ? trimmed.substring(0, 16).toLowerCase() : trimmed.toLowerCase();
    if (lower.startsWith('<!doctype html') || lower.startsWith('<html')) {
      return 'html';
    }
    if (_htmlFragmentPattern.hasMatch(trimmed)) return 'html';
    if (_markdownPattern.hasMatch(trimmed)) return 'markdown';
    return null;
  }

  static final _htmlFragmentPattern = RegExp(
    r'^<(p|div|span|h[1-6]|ul|ol|li|table|blockquote|pre|code|a|img|br|hr|strong|em|b|i)\b',
    caseSensitive: false,
  );

  static final _markdownPattern = RegExp(r'^(#{1,6} |```|~~~|---|\*\*\*|> |\* |- \[)');
}

/// Inspect the first bytes of [bytes] and return a canonical format name
/// (matching [DeltaImporter.format]) or null if unrecognised.
///
/// | Format | Magic bytes                          |
/// |--------|--------------------------------------|
/// | docx   | `PK\x03\x04` (ZIP local file header) |
/// | pdf    | `%PDF`                               |
///
/// Note: ZIP signature also matches xlsx/pptx/odt/apk; callers should prefer
/// MIME or extension hints when available.
String? sniffMagicBytes(List<int> bytes) {
  if (bytes.length >= 4) {
    if (bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04) {
      return 'docx';
    }
    if (bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return 'pdf';
    }
  }
  return null;
}

/// Detect format from a filename extension.
String? sniffExtension(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) return null;
  final ext = filename.substring(dot + 1).toLowerCase();
  return _knownExtensions[ext];
}

const _knownExtensions = <String, String>{
  'html': 'html',
  'htm': 'html',
  'md': 'markdown',
  'markdown': 'markdown',
  'mdown': 'markdown',
  'mkd': 'markdown',
  'docx': 'docx',
  'pdf': 'pdf',
};
