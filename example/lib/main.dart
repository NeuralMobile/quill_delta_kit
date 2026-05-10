import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart' as dqd;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:quill_delta_html/quill_delta_html.dart';

import 'embeds.dart';
import 'fixtures.dart';
import 'word_html_cleaner.dart';
import 'word_import.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'quill_delta_html example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        fq.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('es'), Locale('fr')],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late fq.QuillController _controller;
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final _codec = QuillHtmlCodec(
    adapters: [
      AudioAdapter(),
      LoomAdapter(),
      SpotifyAdapter(),
      CodePenAdapter(),
      TweetAdapter(),
      TableAdapter(),
    ],
    options: const QuillHtmlOptions(
      wrapDocument: true,
      iframePolicy: IframePolicy(
        allowedSchemes: {'https'},
        allowedAttrs: {
          'src',
          'width',
          'height',
          'allow',
          'allowfullscreen',
          'sandbox',
          'title',
          'loading',
          'referrerpolicy',
          'frameborder',
        },
      ),
    ),
  );

  String _encodedHtml = '';
  String _decodedDeltaJson = '';
  String _roundTripStatus = '';
  String _selectedFixture = 'Empty';

  @override
  void initState() {
    super.initState();
    _controller = fq.QuillController.basic();
    _controller.document.changes.listen((_) => _refresh());
    _refresh();
  }

  void _refresh() {
    final delta = _controller.document.toDelta();
    final json = delta.toJson();
    final html = _codec.encode(dqd.Delta.fromJson(json));
    final back = _codec.decode(html).toJson();
    final ok = _semanticEqual(json, back);
    setState(() {
      _encodedHtml = html;
      _decodedDeltaJson = const JsonEncoder.withIndent('  ').convert(back);
      _roundTripStatus = ok ? 'lossless ✓' : 'mismatch ✗';
    });
  }

  bool _semanticEqual(List<dynamic> a, List<dynamic> b) {
    final na = _normalize(a);
    final nb = _normalize(b);
    return jsonEncode(na) == jsonEncode(nb);
  }

  List<Map<String, dynamic>> _normalize(List<dynamic> ops) {
    final delta = dqd.Delta();
    for (final op in ops) {
      final m = op as Map<String, dynamic>;
      final insert = m['insert'];
      final attrs = (m['attributes'] as Map?)?.cast<String, dynamic>();
      delta.insert(insert, attrs);
    }
    return delta.toJson();
  }

  void _loadFixture(String name) {
    final ops = fixtures[name]!;
    _controller.document = fq.Document.fromJson(ops);
    setState(() => _selectedFixture = name);
    _refresh();
  }

  void _loadHtmlFixture(String html) {
    final delta = _codec.decode(html);
    _controller.document = fq.Document.fromJson(delta.toJson());
    _refresh();
  }

  Future<void> _importDocx() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    try {
      final delta = await WordImporter().docxToDelta(bytes);
      _controller.document = fq.Document.fromJson(delta.toJson());
      setState(() => _selectedFixture = 'docx: ${picked!.files.single.name}');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('docx import failed: $e')),
      );
    }
  }

  Future<void> _pasteHtml() async {
    // Try HTML format first; fall back to plain text. Flutter's Clipboard.getData
    // officially supports only Clipboard.kTextPlain — pasting from Word reliably
    // requires the manual dialog (next button) on most platforms.
    final data = await Clipboard.getData('text/html');
    var html = data?.text;
    if (html == null || html.isEmpty) {
      final fallback = await Clipboard.getData(Clipboard.kTextPlain);
      html = fallback?.text;
    }
    if (html == null || html.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard empty — try the "Paste HTML…" dialog')),
      );
      return;
    }
    _ingestHtml(html, source: 'paste');
  }

  Future<void> _pasteHtmlDialog() async {
    final controller = TextEditingController();
    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Paste HTML'),
          content: SizedBox(
            width: 600,
            height: 360,
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Paste HTML from Word, web, etc. then press Import.',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    if (pasted == null || pasted.trim().isEmpty) return;
    _ingestHtml(pasted, source: 'paste-dialog');
  }

  void _ingestHtml(String html, {required String source}) {
    final cleaned = WordHtmlCleaner.isWordHtml(html) ? WordHtmlCleaner.clean(html) : html;
    final delta = _codec.decode(cleaned);
    _controller.document = fq.Document.fromJson(delta.toJson());
    setState(() => _selectedFixture = source);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('quill_delta_html example'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _roundTripStatus,
                style: TextStyle(
                  color: _roundTripStatus.endsWith('✓') ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFixtureBar(),
          SizedBox(
            height: 56,
            child: fq.QuillSimpleToolbar(
              controller: _controller,
              config: const fq.QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: _Panel(
                    title: 'flutter_quill editor',
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: fq.QuillEditor.basic(
                        controller: _controller,
                        scrollController: _scrollCtrl,
                        focusNode: _focusNode,
                        config: fq.QuillEditorConfig(
                          padding: const EdgeInsets.all(8),
                          embedBuilders: exampleEmbedBuilders(),
                          unknownEmbedBuilder: unknownEmbedBuilder(),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _Panel(
                    title: 'Encoded HTML',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: SelectableText(
                        _encodedHtml,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _Panel(
                    title: 'Round-trip Delta',
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: SelectableText(
                        _decodedDeltaJson,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixtureBar() {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 140),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Δ Fixture:', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final name in fixtures.keys)
                ChoiceChip(
                  label: Text(name),
                  selected: _selectedFixture == name,
                  onSelected: (_) => _loadFixture(name),
                ),
              const SizedBox(width: 16),
              const Text('HTML in:', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final entry in htmlFixtures.entries)
                ActionChip(
                  label: Text(entry.key),
                  onPressed: () => _loadHtmlFixture(entry.value),
                ),
              const SizedBox(width: 16),
              const Text('Import:', style: TextStyle(fontWeight: FontWeight.bold)),
              ActionChip(
                avatar: const Icon(Icons.upload_file, size: 16),
                label: const Text('.docx'),
                onPressed: _importDocx,
              ),
              ActionChip(
                avatar: const Icon(Icons.content_paste, size: 16),
                label: const Text('Paste HTML'),
                onPressed: _pasteHtml,
              ),
              ActionChip(
                avatar: const Icon(Icons.edit_note, size: 16),
                label: const Text('Paste HTML…'),
                onPressed: _pasteHtmlDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
