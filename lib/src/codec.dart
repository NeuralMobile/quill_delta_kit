import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:html/parser.dart' as html_parser;

import 'decoder/decoder.dart';
import 'embeds/embed_adapter.dart';
import 'embeds/registry.dart';
import 'encoder/block_encoder.dart';
import 'encoder/line_splitter.dart';
import 'options.dart';
import 'util/html_writer.dart';

/// Bidirectional Quill Delta <-> HTML codec.
class QuillHtmlCodec {
  QuillHtmlCodec({
    List<EmbedAdapter> adapters = const [],
    this.options = const QuillHtmlOptions(),
  }) : registry = EmbedRegistry(user: adapters);

  final QuillHtmlOptions options;
  final EmbedRegistry registry;

  /// Delta -> HTML.
  String encode(Delta delta) {
    final writer = HtmlWriter();
    if (options.wrapDocument) {
      writer.open('div', {
        'class': 'ql-html-doc',
        'style': 'white-space: pre-wrap',
      });
    }
    final lines = splitIntoLines(delta);
    BlockEncoder(registry, options).encode(lines, writer);
    if (options.wrapDocument) {
      writer.close('div');
    }
    return writer.toString();
  }

  /// HTML -> Delta.
  Delta decode(String html) {
    final doc = html_parser.parse(html);
    return HtmlDecoder(registry, options).decode(doc);
  }
}
