import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../config/toolbar_config.dart';
import 'toolbar_renderer.dart';

/// Cross-platform selection-context toolbar that follows the actual
/// selection rect.
///
/// Why not [QuillEditorConfig.contextMenuBuilder]: flutter_quill skips its
/// Flutter selection toolbar on web (`if (kIsWeb) return false` inside
/// `QuillRawEditorState.showToolbar`) so the toolbar never appears in
/// browsers. We need the menu to work everywhere.
///
/// Approach: listen to [QuillController.selection]. On a non-collapsed
/// selection, read the active editor's [RenderEditor] via a
/// [GlobalKey] + `getEndpointsForSelection(...)` to get the start/end
/// points in editor-local coordinates, convert to screen coordinates,
/// and insert a positioned [OverlayEntry] above (or below) the selection.
class SelectionToolbarOverlay extends StatefulWidget {
  const SelectionToolbarOverlay({
    super.key,
    required this.controller,
    required this.config,
    required this.editorKey,
    required this.child,
  });

  final QuillController controller;
  final SelectionToolbar config;
  final GlobalKey<QuillEditorState> editorKey;
  final Widget child;

  @override
  State<SelectionToolbarOverlay> createState() => _SelectionToolbarOverlayState();
}

class _SelectionToolbarOverlayState extends State<SelectionToolbarOverlay> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant SelectionToolbarOverlay old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _hide();
    super.dispose();
  }

  void _onChange() {
    final sel = widget.controller.selection;
    if (!sel.isValid || sel.isCollapsed) {
      _hide();
      return;
    }
    // Build needs the RenderEditor, which is only available after the next
    // frame when selection state has settled.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cur = widget.controller.selection;
      if (!cur.isValid || cur.isCollapsed) return;
      _show();
    });
  }

  void _show() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    if (_entry == null) {
      _entry = OverlayEntry(builder: _buildOverlay);
      overlay.insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  /// Locate the active [RenderEditor] from the editor key. Returns null
  /// when the inner state hasn't mounted yet.
  RenderEditor? _renderEditor() {
    final qe = widget.editorKey.currentState;
    if (qe == null) return null;
    final raw = qe.editableTextKey.currentState;
    if (raw == null) return null;
    return raw.renderEditor;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final renderEditor = _renderEditor();
    if (renderEditor == null) return const SizedBox.shrink();
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return const SizedBox.shrink();
    }
    if (!renderEditor.attached || !renderEditor.hasSize) {
      return const SizedBox.shrink();
    }

    final endpoints = renderEditor.getEndpointsForSelection(selection);
    if (endpoints.isEmpty) return const SizedBox.shrink();
    final origin = renderEditor.localToGlobal(Offset.zero);
    final start = endpoints.first.point + origin;
    final end = endpoints.length > 1 ? endpoints.last.point + origin : start;
    // The endpoint y is at the BASELINE of the line. To get a top-of-line
    // position, subtract a heuristic line height. flutter_quill exposes
    // glyph height via _getGlyphHeights but it isn't public; 18 is a
    // sensible approximation for body text and the toolbar layout
    // delegate auto-flips to below if there's no room above.
    const lineHeight = 18.0;
    final aboveAnchor = Offset(
      (start.dx + end.dx) / 2,
      start.dy - lineHeight - widget.config.offset,
    );
    final belowAnchor = Offset(
      (start.dx + end.dx) / 2,
      end.dy + widget.config.offset,
    );

    // Bound the toolbar width: cap at a sensible popover size and clamp
    // to the available viewport so we never render edge-to-edge. The
    // toolbar's internal arrow-indicated button list scrolls horizontally
    // when its content exceeds this width.
    final screen = MediaQuery.of(overlayContext).size;
    const desired = 460.0;
    final maxWidth = (screen.width - 16).clamp(160.0, desired);

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: aboveAnchor,
        anchorBelow: belowAnchor,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: widget.config.backgroundColor ?? Theme.of(overlayContext).colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: widget.config.padding,
            child: buildSimpleToolbar(
              controller: widget.controller,
              config: widget.config,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
