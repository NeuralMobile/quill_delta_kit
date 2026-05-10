/// Behaviour when a [Delta] embed type has no registered serializer for the
/// target format.
enum UnknownEmbedFallback {
  /// Wrap unknown HTML element in a passthrough custom embed (HTML format)
  /// or emit a best-effort placeholder (other formats).
  passthrough,

  /// Drop unknown elements (text content preserved).
  drop,
}

/// Shared base for every format's option bag.
///
/// Most options are format-specific and live on subclasses. Only fields that
/// every converter must reason about belong here. Today that is the policy
/// for unknown embeds.
///
/// All subclasses must be const-constructible so callers can declare
/// compile-time defaults.
abstract class ConverterOptions {
  const ConverterOptions({
    this.unknownEmbedFallback = UnknownEmbedFallback.passthrough,
  });

  /// What to do when a Delta embed type cannot be expressed in the target
  /// format. Default: [UnknownEmbedFallback.passthrough].
  final UnknownEmbedFallback unknownEmbedFallback;
}
