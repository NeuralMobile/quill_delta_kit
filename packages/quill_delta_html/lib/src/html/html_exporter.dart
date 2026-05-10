import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_core/quill_delta_core.dart';

import '../embeds/embed_adapter.dart';
import '../embeds/registry.dart';
import '../encoder/block_encoder.dart';
import '../util/html_writer.dart';

/// Delta -> HTML string.
final class HtmlExporter implements DeltaExporter<String, HtmlOptions> {
  HtmlExporter({
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
  String get mimeType => 'text/html';

  @override
  String get extension => 'html';

  @override
  HtmlOptions get defaultOptions => _defaultOptions ?? const HtmlOptions();

  @override
  Future<String> export(Delta delta, {HtmlOptions? options}) async {
    return exportSync(delta, options: options);
  }

  /// Synchronous variant. Encoding is fully sync internally; this exposes
  /// that fact for callers who want to skip the Future.
  String exportSync(Delta delta, {HtmlOptions? options}) {
    final opts = options ?? defaultOptions;
    final writer = HtmlWriter();
    if (opts.wrapDocument) {
      writer.open('div', {
        'class': 'ql-html-doc',
        'style': 'white-space: pre-wrap',
      });
    }
    final lines = splitIntoLines(delta);
    BlockEncoder(_registry, opts).encode(lines, writer);
    if (opts.wrapDocument) {
      writer.close('div');
    }
    return writer.toString();
  }
}
