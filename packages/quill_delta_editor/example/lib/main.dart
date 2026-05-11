import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;

import 'demos/auth_injection_demo.dart';
import 'demos/auto_grow_demo.dart';
import 'demos/custom_toolbar_demo.dart';
import 'demos/export_demo.dart';
import 'demos/fixed_height_list_demo.dart';
import 'demos/floating_toolbar_demo.dart';
import 'demos/import_demo.dart';
import 'demos/media_embeds_demo.dart';
import 'demos/read_only_demo.dart';
import 'demos/scrollable_form_demo.dart';
import 'demos/selection_toolbar_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'quill_delta_editor demos',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
      ],
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  static const _demos = <_Demo>[
    _Demo('Scrollable form', Icons.list_alt, ScrollableFormDemo()),
    _Demo('Auto-grow', Icons.unfold_more, AutoGrowDemo()),
    _Demo('Fixed-height list', Icons.view_agenda, FixedHeightListDemo()),
    _Demo('Read-only viewer', Icons.visibility, ReadOnlyDemo()),
    _Demo('Media embeds', Icons.perm_media, MediaEmbedsDemo()),
    _Demo('Auth-injected previews', Icons.lock, AuthInjectionDemo()),
    _Demo('Custom toolbar', Icons.build, CustomToolbarDemo()),
    _Demo('Corner floating toolbar', Icons.layers, FloatingToolbarDemo()),
    _Demo('Selection toolbar (iOS-style)', Icons.text_fields,
        SelectionToolbarDemo()),
    _Demo('Multi-format export', Icons.import_export, ExportDemo()),
    _Demo('Import documents', Icons.upload_file, ImportDemo()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('quill_delta_editor demos')),
      body: ListView.separated(
        itemCount: _demos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final d = _demos[i];
          return ListTile(
            leading: Icon(d.icon),
            title: Text(d.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => d.page,
                settings: RouteSettings(name: d.title),
              ));
            },
          );
        },
      ),
    );
  }
}

class _Demo {
  const _Demo(this.title, this.icon, this.page);
  final String title;
  final IconData icon;
  final Widget page;
}
