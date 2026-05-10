import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'embeds/embed_adapter.dart';
import 'embeds/registry.dart';
import 'html/html_exporter.dart';
import 'html/html_importer.dart';
import 'options.dart';

/// Bidirectional Quill Delta <-> HTML codec.
///
/// Thin façade around [HtmlImporter] + [HtmlExporter]. Prefer the importer/
/// exporter classes directly for new code — they conform to the
/// [DeltaImporter]/[DeltaExporter] contract used by the multi-format
/// converter family.
class QuillHtmlCodec {
  QuillHtmlCodec({
    List<EmbedAdapter> adapters = const [],
    this.options = const QuillHtmlOptions(),
  }) : registry = EmbedRegistry(user: adapters);

  final QuillHtmlOptions options;
  final EmbedRegistry registry;

  /// Delta -> HTML.
  String encode(Delta delta) =>
      HtmlExporter(registry: registry, defaultOptions: options)
          .exportSync(delta);

  /// HTML -> Delta.
  Delta decode(String html) =>
      HtmlImporter(registry: registry, defaultOptions: options)
          .importSync(html);
}
