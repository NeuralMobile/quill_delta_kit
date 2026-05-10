import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show Document, FlutterQuillLocalizations, QuillSimpleToolbar;
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      home: Scaffold(body: SafeArea(child: child)),
    );

void main() {
  group('QuillDeltaEditor builds for each layout', () {
    testWidgets('autoGrow', (tester) async {
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.autoGrow(maxHeight: 200),
        toolbar: const ToolbarConfig.none(),
      )));
      expect(find.byType(QuillDeltaEditor), findsOneWidget);
      controller.dispose();
    });

    testWidgets('fixed height', (tester) async {
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.fixed(height: 240),
        toolbar: const ToolbarConfig.none(),
      )));
      expect(find.byType(SizedBox), findsWidgets);
      controller.dispose();
    });

    testWidgets('scrollable readOnly', (tester) async {
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(SizedBox(
        height: 300,
        child: QuillDeltaEditor(
          controller: controller,
          layout: const EditorLayoutConfig.scrollable(readOnly: true),
          toolbar: const ToolbarConfig.none(),
        ),
      )));
      await tester.pump();
      expect(controller.readOnly, true);
      controller.dispose();
    });

    testWidgets('expanded inside Column', (tester) async {
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(Column(
        children: [
          QuillDeltaEditor(
            controller: controller,
            layout: const EditorLayoutConfig.expanded(),
            toolbar: const ToolbarConfig.none(),
          ),
        ],
      )));
      expect(find.byType(QuillDeltaEditor), findsOneWidget);
      controller.dispose();
    });
  });

  group('Toolbar variants render', () {
    testWidgets('top toolbar', (tester) async {
      await tester.runAsync(() async {
        final controller = QuillController.basic();
        await tester.pumpWidget(_wrap(QuillDeltaEditor(
          controller: controller,
          layout: const EditorLayoutConfig.fixed(height: 200),
          toolbar: const ToolbarConfig.top(style: ToolbarStyle.minimal),
        )));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(QuillSimpleToolbar), findsOneWidget);
        controller.dispose();
      });
    });

    testWidgets('bottom toolbar', (tester) async {
      await tester.runAsync(() async {
        final controller = QuillController.basic();
        await tester.pumpWidget(_wrap(QuillDeltaEditor(
          controller: controller,
          layout: const EditorLayoutConfig.fixed(height: 200),
          toolbar: const ToolbarConfig.bottom(style: ToolbarStyle.compact),
        )));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(QuillSimpleToolbar), findsOneWidget);
        controller.dispose();
      });
    });

    testWidgets('floating toolbar uses Stack', (tester) async {
      // Use a fake toolbar builder to avoid flutter_quill's
      // QuillToolbarArrowIndicatedButtonList timer that fires post-teardown.
      // The floating layout itself (Stack + Positioned) is what we test here.
      await tester.runAsync(() async {
        final controller = QuillController.basic();
        await tester.pumpWidget(_wrap(SizedBox(
          width: 600,
          height: 400,
          child: QuillDeltaEditor(
            controller: controller,
            layout: const EditorLayoutConfig.fixed(height: 300),
            toolbar: ToolbarConfig.custom(
              builder: (ctx, c) => const SizedBox(
                key: Key('FAKE_FLOAT_TB'),
                width: 100,
                height: 30,
              ),
              placement: ToolbarPlacement.overlay,
            ),
          ),
        )));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(Stack), findsWidgets);
        expect(find.byKey(const Key('FAKE_FLOAT_TB')), findsOneWidget);
        controller.dispose();
      });
    });

    testWidgets('custom toolbar uses provided builder', (tester) async {
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.fixed(height: 200),
        toolbar: ToolbarConfig.custom(
          builder: (context, c) => const Text('CUSTOM_TB'),
        ),
      )));
      expect(find.text('CUSTOM_TB'), findsOneWidget);
      controller.dispose();
    });
  });

  group('Embed builders', () {
    testWidgets('image preview placeholder renders when no custom builder',
        (tester) async {
      final controller = QuillController(
        document: Document.fromJson([
          {
            'insert': {'image': 'https://x.test/a.png'}
          },
          {'insert': '\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.fixed(height: 240),
        toolbar: const ToolbarConfig.none(),
      )));
      await tester.pump();
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.textContaining('a.png'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('custom image builder is called', (tester) async {
      String? receivedUrl;
      final controller = QuillController(
        document: Document.fromJson([
          {
            'insert': {'image': 'https://x.test/auth.png'}
          },
          {'insert': '\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.fixed(height: 240),
        toolbar: const ToolbarConfig.none(),
        previewBuilders: MediaPreviewBuilders(
          imageBuilder: (ctx, url, meta) {
            receivedUrl = url;
            return const SizedBox(key: Key('CUSTOM_IMG'));
          },
        ),
      )));
      await tester.pump();
      expect(receivedUrl, 'https://x.test/auth.png');
      expect(find.byKey(const Key('CUSTOM_IMG')), findsOneWidget);
      controller.dispose();
    });
  });
}
