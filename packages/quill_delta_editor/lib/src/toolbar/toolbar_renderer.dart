import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../config/toolbar_config.dart';

/// Build a flutter_quill [QuillSimpleToolbar] from our [ToolbarConfig].
///
/// Only the buttons selected by [ToolbarConfig.sections] (or the default
/// for the [ToolbarStyle]) are enabled in the underlying flutter_quill
/// config. Buttons not in the set are hidden via the showXxx flags.
Widget buildSimpleToolbar({
  required QuillController controller,
  required ToolbarConfig config,
}) {
  final buttons = _resolveButtons(config);
  final cfg = _toolbarConfigFromButtons(buttons, config);
  return QuillSimpleToolbar(
    controller: controller,
    config: cfg,
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
    showInlineCode: has(ToolbarButtonId.inlineCode),
    showFontFamily: has(ToolbarButtonId.fontFamily),
    showFontSize: has(ToolbarButtonId.fontSize),
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
    showIndent: has(ToolbarButtonId.indent),
    showAlignmentButtons: has(ToolbarButtonId.alignLeft) ||
        has(ToolbarButtonId.alignCenter) ||
        has(ToolbarButtonId.alignRight) ||
        has(ToolbarButtonId.alignJustify),
    showClearFormat: has(ToolbarButtonId.clearFormat),
    showDividers: false,
    showSearchButton: has(ToolbarButtonId.search),
    showSubscript: false,
    showSuperscript: false,
    multiRowsDisplay: false,
    color: source.backgroundColor,
    toolbarSize: source.toolbarSize,
    sectionDividerColor: Colors.transparent,
  );
}
