/// Lossless bidirectional Quill Delta <-> HTML conversion.
///
/// Re-exports the converter abstractions from `quill_delta_core` so existing
/// consumers can keep importing only `package:quill_delta_html/quill_delta_html.dart`.
///
/// Concrete built-in embed adapters (audio/divider/iframe/image/video/oembed
/// /mention/youtube/vimeo, plus provider sniffs like Loom, Spotify,
/// SoundCloud, Tweet, CodePen) are intentionally not exported from this
/// barrel: they are wired into the default registry via
/// [EmbedRegistry.defaults] and are not part of the public API surface.
/// Adapters with caller-facing configuration knobs ([FormulaAdapter] —
/// custom renderer, [TableAdapter] — allowed cell tags) and
/// [PassthroughAdapter] (useful as a base for custom embeds) remain
/// exported.
library;

export 'package:quill_delta_core/quill_delta_core.dart';

export 'src/codec.dart';
export 'src/embeds/embed_adapter.dart';
export 'src/embeds/formula.dart' show FormulaAdapter;
export 'src/embeds/passthrough.dart' show PassthroughAdapter;
export 'src/embeds/registry.dart';
export 'src/embeds/table.dart' show TableAdapter;
export 'src/html/html_exporter.dart';
export 'src/html/html_importer.dart';
export 'src/options.dart';
export 'src/util/html_writer.dart';
