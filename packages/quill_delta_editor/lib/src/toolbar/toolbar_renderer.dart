// ignore_for_file: experimental_member_use
//
// Clipboard buttons (cut/copy/paste) are flagged @experimental in
// flutter_quill 11.5. We forward them so toolbar parity is complete;
// callers opting in via [ToolbarButtonId.clipboard*] accept the upstream
// experimental risk.
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../config/toolbar_config.dart';

/// Build a flutter_quill [QuillSimpleToolbar] from our [ToolbarConfig].
///
/// The preset enum (and `sections`) decides which built-in buttons are
/// visible. Visual chrome (background, toolbarSize) comes from the preset.
/// [overrideConfig], if supplied, replaces the preset-derived config in full
/// — adopt this when you want to pass through any of the advanced
/// [QuillSimpleToolbarConfig] fields the preset does not expose
/// (iconTheme, dialogTheme, decoration, link / header dialog variants,
/// embed buttons, …). [builder] is the layered variant: it receives the
/// preset config and returns the final one, so callers can keep most preset
/// fields and `copyWith` (via [QuillSimpleToolbarConfigCopyWithX]) the few
/// they want to change. [builder] takes precedence over [overrideConfig].
Widget buildSimpleToolbar({
  required QuillController controller,
  required ToolbarConfig config,
  QuillSimpleToolbarConfig? overrideConfig,
  QuillSimpleToolbarConfig Function(QuillSimpleToolbarConfig preset)? builder,
}) {
  final preset = _toolbarConfigFromButtons(_resolveButtons(config), config);
  final QuillSimpleToolbarConfig resolved;
  if (builder != null) {
    resolved = builder(preset);
  } else if (overrideConfig != null) {
    resolved = overrideConfig;
  } else {
    resolved = preset;
  }
  return QuillSimpleToolbar(
    controller: controller,
    config: resolved,
  );
}

Set<ToolbarButtonId> _resolveButtons(ToolbarConfig c) {
  final sections = c.sections;
  if (sections != null && sections.isNotEmpty) {
    return {for (final s in sections) ...s.buttons};
  }
  return defaultButtonsFor(c.style).toSet();
}

QuillSimpleToolbarConfig _toolbarConfigFromButtons(
  Set<ToolbarButtonId> buttons,
  ToolbarConfig source,
) {
  bool has(ToolbarButtonId id) => buttons.contains(id);
  return QuillSimpleToolbarConfig(
    showBoldButton: has(ToolbarButtonId.bold),
    showItalicButton: has(ToolbarButtonId.italic),
    showUnderLineButton: has(ToolbarButtonId.underline),
    showStrikeThrough: has(ToolbarButtonId.strike),
    showSmallButton: has(ToolbarButtonId.small),
    showInlineCode: has(ToolbarButtonId.inlineCode),
    showSubscript: has(ToolbarButtonId.subscript),
    showSuperscript: has(ToolbarButtonId.superscript),
    showFontFamily: has(ToolbarButtonId.fontFamily),
    showFontSize: has(ToolbarButtonId.fontSize),
    showLineHeightButton: has(ToolbarButtonId.lineHeight),
    showColorButton: has(ToolbarButtonId.color),
    showBackgroundColorButton: has(ToolbarButtonId.background),
    showLink: has(ToolbarButtonId.link),
    showUndo: has(ToolbarButtonId.undo),
    showRedo: has(ToolbarButtonId.redo),
    showHeaderStyle: has(ToolbarButtonId.header),
    showListBullets: has(ToolbarButtonId.listBullet),
    showListNumbers: has(ToolbarButtonId.listNumber),
    showListCheck: has(ToolbarButtonId.listCheck),
    showQuote: has(ToolbarButtonId.blockquote),
    showCodeBlock: has(ToolbarButtonId.codeBlock),
    showLeftAlignment: has(ToolbarButtonId.alignLeft),
    showCenterAlignment: has(ToolbarButtonId.alignCenter),
    showRightAlignment: has(ToolbarButtonId.alignRight),
    showJustifyAlignment: has(ToolbarButtonId.alignJustify),
    showAlignmentButtons: has(ToolbarButtonId.alignLeft) ||
        has(ToolbarButtonId.alignCenter) ||
        has(ToolbarButtonId.alignRight) ||
        has(ToolbarButtonId.alignJustify),
    showIndent: has(ToolbarButtonId.indent),
    showDirection: has(ToolbarButtonId.direction),
    showClearFormat: has(ToolbarButtonId.clearFormat),
    showSearchButton: has(ToolbarButtonId.search),
    showClipboardCut: has(ToolbarButtonId.clipboardCut),
    showClipboardCopy: has(ToolbarButtonId.clipboardCopy),
    showClipboardPaste: has(ToolbarButtonId.clipboardPaste),
    showDividers: has(ToolbarButtonId.divider),
    multiRowsDisplay: source.multiRowsDisplay,
    customButtons: source.customButtons,
    color: source.backgroundColor,
    toolbarSize: source.toolbarSize,
    sectionDividerColor: source.sectionDividerColor,
  );
}
