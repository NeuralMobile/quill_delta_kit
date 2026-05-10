import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'config/editor_layout.dart';
import 'config/toolbar_config.dart';
import 'embeds/media_embed_builder.dart';
import 'embeds/media_preview_builders.dart';
import 'toolbar/selection_toolbar_overlay.dart';
import 'toolbar/toolbar_renderer.dart';

/// Main editor widget. Wraps `flutter_quill`'s [QuillEditor] +
/// [QuillSimpleToolbar] with configurable layout and toolbar placement,
/// pluggable media preview builders, and integration hooks for the
/// quill_delta_* converter family.
///
/// Minimal usage:
/// ```dart
/// QuillDeltaEditor(controller: controller)
/// ```
///
/// Common configurations:
/// ```dart
/// // Auto-grow inside a Form / Column
/// QuillDeltaEditor(
///   controller: controller,
///   layout: const EditorLayoutConfig.autoGrow(maxHeight: 400),
///   toolbar: const ToolbarConfig.bottom(),
/// );
///
/// // Read-only viewer with floating toolbar
/// QuillDeltaEditor(
///   controller: controller,
///   layout: const EditorLayoutConfig.scrollable(readOnly: true),
///   toolbar: const ToolbarConfig.none(),
/// );
///
/// // Auth-injected image preview
/// QuillDeltaEditor(
///   controller: controller,
///   previewBuilders: MediaPreviewBuilders(
///     imageBuilder: (ctx, url, meta) => Image.network(url,
///       headers: {'Authorization': 'Bearer $token'}),
///   ),
/// );
/// ```
class QuillDeltaEditor extends StatefulWidget {
  const QuillDeltaEditor({
    super.key,
    required this.controller,
    this.layout = const EditorLayoutConfig.autoGrow(),
    this.toolbar = const ToolbarConfig.top(),
    this.previewBuilders,
    this.embedBuilders,
    this.focusNode,
    this.scrollController,
    this.onSelectionChanged,
  });

  /// flutter_quill document controller. Caller owns lifecycle.
  final QuillController controller;
  final EditorLayoutConfig layout;
  final ToolbarConfig toolbar;

  /// Per-media-type preview builders. Null entries fall back to a styled
  /// placeholder.
  final MediaPreviewBuilders? previewBuilders;

  /// Additional embed builders appended after the wrapper's media builders.
  /// Use to register custom embed types (formulas, mentions, dividers, ...).
  final List<EmbedBuilder>? embedBuilders;

  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final void Function(TextSelection)? onSelectionChanged;

  @override
  State<QuillDeltaEditor> createState() => _QuillDeltaEditorState();
}

