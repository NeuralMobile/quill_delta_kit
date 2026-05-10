import 'converter/options/html_options.dart' show HtmlOptions;

export 'converter/converter_options.dart' show UnknownEmbedFallback;
export 'converter/options/html_options.dart' show HtmlOptions;

/// Iframe sanitization policy. Used by [HtmlOptions]/[QuillHtmlOptions].
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

/// Canonical Delta-side color format produced by the decoder.
enum ColorFormat { rgba, hex6, hex8 }

/// Legacy name kept as a typedef so existing call sites compile unchanged.
typedef QuillHtmlOptions = HtmlOptions;
