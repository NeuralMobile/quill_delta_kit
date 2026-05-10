import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../config/toolbar_config.dart';
import 'toolbar_renderer.dart';

/// Wraps an editor with an overlay-managed selection toolbar that appears
/// when the user has a non-collapsed selection (iOS-style context menu).
///
/// Anchors to the top or bottom of the editor's bounding rect. Pixel-exact
/// anchoring to the selection's first/last line would require digging into
/// flutter_quill's RenderEditor for endpoints; the editor-edge anchor is a
/// sensible default that covers the common UX without internal coupling.
class SelectionToolbarOverlay extends StatefulWidget {
  const SelectionToolbarOverlay({
    super.key,
    required this.controller,
    required this.config,
    required this.child,
  });

  final QuillController controller;
  final SelectionToolbar config;
  final Widget child;

  @override
  State<SelectionToolbarOverlay> createState() =>
      _SelectionToolbarOverlayState();
}

class _SelectionToolbarOverlayState extends State<SelectionToolbarOverlay> {
  final _editorKey = GlobalKey();
  OverlayEntry? _entry;
  bool _shown = false;

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
    if (sel.isCollapsed || !sel.isValid) {
      _hide();
    } else {
      _show();
    }
  }

  void _show() {
    if (_shown) {
      _entry?.markNeedsBuild();
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: false);
    if (overlay == null) return;
    _entry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_entry!);
    _shown = true;
  }

  void _hide() {
    if (!_shown) return;
    _entry?.remove();
    _entry = null;
    _shown = false;
  }

  Widget _buildOverlay(BuildContext _) {
    final box = _editorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return const SizedBox.shrink();
    }
    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    final cfg = widget.config;
    final anchor = cfg.anchor;

    return Positioned(
      left: origin.dx,
      top: anchor == SelectionAnchor.above
          ? null
          : origin.dy + size.height + cfg.offset,
      bottom: anchor == SelectionAnchor.above
          ? MediaQuery.of(context).size.height -
              origin.dy +
              cfg.offset
          : null,
      width: size.width,
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width.clamp(120.0, double.infinity),
          ),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            color: cfg.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: cfg.padding,
              child: buildSimpleToolbar(
                controller: widget.controller,
                config: cfg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Marking the editor with a GlobalKey lets _buildOverlay measure it.
    return KeyedSubtree(key: _editorKey, child: widget.child);
  }
}
