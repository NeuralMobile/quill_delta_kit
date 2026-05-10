/// Codec options.
class QuillHtmlOptions {
  const QuillHtmlOptions({
    this.wrapDocument = true,
    this.preserveWhitespace = true,
    this.iframePolicy = const IframePolicy(),
    this.canonicalColorFormat = ColorFormat.rgba,
    this.emitCheckedListBothShapes = true,
    this.useFlutterQuillCustomWrapper = false,
    this.unknownEmbedFallback = UnknownEmbedFallback.passthrough,
  });

  /// Wrap encoded HTML in `<div class="ql-html-doc" style="white-space: pre-wrap">…</div>`.
  /// Set false to emit fragment-only HTML.
  final bool wrapDocument;

  /// Encode significant whitespace via numeric char refs. Default true.
  final bool preserveWhitespace;

  final IframePolicy iframePolicy;

  /// Canonical Delta-side color format.
  final ColorFormat canonicalColorFormat;

  /// Emit both `<ul data-checked="true">` AND `<li data-list="checked">` for max interop.
  final bool emitCheckedListBothShapes;

  /// When true, custom embeds round-trip through flutter_quill `{"insert":{"custom":"<json>"}}` wrapper.
  /// When false, custom embeds use top-level `{"insert":{"<type>": data}}`.
  final bool useFlutterQuillCustomWrapper;

  final UnknownEmbedFallback unknownEmbedFallback;
}

enum ColorFormat { rgba, hex6, hex8 }

enum UnknownEmbedFallback {
  /// Wrap unknown HTML element in a passthrough custom embed.
  passthrough,

  /// Drop unknown elements (text content preserved).
  drop,
}

/// Iframe sanitization policy.
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
