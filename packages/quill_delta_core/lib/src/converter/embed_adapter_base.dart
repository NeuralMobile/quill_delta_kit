import 'converter_options.dart';

/// Format-agnostic root of the embed adapter family.
///
/// A concrete embed adapter is **always per-format**: HTML's [EmbedAdapter]
/// operates on `dom.Element` + `HtmlWriter`; the Markdown package's
/// [MarkdownEmbedAdapter] operates on a [StringBuffer] + `md.Element`; the
/// Docx package's adapter would operate on an OOXML `StringBuffer` +
/// `XmlElement`. Each format ships its own contract because the underlying
/// node types differ — there is no useful single Dart type that captures
/// "an HTML element OR a markdown AST node OR an OOXML element".
///
/// What unifies them, and lives here, is the metadata: the embed [type]
/// (matching `{insert: {<type>: ...}}`), the optional [customSubType] for
/// flutter_quill custom-wrapper round-tripping, and the option-bag generic
/// [TOpts]. Per-format registries are typed as
/// `List<EmbedAdapterBase<TFormatOpts>>` so they can be uniformly held.
abstract class EmbedAdapterBase<TOpts extends ConverterOptions> {
  /// Embed type key, matching the single key inside a Delta
  /// `{"insert": {<type>: ...}}` op.
  String get type;

  /// When non-null, this adapter handles a sub-type wrapped inside the
  /// flutter_quill `{"insert":{"custom":"<json {sub: data}>"}}` shape.
  String? get customSubType => null;
}
