import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'config/editor_layout.dart';
import 'config/toolbar_config.dart';
import 'embeds/media_embed_builder.dart';
import 'embeds/media_preview_builders.dart';
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
    final editor = _buildEditor(context);
    return _wrapWithToolbar(context, editor);
  }

  Widget _buildEditor(BuildContext context) {
    final layout = widget.layout;
    final builders = _resolvedEmbedBuilders();
    final padding = layout.padding;
    final placeholder = layout.placeholder;

    final editorConfig = QuillEditorConfig(
      padding: padding,
      placeholder: placeholder,
      autoFocus: layout.autoFocus,
      embedBuilders: builders,
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
      focusNode: _focusNode,
      scrollController: _scrollController,
      controller: widget.controller,
      config: editorConfig,
    );

    return switch (layout) {
      FixedHeightLayout(:final height) => SizedBox(height: height, child: core),
      ExpandedLayout() => Expanded(child: core),
      _ => core,
    };
  }

  Widget _wrapWithToolbar(BuildContext context, Widget editor) {
    final tb = widget.toolbar;
    return switch (tb) {
      NoToolbar() => editor,
      TopToolbar() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolbarChrome(buildSimpleToolbar(controller: widget.controller, config: tb), tb),
            editor,
          ],
        ),
      BottomToolbar() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            editor,
            _toolbarChrome(buildSimpleToolbar(controller: widget.controller, config: tb), tb),
          ],
        ),
      FloatingToolbar(:final position, :final margin) => _withFloating(
          editor,
          buildSimpleToolbar(controller: widget.controller, config: tb),
          position,
          margin,
          tb,
        ),
      CustomToolbar(:final builder, :final placement) =>
        _withCustom(editor, builder(context, widget.controller), placement),
    };
  }

  Widget _toolbarChrome(Widget child, ToolbarConfig config) {
    return Container(
      color: config.backgroundColor,
      padding: config.padding,
      child: child,
    );
  }

  Widget _withFloating(
    Widget editor,
    Widget toolbar,
    FloatingToolbarPosition position,
    EdgeInsets margin,
    ToolbarConfig config,
  ) {
    return Stack(
      children: [
        editor,
        Positioned(
          top: position == FloatingToolbarPosition.topCenter ||
                  position == FloatingToolbarPosition.topRight
              ? margin.top
              : null,
          bottom: position == FloatingToolbarPosition.bottomCenter ||
                  position == FloatingToolbarPosition.bottomRight
              ? margin.bottom
              : null,
          left: position == FloatingToolbarPosition.topCenter ||
                  position == FloatingToolbarPosition.bottomCenter
              ? margin.left
              : null,
          right: position == FloatingToolbarPosition.topRight ||
                  position == FloatingToolbarPosition.bottomRight
              ? margin.right
              : null,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: config.backgroundColor ?? Theme.of(context).cardColor,
            child: Padding(padding: config.padding, child: toolbar),
          ),
        ),
      ],
    );
  }

  Widget _withCustom(Widget editor, Widget toolbar, ToolbarPlacement placement) {
    return switch (placement) {
      ToolbarPlacement.top =>
        Column(mainAxisSize: MainAxisSize.min, children: [toolbar, editor]),
      ToolbarPlacement.bottom =>
        Column(mainAxisSize: MainAxisSize.min, children: [editor, toolbar]),
      ToolbarPlacement.overlay =>
        Stack(children: [editor, Positioned.fill(child: toolbar)]),
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
