import '../../options.dart' show ColorFormat, IframePolicy;
import '../converter_options.dart';

export '../../options.dart' show ColorFormat, IframePolicy;

/// Options for the HTML importer and exporter.
///
/// Fields mirror the legacy [QuillHtmlOptions] class — [QuillHtmlOptions] is
/// kept as a typedef alias so existing code compiles unchanged.
class HtmlOptions extends ConverterOptions {
  const HtmlOptions({
    this.wrapDocument = true,
    this.preserveWhitespace = true,
    this.iframePolicy = const IframePolicy(),
    this.canonicalColorFormat = ColorFormat.rgba,
    this.emitCheckedListBothShapes = true,
    this.useFlutterQuillCustomWrapper = false,
    super.unknownEmbedFallback,
  });

  /// Wrap encoded HTML in `<div class="ql-html-doc" style="...">`.
  /// When false, emits a fragment.
  final bool wrapDocument;

  /// Encode significant whitespace via numeric char refs.
  final bool preserveWhitespace;

  /// Iframe sanitization policy.
  final IframePolicy iframePolicy;

  /// Canonical Delta-side color format produced by the decoder.
  final ColorFormat canonicalColorFormat;

  /// Emit both `<ul data-checked>` and `<li data-list>` for max interop.
  final bool emitCheckedListBothShapes;

  /// When true, custom embeds round-trip through flutter_quill
  /// `{"insert":{"custom":"<json>"}}` wrapper.
  final bool useFlutterQuillCustomWrapper;
}
