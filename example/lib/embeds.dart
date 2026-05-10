import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;

/// Minimal placeholder embed builders for the example. They render a styled
/// chip showing the embed type + value so the editor doesn't crash. Real apps
/// should use `flutter_quill_extensions` or supply network/file widgets.
List<fq.EmbedBuilder> exampleEmbedBuilders() => [
      _SimpleEmbed('image', icon: Icons.image),
      _SimpleEmbed('video', icon: Icons.play_circle),
      _SimpleEmbed('audio', icon: Icons.audiotrack),
      _SimpleEmbed('formula', icon: Icons.functions),
      _SimpleEmbed('mention', icon: Icons.alternate_email),
      _SimpleEmbed('divider', icon: Icons.horizontal_rule, isInline: false, label: '— divider —'),
      _SimpleEmbed('table', icon: Icons.table_chart),
      _SimpleEmbed('iframe', icon: Icons.open_in_new),
      _SimpleEmbed('loom', icon: Icons.play_circle_outline),
      _SimpleEmbed('spotify', icon: Icons.music_note),
      _SimpleEmbed('soundcloud', icon: Icons.cloud),
      _SimpleEmbed('codepen', icon: Icons.code),
      _SimpleEmbed('tweet', icon: Icons.tag),
    ];

fq.EmbedBuilder unknownEmbedBuilder() => _SimpleEmbed('unknown', icon: Icons.help_outline);

class _SimpleEmbed extends fq.EmbedBuilder {
  _SimpleEmbed(this._key, {required this.icon, this.isInline = true, this.label});

  final String _key;
  final IconData icon;
  final bool isInline;
  final String? label;

  @override
  String get key => _key;

  @override
  bool get expanded => !isInline;

  @override
  Widget build(BuildContext context, fq.EmbedContext embedContext) {
    final node = embedContext.node;
    final value = node.value.data;
    final preview = label ?? _shorten(value);
    final chip = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$_key: $preview',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    return isInline ? chip : SizedBox(width: double.infinity, child: chip);
  }

  String _shorten(Object? v) {
    final s = v?.toString() ?? '';
    if (s.length <= 40) return s;
    return '${s.substring(0, 37)}…';
  }
}
