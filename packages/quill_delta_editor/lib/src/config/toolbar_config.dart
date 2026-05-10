import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Toolbar visual density.
enum ToolbarStyle {
  /// Minimal — text formatting only.
  minimal,

  /// Compact — common buttons in one row.
  compact,

  /// Full — every formatting + media + history button.
  full,
}

/// Position of a floating toolbar relative to its container.
enum FloatingToolbarPosition {
  topCenter,
  topRight,
  bottomCenter,
  bottomRight,
}

/// Built-in toolbar button identifiers. The wrapper maps each ID to the
/// flutter_quill button it represents. Custom toolbars built via
/// [ToolbarConfig.custom] bypass this enum entirely.
enum ToolbarButtonId {
  bold,
  italic,
  underline,
  strike,
  inlineCode,
  fontFamily,
  fontSize,
  color,
  background,
  link,
  undo,
  redo,
  header,
  listBullet,
  listNumber,
  listCheck,
  blockquote,
  codeBlock,
  alignLeft,
  alignCenter,
  alignRight,
  alignJustify,
  indent,
  outdent,
  image,
  video,
  divider,
  formula,
  clearFormat,
  search,
}

/// One logical group of buttons rendered as a contiguous toolbar segment.
class ToolbarSection {
  const ToolbarSection({required this.buttons, this.padding});
  final List<ToolbarButtonId> buttons;
  final EdgeInsets? padding;
}

/// Toolbar placement and styling.
sealed class ToolbarConfig {
  const ToolbarConfig({
    this.style = ToolbarStyle.compact,
    this.sections,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.toolbarSize = 36,
  });

  final ToolbarStyle style;
  final List<ToolbarSection>? sections;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final double toolbarSize;

  const factory ToolbarConfig.top({
    ToolbarStyle style,
    List<ToolbarSection>? sections,
    Color? backgroundColor,
    EdgeInsets padding,
    double toolbarSize,
  }) = TopToolbar;

  const factory ToolbarConfig.bottom({
    ToolbarStyle style,
    List<ToolbarSection>? sections,
    Color? backgroundColor,
    EdgeInsets padding,
    double toolbarSize,
  }) = BottomToolbar;

  const factory ToolbarConfig.floating({
    FloatingToolbarPosition position,
    ToolbarStyle style,
    List<ToolbarSection>? sections,
    Color? backgroundColor,
    EdgeInsets padding,
    double toolbarSize,
    EdgeInsets margin,
  }) = FloatingToolbar;

  const factory ToolbarConfig.none() = NoToolbar;

  /// Toolbar appears as a floating popover anchored to the active text
  /// selection (iOS-style selection context menu). Hidden when the
  /// selection is collapsed or the editor has no focus.
  const factory ToolbarConfig.selection({
    SelectionAnchor anchor,
    double offset,
    ToolbarStyle style,
    List<ToolbarSection>? sections,
    Color? backgroundColor,
    EdgeInsets padding,
    double toolbarSize,
  }) = SelectionToolbar;

  /// Fully custom toolbar. The wrapper renders the result of [builder] in
  /// the chosen [position] without applying its own styling.
  const factory ToolbarConfig.custom({
    required ToolbarBuilder builder,
    ToolbarPlacement placement,
  }) = CustomToolbar;
}

/// Where a custom toolbar sits relative to the editor surface.
enum ToolbarPlacement { top, bottom, overlay }

typedef ToolbarBuilder = Widget Function(
  BuildContext context,
  QuillController controller,
);

final class TopToolbar extends ToolbarConfig {
  const TopToolbar({
    super.style,
    super.sections,
    super.backgroundColor,
    super.padding,
    super.toolbarSize,
  });
}

final class BottomToolbar extends ToolbarConfig {
  const BottomToolbar({
    super.style,
    super.sections,
    super.backgroundColor,
    super.padding,
    super.toolbarSize,
  });
}

final class FloatingToolbar extends ToolbarConfig {
  const FloatingToolbar({
    this.position = FloatingToolbarPosition.topCenter,
    this.margin = const EdgeInsets.all(8),
    super.style,
    super.sections,
    super.backgroundColor,
    super.padding,
    super.toolbarSize,
  });
  final FloatingToolbarPosition position;
  final EdgeInsets margin;
}

final class NoToolbar extends ToolbarConfig {
  const NoToolbar() : super(sections: null);
}

/// Anchor point for [SelectionToolbar].
enum SelectionAnchor {
  /// Float above the selection rect (or above the editor top when the
  /// rect cannot be measured).
  above,

  /// Float below the selection rect (or below the editor bottom).
  below,
}

final class SelectionToolbar extends ToolbarConfig {
  const SelectionToolbar({
    this.anchor = SelectionAnchor.above,
    this.offset = 8,
    super.style,
    super.sections,
    super.backgroundColor,
    super.padding,
    super.toolbarSize,
  });
  final SelectionAnchor anchor;

  /// Pixel gap between the selection (or editor edge) and the toolbar.
  final double offset;
}

final class CustomToolbar extends ToolbarConfig {
  const CustomToolbar({
    required this.builder,
    this.placement = ToolbarPlacement.top,
  }) : super(sections: null);

  final ToolbarBuilder builder;
  final ToolbarPlacement placement;
}

/// Default button sets per [ToolbarStyle].
List<ToolbarButtonId> defaultButtonsFor(ToolbarStyle style) {
  switch (style) {
    case ToolbarStyle.minimal:
      return const [
        ToolbarButtonId.bold,
        ToolbarButtonId.italic,
        ToolbarButtonId.underline,
        ToolbarButtonId.link,
      ];
    case ToolbarStyle.compact:
      return const [
        ToolbarButtonId.undo,
        ToolbarButtonId.redo,
        ToolbarButtonId.bold,
        ToolbarButtonId.italic,
        ToolbarButtonId.underline,
        ToolbarButtonId.strike,
        ToolbarButtonId.color,
        ToolbarButtonId.background,
        ToolbarButtonId.link,
        ToolbarButtonId.listBullet,
        ToolbarButtonId.listNumber,
        ToolbarButtonId.blockquote,
        ToolbarButtonId.codeBlock,
        ToolbarButtonId.image,
      ];
    case ToolbarStyle.full:
      return ToolbarButtonId.values;
  }
}
