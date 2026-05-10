import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../config/toolbar_config.dart';
import 'toolbar_renderer.dart';

/// Builds the selection-context toolbar that flutter_quill renders via
/// [QuillEditorConfig.contextMenuBuilder]. Replaces the platform copy/paste
/// toolbar with our formatting toolbar, anchored to the actual selection
/// rect via [TextSelectionToolbarLayoutDelegate] (iOS-style).
///
/// `state.contextMenuAnchors` exposes the [TextSelectionToolbarAnchors]
/// computed by flutter_quill from `renderEditor.getEndpointsForSelection`,
/// so the toolbar lands directly above (or below, if it doesn't fit) the
/// selected text.
QuillEditorContextMenuBuilder buildSelectionContextMenuBuilder({
  required QuillController controller,
  required SelectionToolbar config,
}) {
  return (BuildContext context, QuillRawEditorState state) {
    final anchors = state.contextMenuAnchors;
    final anchorAbove = anchors.primaryAnchor;
    final anchorBelow = anchors.secondaryAnchor ?? anchors.primaryAnchor;

    return TextFieldTapRegion(
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchorAbove,
          anchorBelow: anchorBelow,
        ),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: config.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: config.padding,
            child: buildSimpleToolbar(
              controller: controller,
              config: config,
            ),
          ),
        ),
      ),
    );
  };
}
