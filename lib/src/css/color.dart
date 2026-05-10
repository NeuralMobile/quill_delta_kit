/// Color canonicalization. Handles every CSS color form Quill / flutter_quill / browsers may emit.
class CssColor {
  const CssColor(this.r, this.g, this.b, [this.a = 255]);

  final int r;
  final int g;
  final int b;
  final int a;

  static CssColor? parse(String input) {
    final s = input.trim().toLowerCase();
    if (s.isEmpty) return null;

    if (s.startsWith('#')) return _parseHex(s);
    if (s.startsWith('rgb')) return _parseRgbFunc(s);
    if (s.startsWith('hsl')) return _parseHslFunc(s);
    return _named[s];
  }

  static CssColor? _parseHex(String s) {
    final hex = s.substring(1);
    String r, g, b, a;
    switch (hex.length) {
      case 3:
        r = hex[0] * 2;
        g = hex[1] * 2;
        b = hex[2] * 2;
        a = 'ff';
        break;
      case 4:
        r = hex[0] * 2;
        g = hex[1] * 2;
        b = hex[2] * 2;
        a = hex[3] * 2;
        break;
      case 6:
        r = hex.substring(0, 2);
        g = hex.substring(2, 4);
        b = hex.substring(4, 6);
        a = 'ff';
        break;
      case 8:
        // flutter_quill writes #AARRGGBB. Standard CSS is #RRGGBBAA. Detect by heuristic:
        // If first byte == 'ff' AND first 6 chars look like a typical color, prefer ARGB.
        // Safer: try both, but Quill output convention strongly suggests ARGB. Provide both parsers.
        return _parseHex8Ambiguous(hex);
      default:
        return null;
    }
    final ri = int.tryParse(r, radix: 16);
    final gi = int.tryParse(g, radix: 16);
    final bi = int.tryParse(b, radix: 16);
    final ai = int.tryParse(a, radix: 16);
    if (ri == null || gi == null || bi == null || ai == null) return null;
    return CssColor(ri, gi, bi, ai);
  }

  /// Default behavior: assume RRGGBBAA (CSS spec). flutter_quill ARGB callers should use [parseArgb].
  static CssColor? _parseHex8Ambiguous(String hex) {
    final r = int.tryParse(hex.substring(0, 2), radix: 16);
    final g = int.tryParse(hex.substring(2, 4), radix: 16);
    final b = int.tryParse(hex.substring(4, 6), radix: 16);
    final a = int.tryParse(hex.substring(6, 8), radix: 16);
    if (r == null || g == null || b == null || a == null) return null;
    return CssColor(r, g, b, a);
  }

  /// flutter_quill writes #AARRGGBB. Use this when you know source is flutter_quill.
  static CssColor? parseArgb(String input) {
    final s = input.trim();
    if (!s.startsWith('#') || s.length != 9) return null;
    final hex = s.substring(1);
    final a = int.tryParse(hex.substring(0, 2), radix: 16);
    final r = int.tryParse(hex.substring(2, 4), radix: 16);
    final g = int.tryParse(hex.substring(4, 6), radix: 16);
    final b = int.tryParse(hex.substring(6, 8), radix: 16);
    if (a == null || r == null || g == null || b == null) return null;
    return CssColor(r, g, b, a);
  }

