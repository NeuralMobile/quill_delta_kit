import 'package:html/dom.dart' as dom;

import '../options.dart';
import '../util/html_writer.dart';

/// Custom embed (de)serializer.
///
/// Adapters operate on:
///   - Encode: a Delta `insert` value (`{<type>: <data>}`) plus optional
///     sibling attrs. Writes directly into an [HtmlWriter] (streaming
///     StringBuffer) — there is no intermediate DOM tree.
///   - Decode: a parsed HTML element from `package:html`.
///
/// **Value & attribute contract.** [encode]'s `value` parameter is the raw
/// embed payload as it appears inside the Delta op
/// (`op['insert'][<type>]`) — the shape is adapter-specific (string for
/// image src, `Map<String, dynamic>` for table data, …) and adapters
/// should validate via `is` before downcasting. [siblingAttrs] mirrors the
/// `Map<String, dynamic>` shape used by upstream `dart_quill_delta`.
///
/// Multiple adapters can register; encoder routes by [type], decoder by
/// [matches].
abstract class EmbedAdapter {
  /// Embed type key (matches the single key inside a Delta
  /// `{"insert": {<type>: ...}}` op).
  String get type;

  /// When non-null, this adapter handles a sub-type wrapped inside the
  /// flutter_quill `{"insert":{"custom":"<json {sub: data}>"}}` shape.
  String? get customSubType => null;

  /// Optional CSS injected once into a `<style>` tag at document scope.
  String? get css => null;

  /// Encode this op into HTML written into [writer].
  /// [value] is the embed payload; [siblingAttrs] are op-level attributes
  /// (e.g. width/height/style) attached alongside the embed insert.
  void encode({
    required HtmlWriter writer,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  });

  /// Returns true if this adapter recognizes [element].
  bool matches(dom.Element element);

  /// Decode [element] into a Delta op JSON map:
  /// `{"insert": {<type>: <data>}, "attributes": {...}?}`.
  /// Return null to defer to the next adapter.
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options);
}

/// Result of a successful adapter dispatch.
class EmbedDecodeResult {
  EmbedDecodeResult(this.op);
  final Map<String, dynamic> op;
}
