import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:quill_delta_editor/quill_delta_editor.dart';

/// Export the current editor contents to HTML, Markdown, Docx, and Delta
/// JSON. Demonstrates the converter family wired into a real UI.
class ExportDemo extends StatefulWidget {
  const ExportDemo({super.key});

  @override
  State<ExportDemo> createState() => _ExportDemoState();
}

class _ExportDemoState extends State<ExportDemo>
    with SingleTickerProviderStateMixin {
  late final QuillController _controller;
  late final TabController _tabs;
  String _html = '';
  String _markdown = '';
  String _docxSize = '';
  String _json = '';

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(_seed),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _tabs = TabController(length: 4, vsync: this);
    _refresh();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() async {
    final delta = _controller.document.toDelta();
    final html = await HtmlExporter(
      defaultOptions: const HtmlOptions(wrapDocument: false),
    ).export(delta);
    final md = await const MarkdownExporter().export(delta);
    final docx = await const DocxExporter().export(delta);
    final json = const JsonEncoder.withIndent('  ')
        .convert(delta.toJson());
    if (!mounted) return;
    setState(() {
      _html = html;
      _markdown = md;
      _docxSize = '${docx.length} bytes';
      _json = json;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-format export'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'HTML'),
            Tab(text: 'Markdown'),
            Tab(text: 'Docx'),
            Tab(text: 'Delta'),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 280,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: QuillDeltaEditor(
                  controller: _controller,
                  layout: const EditorLayoutConfig.expanded(),
                  toolbar: const ToolbarConfig.top(
                    style: ToolbarStyle.compact,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CodeView(text: _html),
                _CodeView(text: _markdown),
                _CodeView(text: 'Encoded $_docxSize as a .docx archive.'),
                _CodeView(text: _json),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeView extends StatelessWidget {
  const _CodeView({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
    );
  }
}

const _seed = [
  {'insert': 'Sample document'},
  {'insert': '\n', 'attributes': {'header': 1}},
  {'insert': 'A paragraph with '},
  {'insert': 'bold', 'attributes': {'bold': true}},
  {'insert': ' and '},
  {'insert': 'italic', 'attributes': {'italic': true}},
  {'insert': '.\n'},
  {'insert': 'feature one'},
  {'insert': '\n', 'attributes': {'list': 'bullet'}},
  {'insert': 'feature two'},
  {'insert': '\n', 'attributes': {'list': 'bullet'}},
];
