import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../converter_options.dart';

const _setEq = SetEquality<String>();
const _listEq = ListEquality<String>();

/// Iframe sanitization policy used by [HtmlOptions].
@immutable
class IframePolicy {
  IframePolicy({
    Set<String> allowedHosts = const <String>{},
    Set<String> allowedSchemes = const {'https'},
    this.requireSandbox = false,
    List<String> defaultSandbox = const ['allow-scripts', 'allow-same-origin'],
    Set<String> allowedAttrs = const {
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
  })  : allowedHosts = Set.unmodifiable(allowedHosts),
        allowedSchemes = Set.unmodifiable(allowedSchemes),
        defaultSandbox = List.unmodifiable(defaultSandbox),
        allowedAttrs = Set.unmodifiable(allowedAttrs);

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

  IframePolicy copyWith({
    Set<String>? allowedHosts,
    Set<String>? allowedSchemes,
    bool? requireSandbox,
    List<String>? defaultSandbox,
    Set<String>? allowedAttrs,
  }) {
    return IframePolicy(
      allowedHosts: allowedHosts ?? this.allowedHosts,
      allowedSchemes: allowedSchemes ?? this.allowedSchemes,
      requireSandbox: requireSandbox ?? this.requireSandbox,
      defaultSandbox: defaultSandbox ?? this.defaultSandbox,
      allowedAttrs: allowedAttrs ?? this.allowedAttrs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IframePolicy &&
        _setEq.equals(allowedHosts, other.allowedHosts) &&
        _setEq.equals(allowedSchemes, other.allowedSchemes) &&
        requireSandbox == other.requireSandbox &&
        _listEq.equals(defaultSandbox, other.defaultSandbox) &&
        _setEq.equals(allowedAttrs, other.allowedAttrs);
  }

  @override
  int get hashCode => Object.hash(
        _setEq.hash(allowedHosts),
        _setEq.hash(allowedSchemes),
        requireSandbox,
        _listEq.hash(defaultSandbox),
        _setEq.hash(allowedAttrs),
      );
}

/// Canonical Delta-side color format produced by the HTML decoder.
enum ColorFormat { rgba, hex6, hex8 }

/// Options for the HTML importer and exporter.
///
/// Lives in core (not the html package) so that pivot-based importers in
/// other format packages (markdown, docx) can reference [HtmlOptions]
/// without taking a dependency on `package:quill_delta_html`.
@immutable
class HtmlOptions extends ConverterOptions {
  const HtmlOptions({
    this.wrapDocument = true,
    this.preserveWhitespace = true,
    this.iframePolicy = const IframePolicyDefault(),
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

  HtmlOptions copyWith({
    bool? wrapDocument,
    bool? preserveWhitespace,
    IframePolicy? iframePolicy,
    ColorFormat? canonicalColorFormat,
    bool? emitCheckedListBothShapes,
    bool? useFlutterQuillCustomWrapper,
    UnknownEmbedFallback? unknownEmbedFallback,
  }) {
    return HtmlOptions(
      wrapDocument: wrapDocument ?? this.wrapDocument,
      preserveWhitespace: preserveWhitespace ?? this.preserveWhitespace,
      iframePolicy: iframePolicy ?? this.iframePolicy,
      canonicalColorFormat: canonicalColorFormat ?? this.canonicalColorFormat,
      emitCheckedListBothShapes: emitCheckedListBothShapes ?? this.emitCheckedListBothShapes,
      useFlutterQuillCustomWrapper: useFlutterQuillCustomWrapper ?? this.useFlutterQuillCustomWrapper,
      unknownEmbedFallback: unknownEmbedFallback ?? this.unknownEmbedFallback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HtmlOptions &&
        wrapDocument == other.wrapDocument &&
        preserveWhitespace == other.preserveWhitespace &&
        iframePolicy == other.iframePolicy &&
        canonicalColorFormat == other.canonicalColorFormat &&
        emitCheckedListBothShapes == other.emitCheckedListBothShapes &&
        useFlutterQuillCustomWrapper == other.useFlutterQuillCustomWrapper &&
        unknownEmbedFallback == other.unknownEmbedFallback;
  }

  @override
  int get hashCode => Object.hash(
        wrapDocument,
        preserveWhitespace,
        iframePolicy,
        canonicalColorFormat,
        emitCheckedListBothShapes,
        useFlutterQuillCustomWrapper,
        unknownEmbedFallback,
      );
}

/// `const`-friendly identity for the default [IframePolicy].
///
/// Required because the unmodifiable wrapping in [IframePolicy]'s constructor
/// runs at runtime; the regular ctor cannot be `const`. We expose a singleton
/// default so callers can still construct [HtmlOptions] at compile time.
class IframePolicyDefault implements IframePolicy {
  const IframePolicyDefault();

  @override
  Set<String> get allowedHosts => const <String>{};
  @override
  Set<String> get allowedSchemes => const {'https'};
  @override
  bool get requireSandbox => false;
  @override
  List<String> get defaultSandbox => const ['allow-scripts', 'allow-same-origin'];
  @override
  Set<String> get allowedAttrs => const {
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
      };

  @override
  bool isUrlAllowed(String? src) {
    if (src == null || src.isEmpty) return false;
    final uri = Uri.tryParse(src);
    if (uri == null) return false;
    return allowedSchemes.contains(uri.scheme);
  }

  @override
  IframePolicy copyWith({
    Set<String>? allowedHosts,
    Set<String>? allowedSchemes,
    bool? requireSandbox,
    List<String>? defaultSandbox,
    Set<String>? allowedAttrs,
  }) {
    return IframePolicy(
      allowedHosts: allowedHosts ?? this.allowedHosts,
      allowedSchemes: allowedSchemes ?? this.allowedSchemes,
      requireSandbox: requireSandbox ?? this.requireSandbox,
      defaultSandbox: defaultSandbox ?? this.defaultSandbox,
      allowedAttrs: allowedAttrs ?? this.allowedAttrs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IframePolicy) return false;
    return _setEq.equals(allowedHosts, other.allowedHosts) &&
        _setEq.equals(allowedSchemes, other.allowedSchemes) &&
        requireSandbox == other.requireSandbox &&
        _listEq.equals(defaultSandbox, other.defaultSandbox) &&
        _setEq.equals(allowedAttrs, other.allowedAttrs);
  }

  @override
  int get hashCode => Object.hash(
        _setEq.hash(allowedHosts),
        _setEq.hash(allowedSchemes),
        requireSandbox,
        _listEq.hash(defaultSandbox),
        _setEq.hash(allowedAttrs),
      );
}
