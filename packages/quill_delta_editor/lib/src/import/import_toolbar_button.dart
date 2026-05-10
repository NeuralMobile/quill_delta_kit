import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'quill_document_importer.dart';

/// Lightweight source descriptor returned by a file picker callback.
///
/// Provide exactly one of [bytes] (for binary formats like .docx) or
/// [text] (for text formats like .html / .md). [filename] / [mime] /
/// [format] are optional hints used by the converter registry to pick
/// the right importer.
class ImportSource {
  const ImportSource({
    this.bytes,
    this.text,
    this.filename,
    this.mime,
    this.format,
  }) : assert(bytes != null || text != null,
            'ImportSource needs either bytes or text');

  final List<int>? bytes;
  final String? text;
  final String? filename;
  final String? mime;
  final String? format;
}

/// Callback the toolbar button invokes when the user taps it. Return null
/// when the user cancels the picker.
///
/// Editor package keeps no opinion on file-picker plumbing — host app
/// supplies whatever picker fits (`file_picker`, `image_picker`, a custom
/// share-sheet handler, drag-drop bytes, etc.).
typedef ImportSourcePicker = Future<ImportSource?> Function(
    BuildContext context);

/// Builds a [QuillToolbarCustomButtonOptions] you can drop into
/// [ToolbarConfig.customButtons] (or directly into flutter_quill's
/// `customButtons` config) to add an "import document" action to the
/// toolbar.
///
/// On press:
///   1. Calls [pickSource] for the file/bytes/text to import.
///   2. Routes through [QuillDocumentImporter.insertBytesAtCursor] /
///      [QuillDocumentImporter.insertTextAtCursor] so the imported
///      content lands at the current selection, not replacing the doc.
///   3. Notifies the caller via [onError] when conversion fails.
QuillToolbarCustomButtonOptions buildImportDocumentButton({
  required QuillController controller,
  required ImportSourcePicker pickSource,
  QuillDocumentImporter? importer,
  Widget? icon,
  String tooltip = 'Insert document',
  void Function(Object error, StackTrace stackTrace)? onError,
}) {
  final imp = importer ?? QuillDocumentImporter();
  return QuillToolbarCustomButtonOptions(
    icon: icon ?? const Icon(Icons.attach_file),
    tooltip: tooltip,
    childBuilder: null,
    onPressed: () async {
      // The `onPressed` signature has no BuildContext, so the picker
      // receives a root navigator context via a stashed lookup. In
      // practice we attach a no-context fallback — most pickers don't
      // need a BuildContext for the picker itself, they show platform
      // UI.
      final source = await pickSource(_pickerContext);
      if (source == null) return;
      try {
        if (source.text != null) {
          await imp.insertTextAtCursor(
            controller: controller,
            text: source.text!,
            format: source.format,
            mime: source.mime,
          );
        } else if (source.bytes != null) {
          await imp.insertBytesAtCursor(
            controller: controller,
            bytes: source.bytes!,
            format: source.format,
            mime: source.mime,
            filename: source.filename,
          );
        }
      } catch (e, st) {
        if (onError != null) {
          onError(e, st);
        } else {
          // Best-effort surface in debug mode.
          assert(() {
            // ignore: avoid_print
            print('Import failed: $e\n$st');
            return true;
          }());
        }
      }
    },
  );
}

/// Fallback context used when [QuillToolbarCustomButtonOptions.onPressed]
/// fires without a BuildContext. Host apps that need a real context to
/// drive their picker can capture one via a stateful wrapper and pass it
/// in via a closure when calling [buildImportDocumentButton].
final BuildContext _pickerContext = _NoContext();

class _NoContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
