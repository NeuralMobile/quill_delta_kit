import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Fully custom toolbar built from individual flutter_quill button widgets.
class CustomToolbarDemo extends StatefulWidget {
  const CustomToolbarDemo({super.key});

  @override
  State<CustomToolbarDemo> createState() => _CustomToolbarDemoState();
}

class _CustomToolbarDemoState extends State<CustomToolbarDemo> {
  final _controller = QuillController.basic();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom toolbar')),
      body: QuillDeltaEditor(
        controller: _controller,
        layout: const EditorLayoutConfig.expanded(),
        toolbar: ToolbarConfig.custom(
          builder: (ctx, c) => _BrandedToolbar(controller: c),
          placement: ToolbarPlacement.top,
        ),
      ),
    );
  }
}

class _BrandedToolbar extends StatelessWidget {
  const _BrandedToolbar({required this.controller});
  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '✏️',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.bold,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(color: Colors.amber),
                iconButtonUnselectedData: IconButtonData(color: Colors.white),
              ),
            ),
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.italic,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(color: Colors.amber),
                iconButtonUnselectedData: IconButtonData(color: Colors.white),
              ),
            ),
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.underline,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(color: Colors.amber),
                iconButtonUnselectedData: IconButtonData(color: Colors.white),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Clear all',
            onPressed: () => controller.clear(),
          ),
        ],
      ),
    );
  }
}
