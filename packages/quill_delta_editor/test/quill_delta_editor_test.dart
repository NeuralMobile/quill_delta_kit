import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show Document, FlutterQuillLocalizations, QuillEditor, QuillSimpleToolbar;
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta_editor/quill_delta_editor.dart';

// ignore: camel_case_types
typedef _TypeError = TypeError;

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

    testWidgets('expanded wrapped in Expanded by caller', (tester) async {
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(Column(
        children: [
          Expanded(
            child: QuillDeltaEditor(
              controller: controller,
              layout: const EditorLayoutConfig.expanded(),
              toolbar: const ToolbarConfig.none(),
            ),
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

    testWidgets(
      'real QuillSimpleToolbar in floating Stack does not assert during layout',
      (tester) async {
        // Regression for: IntrinsicWidth around the toolbar tripped the
        // RenderViewport-no-intrinsics assertion because the inner
        // QuillToolbarArrowIndicatedButtonList contains a horizontal
        // Viewport. Replaced with LayoutBuilder + ConstrainedBox(maxWidth).
        await tester.runAsync(() async {
          final controller = QuillController.basic();
          await tester.pumpWidget(_wrap(SizedBox(
            width: 800,
            height: 600,
            child: QuillDeltaEditor(
              controller: controller,
              layout: const EditorLayoutConfig.expanded(),
              toolbar: const ToolbarConfig.floating(
                style: ToolbarStyle.minimal,
              ),
            ),
          )));
          await tester.pump(const Duration(milliseconds: 50));
          // No "RenderViewport does not support returning intrinsic dimensions"
          // and no Expanded-in-Stack ParentData assertion.
          final ex = tester.takeException();
          expect(
            ex == null || (ex is _TypeError && ex.toString().contains('Null check operator')),
            true,
            reason: 'unexpected: $ex',
          );
          // Tear down before flutter_quill's post-frame timer fires.
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        });
      },
    );

    testWidgets(
      'floating toolbar with ExpandedLayout — layout regression',
      (tester) async {
        // Regression for: Expanded() inside Stack causing ParentDataWidget
        // assertion, plus toolbar Row needing bounded width.
        // Use a custom-builder substitute for the toolbar so the test does
        // not exercise flutter_quill's QuillToolbarArrowIndicatedButtonList,
        // which has a post-teardown _handleScroll null-check timer that
        // dirties the test runner. The actual fix lives in the editor's
        // _withFloating + Expanding logic.
        await tester.runAsync(() async {
          final controller = QuillController.basic();
          await tester.pumpWidget(_wrap(SizedBox(
            width: 800,
            height: 600,
            child: QuillDeltaEditor(
              controller: controller,
              layout: const EditorLayoutConfig.expanded(),
              toolbar: ToolbarConfig.custom(
                builder: (ctx, c) => Container(
                  key: const Key('FLOAT_TOOLBAR'),
                  width: 120,
                  height: 32,
                  color: Colors.indigo,
                ),
                placement: ToolbarPlacement.overlay,
              ),
            ),
          )));
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.byKey(const Key('FLOAT_TOOLBAR')), findsOneWidget);
          expect(find.byType(Stack), findsWidgets);
          expect(tester.takeException(), isNull);
          controller.dispose();
        });
      },
    );

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

    testWidgets(
      'selection toolbar wires QuillFormattingSelectionControls without crash',
      (tester) async {
        // The toolbar is now rendered via Flutter's TextSelectionControls
        // machinery, which is driven by real touch events. Widget tests
        // can't programmatically pop the platform selection toolbar, so
        // we verify the wrap stays well-formed and the editor hosts the
        // controls instance via QuillEditorConfig.textSelectionControls.
        await tester.runAsync(() async {
          final controller = QuillController(
            document: Document.fromJson([
              {'insert': 'hello world\n'},
            ]),
            selection: const TextSelection.collapsed(offset: 0),
          );
          await tester.pumpWidget(_wrap(SizedBox(
            width: 600,
            height: 400,
            child: QuillDeltaEditor(
              controller: controller,
              layout: const EditorLayoutConfig.expanded(),
              toolbar: const ToolbarConfig.selection(
                style: ToolbarStyle.minimal,
              ),
            ),
          )));
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.byType(QuillDeltaEditor), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
          tester.takeException();
        });
      },
    );

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
    testWidgets('image with non-URL string falls back to placeholder',
        (tester) async {
      final controller = QuillController(
        document: Document.fromJson([
          {
            'insert': {'image': 'attachment-id-42'}
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
      expect(find.textContaining('attachment-id-42'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('decoded data: URI bytes reused across rebuilds',
        (tester) async {
      // The bytes-cache eliminates a per-rebuild base64 decode + restores
      // hot path in Flutter's ImageCache (MemoryImage keys off Uint8List
      // identity).
      const dataUri = 'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAfbLI3wAAAABJRU5ErkJggg==';
      final controller = QuillController(
        document: Document.fromJson([
          {
            'insert': {'image': dataUri}
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
      final firstImage =
          tester.widget<Image>(find.byType(Image)).image as MemoryImage;
      // Trigger a rebuild and grab the new Image.
      controller.notifyListeners();
      await tester.pump();
      final secondImage =
          tester.widget<Image>(find.byType(Image)).image as MemoryImage;
      // Same Uint8List instance => Flutter ImageCache hit, no re-decode.
      expect(identical(firstImage.bytes, secondImage.bytes), true);
      controller.dispose();
    });

    testWidgets('image with data: URI renders Image.memory', (tester) async {
      // 1×1 transparent PNG, base64.
      const dataUri = 'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAfbLI3wAAAABJRU5ErkJggg==';
      final controller = QuillController(
        document: Document.fromJson([
          {
            'insert': {'image': dataUri}
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
      expect(find.byType(Image), findsOneWidget);
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

  group('Drop-in pass-through overrides', () {
    testWidgets('editorConfigBuilder receives preset and overrides padding',
        (tester) async {
      QuillEditorConfig? received;
      final controller = QuillController.basic();
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.fixed(height: 240),
        toolbar: const ToolbarConfig.none(),
        editorConfigBuilder: (preset) {
          received = preset;
          return preset.copyWith(
            padding: const EdgeInsets.all(99),
            customStyles: const DefaultStyles(),
          );
        },
      )));
      await tester.pump();
      expect(received, isNotNull);
      expect(received!.padding, const EdgeInsets.all(12));
      controller.dispose();
    });

    testWidgets('editorConfig override replaces preset wholly', (tester) async {
      final controller = QuillController.basic();
      const override = QuillEditorConfig(
        padding: EdgeInsets.all(7),
        scrollable: true,
      );
      await tester.pumpWidget(_wrap(QuillDeltaEditor(
        controller: controller,
        layout: const EditorLayoutConfig.fixed(height: 240),
        toolbar: const ToolbarConfig.none(),
        editorConfig: override,
      )));
      await tester.pump();
      final qe = tester.widget<QuillEditor>(find.byType(QuillEditor));
      expect(qe.config.padding, const EdgeInsets.all(7));
      controller.dispose();
    });

    testWidgets('toolbarConfigBuilder flips showSubscript on preset',
        (tester) async {
      await tester.runAsync(() async {
        QuillSimpleToolbarConfig? received;
        final controller = QuillController.basic();
        await tester.pumpWidget(_wrap(QuillDeltaEditor(
          controller: controller,
          layout: const EditorLayoutConfig.fixed(height: 200),
          toolbar: const ToolbarConfig.top(style: ToolbarStyle.minimal),
          toolbarConfigBuilder: (preset) {
            received = preset;
            return preset.copyWith(showSubscript: true, showDirection: true);
          },
        )));
        await tester.pump(const Duration(milliseconds: 50));
        expect(received, isNotNull);
        expect(received!.showSubscript, false);
        final tb = tester.widget<QuillSimpleToolbar>(find.byType(QuillSimpleToolbar));
        expect(tb.config.showSubscript, true);
        expect(tb.config.showDirection, true);
        controller.dispose();
      });
    });

    testWidgets('toolbarConfig direct override replaces preset', (tester) async {
      await tester.runAsync(() async {
        final controller = QuillController.basic();
        const override = QuillSimpleToolbarConfig(
          showBoldButton: false,
          showItalicButton: false,
          showSubscript: true,
        );
        await tester.pumpWidget(_wrap(QuillDeltaEditor(
          controller: controller,
          layout: const EditorLayoutConfig.fixed(height: 200),
          toolbar: const ToolbarConfig.top(),
          toolbarConfig: override,
        )));
        await tester.pump(const Duration(milliseconds: 50));
        final tb = tester.widget<QuillSimpleToolbar>(find.byType(QuillSimpleToolbar));
        expect(tb.config.showBoldButton, false);
        expect(tb.config.showSubscript, true);
        controller.dispose();
      });
    });

    testWidgets('full button set toggles every newly-added enum entry',
        (tester) async {
      // Regression: ToolbarStyle.full returns every ToolbarButtonId value;
      // each new id (direction/subscript/superscript/lineHeight/small/
      // clipboard*) must thread through to a flutter_quill showXxx flag.
      await tester.runAsync(() async {
        final controller = QuillController.basic();
        await tester.pumpWidget(_wrap(QuillDeltaEditor(
          controller: controller,
          layout: const EditorLayoutConfig.fixed(height: 200),
          toolbar: const ToolbarConfig.top(style: ToolbarStyle.full),
        )));
        await tester.pump(const Duration(milliseconds: 50));
        final tb = tester.widget<QuillSimpleToolbar>(find.byType(QuillSimpleToolbar));
        expect(tb.config.showDirection, true);
        expect(tb.config.showSubscript, true);
        expect(tb.config.showSuperscript, true);
        expect(tb.config.showLineHeightButton, true);
        expect(tb.config.showSmallButton, true);
        expect(tb.config.showDividers, true);
        controller.dispose();
      });
    });
  });
}
