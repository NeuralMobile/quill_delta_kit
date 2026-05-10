import 'package:flutter/widgets.dart';

/// How the editor lays out vertically.
///
/// Each variant is a `const` factory so callers can build configs without
/// allocations. Use the matching subtype to pattern-match on layout in
/// custom code paths.
sealed class EditorLayoutConfig {
  const EditorLayoutConfig({
    this.padding = const EdgeInsets.all(12),
    this.placeholder,
    this.autoFocus = false,
    this.readOnly = false,
  });

  /// Padding inside the editor's content area.
  final EdgeInsets padding;

  /// Optional placeholder shown when document is empty.
  final String? placeholder;

  /// Take focus on first build.
  final bool autoFocus;

  /// Render in read-only mode (no toolbar buttons modify the document, the
  /// editor surface still allows selection / copy).
  final bool readOnly;

  /// Editor scrolls internally; suitable for fixed-size containers.
  const factory EditorLayoutConfig.scrollable({
    EdgeInsets padding,
    String? placeholder,
    bool autoFocus,
    bool readOnly,
  }) = ScrollableLayout;

  /// Editor grows with content between [minHeight] and [maxHeight].
  /// Useful inside `Column`s or `Form`s where the surrounding scroll view
  /// owns the scroll.
  const factory EditorLayoutConfig.autoGrow({
    double minHeight,
    double? maxHeight,
    EdgeInsets padding,
    String? placeholder,
    bool autoFocus,
    bool readOnly,
  }) = AutoGrowLayout;

  /// Editor occupies exactly [height] pixels and scrolls internally.
  const factory EditorLayoutConfig.fixed({
    required double height,
    EdgeInsets padding,
    String? placeholder,
    bool autoFocus,
    bool readOnly,
  }) = FixedHeightLayout;

  /// Editor expands to fill its parent's vertical constraints.
  /// Use inside `Expanded` / sliver / sized box.
  const factory EditorLayoutConfig.expanded({
    EdgeInsets padding,
    String? placeholder,
    bool autoFocus,
    bool readOnly,
  }) = ExpandedLayout;
}

final class ScrollableLayout extends EditorLayoutConfig {
  const ScrollableLayout({
    super.padding = const EdgeInsets.all(12),
    super.placeholder,
    super.autoFocus = false,
    super.readOnly = false,
  });
}

final class AutoGrowLayout extends EditorLayoutConfig {
  const AutoGrowLayout({
    this.minHeight = 80,
    this.maxHeight,
    super.padding = const EdgeInsets.all(12),
    super.placeholder,
    super.autoFocus = false,
    super.readOnly = false,
  });
  final double minHeight;
  final double? maxHeight;
}

final class FixedHeightLayout extends EditorLayoutConfig {
  const FixedHeightLayout({
    required this.height,
    super.padding = const EdgeInsets.all(12),
    super.placeholder,
    super.autoFocus = false,
    super.readOnly = false,
  });
  final double height;
}

final class ExpandedLayout extends EditorLayoutConfig {
  const ExpandedLayout({
    super.padding = const EdgeInsets.all(12),
    super.placeholder,
    super.autoFocus = false,
    super.readOnly = false,
  });
}
