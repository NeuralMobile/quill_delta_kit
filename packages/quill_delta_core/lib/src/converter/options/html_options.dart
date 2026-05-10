import '../converter_options.dart';

/// Iframe sanitization policy used by [HtmlOptions].
class IframePolicy {
  const IframePolicy({
    this.allowedHosts = const <String>{},
    this.allowedSchemes = const {'https'},
    this.requireSandbox = false,
    this.defaultSandbox = const ['allow-scripts', 'allow-same-origin'],
    this.allowedAttrs = const {
      'src',
      'width',
      'height',
      'allow',
      'allowfullscreen',
      'sandbox',
      'title',
      'loading',
      'referrerpolicy',
      'frameborder',
    },
  });

  /// Empty = allow all hosts (still scheme-checked).
  final Set<String> allowedHosts;
  final Set<String> allowedSchemes;
  final bool requireSandbox;
  final List<String> defaultSandbox;
  final Set<String> allowedAttrs;

  bool isUrlAllowed(String? src) {
    if (src == null || src.isEmpty) return false;
    final uri = Uri.tryParse(src);
    if (uri == null) return false;
    if (!allowedSchemes.contains(uri.scheme)) return false;
    if (allowedHosts.isNotEmpty && !allowedHosts.contains(uri.host)) {
      return false;
    }
    return true;
  }
}

/// Canonical Delta-side color format produced by the HTML decoder.
enum ColorFormat { rgba, hex6, hex8 }

/// Options for the HTML importer and exporter.
///
/// Lives in core (not the html package) so that pivot-based importers in
/// other format packages (markdown, docx) can reference [HtmlOptions]
/// without taking a dependency on `package:quill_delta_html`.
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