  static CssColor? _parseRgbFunc(String s) {
    final start = s.indexOf('(');
    final end = s.indexOf(')');
    if (start < 0 || end < 0) return null;
    final inner = s.substring(start + 1, end);
    final parts = inner
        .replaceAll('/', ',')
        .split(RegExp(r'[ ,]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3 || parts.length > 4) return null;
    int? component(String p) {
      if (p.endsWith('%')) {
        final v = double.tryParse(p.substring(0, p.length - 1));
        if (v == null) return null;
        return (v * 255 / 100).round().clamp(0, 255);
      }
      final v = double.tryParse(p);
      if (v == null) return null;
      return v.round().clamp(0, 255);
    }

    int? alpha(String p) {
      if (p.endsWith('%')) {
        final v = double.tryParse(p.substring(0, p.length - 1));
        if (v == null) return null;
        return (v * 255 / 100).round().clamp(0, 255);
      }
      final v = double.tryParse(p);
      if (v == null) return null;
      return (v * 255).round().clamp(0, 255);
    }

    final r = component(parts[0]);
    final g = component(parts[1]);
    final b = component(parts[2]);
    final a = parts.length == 4 ? alpha(parts[3]) : 255;
    if (r == null || g == null || b == null || a == null) return null;
    return CssColor(r, g, b, a);
  }

  static CssColor? _parseHslFunc(String s) {
    final start = s.indexOf('(');
    final end = s.indexOf(')');
    if (start < 0 || end < 0) return null;
    final inner = s.substring(start + 1, end);
    final parts = inner
        .replaceAll('/', ',')
        .split(RegExp(r'[ ,]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3 || parts.length > 4) return null;

    double? num(String p) {
      var t = p;
      if (t.endsWith('deg')) t = t.substring(0, t.length - 3);
      if (t.endsWith('%')) t = t.substring(0, t.length - 1);
      return double.tryParse(t);
    }

    final h = num(parts[0]);
    final sP = num(parts[1]);
    final lP = num(parts[2]);
    if (h == null || sP == null || lP == null) return null;
    final hh = (h % 360 + 360) % 360 / 360;
    final ss = (sP / 100).clamp(0.0, 1.0);
    final ll = (lP / 100).clamp(0.0, 1.0);

    double hue2rgb(double p, double q, double t) {
      var tt = t;
      if (tt < 0) tt += 1;
      if (tt > 1) tt -= 1;
      if (tt < 1 / 6) return p + (q - p) * 6 * tt;
      if (tt < 1 / 2) return q;
      if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
      return p;
    }

    double rd, gd, bd;
    if (ss == 0) {
      rd = gd = bd = ll;
    } else {
      final q = ll < 0.5 ? ll * (1 + ss) : ll + ss - ll * ss;
      final p = 2 * ll - q;
      rd = hue2rgb(p, q, hh + 1 / 3);
      gd = hue2rgb(p, q, hh);
      bd = hue2rgb(p, q, hh - 1 / 3);
    }

    int alpha = 255;
    if (parts.length == 4) {
      var a = parts[3];
      if (a.endsWith('%')) {
        final av = double.tryParse(a.substring(0, a.length - 1));
        if (av == null) return null;
        alpha = (av * 255 / 100).round().clamp(0, 255);
      } else {
        final av = double.tryParse(a);
        if (av == null) return null;
        alpha = (av * 255).round().clamp(0, 255);
      }
    }
    return CssColor((rd * 255).round(), (gd * 255).round(), (bd * 255).round(), alpha);
  }

  /// Canonical CSS form. Uses rgba() when alpha < 255, else 6-digit hex.
  String toCss() {
    if (a < 255) {
      final aa = (a / 255).toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return 'rgba($r, $g, $b, $aa)';
    }
    return '#${_h(r)}${_h(g)}${_h(b)}';
  }

  /// Quill-side canonical: `#rrggbb` if opaque, else `#rrggbbaa`.
  String toHex() {
    if (a == 255) return '#${_h(r)}${_h(g)}${_h(b)}';
    return '#${_h(r)}${_h(g)}${_h(b)}${_h(a)}';
  }

  /// flutter_quill convention: `#aarrggbb`.
  String toArgbHex() => '#${_h(a)}${_h(r)}${_h(g)}${_h(b)}';

  static String _h(int v) => v.toRadixString(16).padLeft(2, '0');

  @override
  String toString() => toCss();

  @override
  bool operator ==(Object other) =>
      other is CssColor && other.r == r && other.g == g && other.b == b && other.a == a;

  @override
  int get hashCode => Object.hash(r, g, b, a);

  static const _named = <String, CssColor>{
    'transparent': CssColor(0, 0, 0, 0),
    'black': CssColor(0, 0, 0),
    'white': CssColor(255, 255, 255),
    'red': CssColor(255, 0, 0),
    'green': CssColor(0, 128, 0),
    'lime': CssColor(0, 255, 0),
    'blue': CssColor(0, 0, 255),
    'yellow': CssColor(255, 255, 0),
    'cyan': CssColor(0, 255, 255),
    'aqua': CssColor(0, 255, 255),
    'magenta': CssColor(255, 0, 255),
    'fuchsia': CssColor(255, 0, 255),
    'silver': CssColor(192, 192, 192),
    'gray': CssColor(128, 128, 128),
    'grey': CssColor(128, 128, 128),
    'maroon': CssColor(128, 0, 0),
    'olive': CssColor(128, 128, 0),
    'purple': CssColor(128, 0, 128),
    'teal': CssColor(0, 128, 128),
    'navy': CssColor(0, 0, 128),
    'orange': CssColor(255, 165, 0),
    'pink': CssColor(255, 192, 203),
    'brown': CssColor(165, 42, 42),
    'gold': CssColor(255, 215, 0),
  };
}
