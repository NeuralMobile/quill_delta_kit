import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../config/toolbar_config.dart';
import 'toolbar_renderer.dart';

/// Subclass of [MaterialTextSelectionControls] that renders our formatting
/// toolbar above (or below) the selection rect using the same machinery
/// that drives the platform copy/paste toolbar.
///
/// Why this rather than an OverlayEntry watcher:
/// flutter_quill's `RawEditor` already pipes `selectionMidpoint`,
/// `endpoints`, and `globalEditableRegion` into its [TextSelectionControls]
/// implementation, so positioning lands on the actual selection bubble — no
/// reaching into private RenderEditor APIs needed.
class QuillFormattingSelectionControls extends MaterialTextSelectionControls {
  QuillFormattingSelectionControls({
    required this.controller,
    required this.toolbarConfig,
  });

  final QuillController controller;
  final SelectionToolbar toolbarConfig;

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    final start = endpoints.first.point;
    final end = endpoints.length > 1 ? endpoints.last.point : start;
    final midX = selectionMidpoint.dx + globalEditableRegion.left;
    final aboveY = start.dy +
        globalEditableRegion.top -
        textLineHeight -
        toolbarConfig.offset;
    final belowY =
        end.dy + globalEditableRegion.top + toolbarConfig.offset;

    return _SelectionContextToolbar(
      anchorAbove: Offset(midX, aboveY),
      anchorBelow: Offset(midX, belowY),
      controller: controller,
      config: toolbarConfig,
    );
  }
}

class _SelectionContextToolbar extends StatelessWidget {
  const _SelectionContextToolbar({
    required this.anchorAbove,
    required this.anchorBelow,
    required this.controller,
    required this.config,
  });

  final Offset anchorAbove;
  final Offset anchorBelow;
  final QuillController controller;
  final SelectionToolbar config;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _SelectionToolbarLayoutDelegate(
        anchorAbove: anchorAbove,
        anchorBelow: anchorBelow,
        preferAbove: config.anchor == SelectionAnchor.above,
      ),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color:
            config.backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: config.padding,
          child: buildSimpleToolbar(
            controller: controller,
            config: config,
          ),
        ),
      ),
    );
  }
}

/// Picks the anchor that fits, falling back to the other side. Within the
/// chosen side, horizontally centers the toolbar on the anchor and clamps
/// to the viewport with an 8 px margin.
class _SelectionToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  _SelectionToolbarLayoutDelegate({
    required this.anchorAbove,
    required this.anchorBelow,
    required this.preferAbove,
  });

  final Offset anchorAbove;
  final Offset anchorBelow;
  final bool preferAbove;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final fitsAbove = anchorAbove.dy - childSize.height >= 0;
    final fitsBelow = anchorBelow.dy + childSize.height <= size.height;

    final bool placeAbove;
    if (preferAbove) {
      placeAbove = fitsAbove || !fitsBelow;
    } else {
      placeAbove = !fitsBelow && fitsAbove;
    }

    final anchor = placeAbove ? anchorAbove : anchorBelow;
    final y = placeAbove ? anchor.dy - childSize.height : anchor.dy;

    var x = anchor.dx - childSize.width / 2;
    x = x.clamp(8.0, (size.width - childSize.width - 8).clamp(8.0, size.width));
    return Offset(
      x,
      y.clamp(0.0, (size.height - childSize.height).clamp(0.0, size.height)),
    );
  }

  @override
  bool shouldRelayout(covariant _SelectionToolbarLayoutDelegate old) {
    return old.anchorAbove != anchorAbove ||
        old.anchorBelow != anchorBelow ||
        old.preferAbove != preferAbove;
  }
}