class _QuillDeltaEditorState extends State<QuillDeltaEditor> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final ScrollController _scrollController =
      widget.scrollController ?? ScrollController();
  // Used by SelectionToolbarOverlay to reach the RenderEditor for endpoint
  // measurement.
  final GlobalKey<QuillEditorState> _quillEditorKey =
      GlobalKey<QuillEditorState>();

  bool get _ownFocus => widget.focusNode == null;
  bool get _ownScroll => widget.scrollController == null;

  @override
  void initState() {
    super.initState();
    final cb = widget.onSelectionChanged;
    if (cb != null) {
      widget.controller.addListener(_onChange);
    }
    if (widget.layout.readOnly) {
      widget.controller.readOnly = true;
    }
  }

  @override
  void didUpdateWidget(covariant QuillDeltaEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.layout.readOnly != oldWidget.layout.readOnly) {
      widget.controller.readOnly = widget.layout.readOnly;
    }
  }

  void _onChange() {
    final cb = widget.onSelectionChanged;
    if (cb != null) cb(widget.controller.selection);
  }

  @override
  void dispose() {
    if (_ownFocus) _focusNode.dispose();
    if (_ownScroll) _scrollController.dispose();
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _wrapWithToolbar(context);
  }

  /// Build the [QuillEditor] core (no parent-data wrappers like [Expanded] or
  /// [Positioned]). The toolbar wrapper decides how to size it for its
  /// chosen container (Column, Stack, etc.).
  Widget _buildEditorCore() {
    final layout = widget.layout;
    final editorConfig = QuillEditorConfig(
      padding: layout.padding,
      placeholder: layout.placeholder,
      autoFocus: layout.autoFocus,
      embedBuilders: _resolvedEmbedBuilders(),
      scrollable: switch (layout) {
        ScrollableLayout() || FixedHeightLayout() || ExpandedLayout() => true,
        AutoGrowLayout() => false,
      },
      expands: layout is ExpandedLayout,
      minHeight: layout is AutoGrowLayout ? layout.minHeight : null,
      maxHeight: switch (layout) {
        AutoGrowLayout(:final maxHeight) => maxHeight,
        FixedHeightLayout(:final height) => height,
        _ => null,
      },
    );

    final core = QuillEditor(
      key: _quillEditorKey,
      focusNode: _focusNode,
      scrollController: _scrollController,
      controller: widget.controller,
      config: editorConfig,
    );

    return switch (layout) {
      FixedHeightLayout(:final height) => SizedBox(height: height, child: core),
      _ => core,
    };
  }

  /// True when the layout asks the widget to fill its parent's vertical
  /// constraints. The toolbar wrapper uses this to pick the right
  /// container-specific sizing widget ([Expanded] inside Column,
  /// [Positioned.fill] inside Stack, [SizedBox.expand] for a no-toolbar
  /// solo layout).
  bool get _expanding => widget.layout is ExpandedLayout;

  Widget _wrapWithToolbar(BuildContext context) {
    final tb = widget.toolbar;
    final core = _buildEditorCore();
    return switch (tb) {
      // No toolbar: caller controls the parent constraints. For ExpandedLayout
      // the caller wraps us in Expanded / SizedBox.expand themselves; we don't
      // do it here because we cannot tell whether the parent is a Flex.
      NoToolbar() => core,
      TopToolbar() => Column(
          mainAxisSize: _expanding ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _toolbarChrome(
              buildSimpleToolbar(controller: widget.controller, config: tb),
              tb,
            ),
            if (_expanding) Expanded(child: core) else core,
          ],
        ),
      BottomToolbar() => Column(
          mainAxisSize: _expanding ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (_expanding) Expanded(child: core) else core,
            _toolbarChrome(
              buildSimpleToolbar(controller: widget.controller, config: tb),
              tb,
            ),
          ],
        ),
      FloatingToolbar(:final position, :final margin) => _withFloating(
          context: context,
          editor: core,
          toolbar: buildSimpleToolbar(
            controller: widget.controller,
            config: tb,
          ),
          position: position,
          margin: margin,
          config: tb,
        ),
      // SelectionToolbar uses an OverlayEntry watcher anchored to
      // RenderEditor.getEndpointsForSelection. Cross-platform (works on
      // web, where flutter_quill suppresses its built-in selection
      // toolbar via kIsWeb).
      SelectionToolbar() => SelectionToolbarOverlay(
          controller: widget.controller,
          config: tb,
          editorKey: _quillEditorKey,
          child: _expanding ? SizedBox.expand(child: core) : core,
        ),
      CustomToolbar(:final builder, :final placement) =>
        _withCustom(core, builder(context, widget.controller), placement),
    };
  }

  Widget _toolbarChrome(Widget child, ToolbarConfig config) {
    return Container(
      color: config.backgroundColor,
      padding: config.padding,
      child: child,
    );
  }

  /// Layered toolbar over editor.
  ///
  /// Editor is wrapped in [Positioned.fill] when the layout is
  /// [ExpandedLayout] so the [Stack] sizes correctly to its parent.
  ///
  /// flutter_quill's QuillSimpleToolbar contains an internally-scrolling
  /// Viewport (QuillToolbarArrowIndicatedButtonList). Two constraints we
  /// must satisfy:
  ///   - The toolbar Row needs a bounded incoming width or its non-zero
  ///     flex children assert.
  ///   - We cannot wrap the toolbar in [IntrinsicWidth]: the inner
  ///     Viewport refuses intrinsic dimension queries.
  /// Solution: read the parent width via [LayoutBuilder] and pass it to
  /// the [Positioned] as an explicit `width`, leaving margins as Positioned
  /// inset values.
  Widget _withFloating({
    required BuildContext context,
    required Widget editor,
    required Widget toolbar,
    required FloatingToolbarPosition position,
    required EdgeInsets margin,
    required ToolbarConfig config,
  }) {
    final isTop = position == FloatingToolbarPosition.topCenter ||
        position == FloatingToolbarPosition.topRight;
    final isBottom = position == FloatingToolbarPosition.bottomCenter ||
        position == FloatingToolbarPosition.bottomRight;
    final isLeftish = position == FloatingToolbarPosition.topCenter ||
        position == FloatingToolbarPosition.bottomCenter;
    final isRightish = position == FloatingToolbarPosition.topRight ||
        position == FloatingToolbarPosition.bottomRight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth - margin.horizontal)
                .clamp(120.0, double.infinity)
            : double.infinity;
        return Stack(
          children: [
            if (_expanding) Positioned.fill(child: editor) else editor,
            Positioned(
              top: isTop ? margin.top : null,
              bottom: isBottom ? margin.bottom : null,
              left: isLeftish ? margin.left : null,
              right: isRightish ? margin.right : null,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: config.backgroundColor ?? Theme.of(context).cardColor,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: config.padding,
                    child: toolbar,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _withCustom(Widget editor, Widget toolbar, ToolbarPlacement placement) {
    return switch (placement) {
      ToolbarPlacement.top => Column(
          mainAxisSize: _expanding ? MainAxisSize.max : MainAxisSize.min,
          children: [
            toolbar,
            if (_expanding) Expanded(child: editor) else editor,
          ],
        ),
      ToolbarPlacement.bottom => Column(
          mainAxisSize: _expanding ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (_expanding) Expanded(child: editor) else editor,
            toolbar,
          ],
        ),
      ToolbarPlacement.overlay => Stack(
          children: [
            if (_expanding) Positioned.fill(child: editor) else editor,
            Positioned.fill(child: toolbar),
          ],
        ),
    };
  }

  List<EmbedBuilder> _resolvedEmbedBuilders() {
    final pb = widget.previewBuilders;
    final media = <EmbedBuilder>[
      MediaEmbedBuilder.image(customBuilder: pb?.imageBuilder),
      MediaEmbedBuilder.video(customBuilder: pb?.videoBuilder),
      MediaEmbedBuilder.audio(customBuilder: pb?.audioBuilder),
    ];
    return [...media, ...?widget.embedBuilders];
  }
}
