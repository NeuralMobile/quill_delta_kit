import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:quill_delta_core/quill_delta_core.dart';

import '../decoder/decoder.dart';
import '../embeds/embed_adapter.dart';
import '../embeds/registry.dart';

/// HTML string -> Delta. The only format-specific importer that uses
/// [HtmlDecoder] directly; all other text importers pivot through this via
/// [HtmlPivotImporter].
final class HtmlImporter implements SyncDeltaImporter<String, HtmlOptions> {
  HtmlImporter({
    EmbedRegistry? registry,
    List<EmbedAdapter> adapters = const [],
    HtmlOptions? defaultOptions,
  })  : _registry = registry ?? EmbedRegistry(user: adapters),
        _defaultOptions = defaultOptions;

  final EmbedRegistry _registry;
  final HtmlOptions? _defaultOptions;

  EmbedRegistry get registry => _registry;

  @override
  String get format => 'html';

  @override
  Set<String> get mimeTypes => const {'text/html', 'application/xhtml+xml'};

  @override
  Set<String> get extensions => const {'html', 'htm'};

  @override
  HtmlOptions get defaultOptions => _defaultOptions ?? const HtmlOptions();

  @override
  Future<Delta> import(String input, {HtmlOptions? options}) async {
    final opts = options ?? defaultOptions;
    final doc = html_parser.parse(input);
    return HtmlDecoder(_registry, opts).decode(doc);
  }

  /// Synchronous variant for callers that need direct sync access (the codec
  /// shim and existing call sites). The async [import] wraps this.
  @override
  Delta importSync(String input, {HtmlOptions? options}) {
    final opts = options ?? defaultOptions;
    final doc = html_parser.parse(input);
    return HtmlDecoder(_registry, opts).decode(doc);
  }
}
