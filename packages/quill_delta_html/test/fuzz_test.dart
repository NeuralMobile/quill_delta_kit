import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';
import 'package:test/test.dart';

import '_helpers.dart';

/// Property test: for every randomly generated Delta, `decode(encode(d))` must
/// equal `d` after normalization.
///
/// Tests are deterministic per seed. Increase `iterations` for deeper coverage.
void main() {
  final c = QuillHtmlCodec(options: const QuillHtmlOptions(wrapDocument: false));
  const seeds = [1, 7, 42, 1024, 31415, 99991];
  const iterations = 30;

  group('property: decode(encode(delta)) == delta', () {
    for (final seed in seeds) {
      for (var i = 0; i < iterations; i++) {
        final iterSeed = seed * 1000 + i;
        test('seed=$iterSeed', () {
          final rng = Random(iterSeed);
          final delta = _genDelta(rng);
          final html = c.encode(delta);
          final back = c.decode(html);
          expect(
            normalize(back).toJson(),
            normalize(delta).toJson(),
            reason: 'seed=$iterSeed delta=${delta.toJson()}\n  html=$html',
          );
        });
      }
    }
  });
}

/// Random Delta generator. Produces a bounded number of lines with random
/// inline + block attributes, embeds, and whitespace.
Delta _genDelta(Random rng) {
  final delta = Delta();
  final lineCount = 1 + rng.nextInt(8);
  for (var l = 0; l < lineCount; l++) {
    final block = _randomBlockAttrs(rng);
    final isCodeBlock = block != null && block['code-block'] != null;
    final lineOps = 1 + rng.nextInt(4);
    for (var o = 0; o < lineOps; o++) {
      if (!isCodeBlock && rng.nextDouble() < 0.10) {
        delta.insert(_randomEmbed(rng));
      } else {
        final text = _randomText(rng);
        if (text.isEmpty) continue;
        // No inline formatting inside code-block lines (Quill spec).
        final attrs = isCodeBlock ? null : _randomInlineAttrs(rng);
        delta.insert(text, attrs);
      }
    }
    delta.insert('\n', block);
  }
  return delta;
}

const _alpha = 'abcdefghijklmnopqrstuvwxyz0123456789 ';

String _randomText(Random rng) {
  final len = 1 + rng.nextInt(15);
  final sb = StringBuffer();
  for (var i = 0; i < len; i++) {
    if (rng.nextDouble() < 0.05) {
      // Sprinkle special whitespace.
      sb.writeCharCode([0x00A0, 0x200B, 0x2009, 0x202F, 0x09][rng.nextInt(5)]);
    } else {
      sb.write(_alpha[rng.nextInt(_alpha.length)]);
    }
  }
  return sb.toString();
}

Map<String, dynamic>? _randomInlineAttrs(Random rng) {
  final attrs = <String, dynamic>{};
  if (rng.nextDouble() < 0.3) attrs['bold'] = true;
  if (rng.nextDouble() < 0.3) attrs['italic'] = true;
  if (rng.nextDouble() < 0.2) attrs['underline'] = true;
  if (rng.nextDouble() < 0.15) attrs['strike'] = true;
  if (rng.nextDouble() < 0.15) attrs['code'] = true;
  if (rng.nextDouble() < 0.20) attrs['color'] = _randomColor(rng);
  if (rng.nextDouble() < 0.10) attrs['background'] = _randomColor(rng);
  if (rng.nextDouble() < 0.10) {
    final size = ['small', 'large', 'huge', '14', '16', '20'][rng.nextInt(6)];
    attrs['size'] = size;
  }
  if (rng.nextDouble() < 0.05) attrs['script'] = rng.nextBool() ? 'super' : 'sub';
  if (rng.nextDouble() < 0.05) attrs['link'] = 'https://example.com/${rng.nextInt(1000)}';
  return attrs.isEmpty ? null : attrs;
}

Map<String, dynamic>? _randomBlockAttrs(Random rng) {
  final r = rng.nextDouble();
  // 50% plain, 15% header, 15% list, 8% blockquote, 7% code-block, 5% align/dir/indent.
  if (r < 0.50) return null;
  if (r < 0.65) return {'header': 1 + rng.nextInt(6)};
  if (r < 0.80) {
    final type = ['ordered', 'bullet', 'checked', 'unchecked'][rng.nextInt(4)];
    final attrs = <String, dynamic>{'list': type};
    if (rng.nextDouble() < 0.3) attrs['indent'] = 1 + rng.nextInt(2);
    return attrs;
  }
  if (r < 0.88) return {'blockquote': true};
  if (r < 0.95) return {'code-block': true};
  // Tail: align/direction/indent.
  final attrs = <String, dynamic>{};
  if (rng.nextBool()) {
    attrs['align'] = ['left', 'center', 'right', 'justify'][rng.nextInt(4)];
  }
  if (rng.nextBool()) {
    attrs['direction'] = rng.nextBool() ? 'rtl' : 'ltr';
  }
  if (rng.nextBool() && attrs.isEmpty) {
    attrs['indent'] = 1 + rng.nextInt(3);
  }
  return attrs.isEmpty ? null : attrs;
}

String _randomColor(Random rng) {
  final r = rng.nextInt(256);
  final g = rng.nextInt(256);
  final b = rng.nextInt(256);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

Map<String, dynamic> _randomEmbed(Random rng) {
  final type = rng.nextInt(5);
  switch (type) {
    case 0:
      return {'image': 'https://x/img${rng.nextInt(99)}.png'};
    case 1:
      return {'audio': 'https://x/a${rng.nextInt(99)}.mp3'};
    case 2:
      return {'video': 'https://x/v${rng.nextInt(99)}.mp4'};
    case 3:
      return {
        'mention': {'id': '${rng.nextInt(1000)}', 'value': 'User${rng.nextInt(99)}', 'denotationChar': '@'}
      };
    default:
      return {'formula': 'x^${rng.nextInt(10)}'};
  }
}
