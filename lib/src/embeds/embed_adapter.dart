import 'package:html/dom.dart' as dom;

import '../options.dart';

/// Custom embed (de)serializer.
///
/// Adapters operate on:
///   - Encode: a Delta `insert` value (`{<type>: <data>}`) plus optional sibling attrs.
///   - Decode: a parsed HTML element.
///
/// Multiple adapters can register; encoder routes by [type], decoder by [matches].
abstract class EmbedAdapter {
  /// Embed type key (matches the single key inside a Delta `{"insert": {<type>: ...}}` op).
  String get type;

  /// When non-null, this adapter handles a sub-type wrapped inside the flutter_quill
  /// `{"insert":{"custom":"<json {sub: data}>"}}` shape.
  String? get customSubType => null;

  /// Optional CSS injected once into a `<style>` tag at document scope.
  String? get css => null;

  /// Encode this op into one or more HTML nodes appended onto [parent].
  /// [value] is the embed payload; [siblingAttrs] are op-level attributes
  /// (e.g. width/height/style) attached alongside the embed insert.
  void encode({
    required dom.Element parent,
    required Object? value,
    Map<String, dynamic>? siblingAttrs,
    required QuillHtmlOptions options,
  });

  /// Returns true if this adapter recognizes [element].
  bool matches(dom.Element element);

  /// Decode [element] into a Delta op JSON map: `{"insert": {<type>: <data>}, "attributes": {...}?}`.
  /// Return null to defer to the next adapter.
  Map<String, dynamic>? decode(dom.Element element, QuillHtmlOptions options);
}

/// Result of a successful adapter dispatch.
class EmbedDecodeResult {
  EmbedDecodeResult(this.op);
  final Map<String, dynamic> op;
}
