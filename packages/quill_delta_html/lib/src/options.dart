/// Backwards-compat barrel.
///
/// The actual definitions of [HtmlOptions], [IframePolicy], [ColorFormat],
/// and [UnknownEmbedFallback] now live in `package:quill_delta_core` so other
/// format packages can reuse them without depending on the html package.
library;

import 'package:quill_delta_core/quill_delta_core.dart' show HtmlOptions;

export 'package:quill_delta_core/quill_delta_core.dart'
    show ColorFormat, HtmlOptions, IframePolicy, UnknownEmbedFallback;

/// Legacy name kept as a typedef so existing call sites compile unchanged.
typedef QuillHtmlOptions = HtmlOptions;
