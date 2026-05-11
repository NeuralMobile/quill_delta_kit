import 'package:html/dom.dart' as dom;

import 'audio.dart';
import 'divider.dart';
import 'embed_adapter.dart';
import 'formula.dart';
import 'iframe.dart';
import 'image.dart';
import 'mention.dart';
import 'oembed.dart';
import 'passthrough.dart';
import 'providers.dart';
import 'table.dart';
import 'video.dart';
import 'vimeo.dart';
import 'youtube.dart';

/// Registry holds adapters in dispatch order.
///
/// Encode lookup: by `op.insert` map's single key, with custom-sub-type fallback.
/// Decode lookup: first adapter whose [EmbedAdapter.matches] returns true.
class EmbedRegistry {
  EmbedRegistry({List<EmbedAdapter>? user, bool includeBuiltin = true})
      : _adapters = [
          if (user != null) ...user,
          if (includeBuiltin) ...defaults(),
        ];

  final List<EmbedAdapter> _adapters;

  /// Built-in default adapters (order matters — most specific first).
  ///
  /// Returns the shared module-level instance — adapters are stateless so
  /// no isolation concern, and callers paying for repeated [defaults] reads
  /// (e.g. per-encoder instantiation in hot tests) skip the allocation.
  static List<EmbedAdapter> defaults() => _defaults;

  static final List<EmbedAdapter> _defaults = List<EmbedAdapter>.unmodifiable([
    ImageAdapter(),
    VideoAdapter(),
    AudioAdapter(),
    DividerAdapter(),
    FormulaAdapter(),
    MentionAdapter(),
    TableAdapter(),
    // Iframe-aware provider sniffers (most specific first).
    YouTubeAdapter(),
    VimeoAdapter(),
    LoomAdapter(),
    SpotifyAdapter(),
    SoundCloudAdapter(),
    CodePenAdapter(),
    TweetAdapter(),
    OEmbedAdapter(),
    // Generic iframe last, before passthrough.
    IframeAdapter(),
    PassthroughAdapter(),
  ]);

  Iterable<EmbedAdapter> get all => _adapters;

  /// All CSS contributed by registered adapters.
  String collectCss() {
    final out = StringBuffer();
    for (final a in _adapters) {
      final css = a.css;
      if (css != null && css.trim().isNotEmpty) {
        out.writeln('/* ${a.type} */');
        out.writeln(css.trim());
      }
    }
    return out.toString();
  }

  /// Find the encode adapter for an embed type. Returns null if none registered.
  EmbedAdapter? forType(String type, {String? customSubType}) {
    for (final a in _adapters) {
      if (customSubType != null) {
        if (a.type == 'custom' && a.customSubType == customSubType) return a;
        if (a.type == customSubType && a.customSubType == null) return a;
      } else if (a.type == type) {
        return a;
      }
    }
    return null;
  }

  /// First adapter whose [EmbedAdapter.matches] returns true for [element].
  EmbedAdapter? forElement(dom.Element element) {
    for (final a in _adapters) {
      if (a.matches(element)) return a;
    }
    return null;
  }
}
