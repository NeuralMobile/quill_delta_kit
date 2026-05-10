/// Quill named font sizes per Quill JS convention.
class QuillSize {
  static const small = 'small';
  static const normal = 'normal';
  static const large = 'large';
  static const huge = 'huge';

  /// Map Quill named sizes to CSS px (Quill default snow theme values).
  static const namedToPx = <String, double>{
    'small': 10,
    'normal': 13,
    'large': 18,
    'huge': 32,
  };

  /// Parse a size string. Returns canonical form preserved verbatim
  /// (e.g. "14px", "small", "1.2em"). Returns null if blank.
  static String? canonical(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    return s;
  }

  /// Convert a Delta `size` attribute to a CSS `font-size` value.
  /// `"small"` -> `"10px"`, `"14"` -> `"14px"`, `"14px"` -> `"14px"`, `"1.2em"` -> `"1.2em"`.
  static String toCss(String value) {
    final v = value.trim();
    final px = namedToPx[v];
    if (px != null) return '${_n(px)}px';
    if (RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(v)) return '${v}px';
    return v;
  }

  /// Convert a CSS `font-size` value back to a Delta `size`.
  /// - Named match (10px -> small) when exact.
  /// - `Npx` -> `'N'` (Quill numeric size convention).
  /// - Other units (em/rem/%/pt) preserved verbatim.
  static String fromCss(String css) {
    final v = css.trim();
    for (final entry in namedToPx.entries) {
      if (v == '${_n(entry.value)}px') return entry.key;
    }
    final m = RegExp(r'^([0-9]+(?:\.[0-9]+)?)px$').firstMatch(v);
    if (m != null) return m.group(1)!;
    return v;
  }

  static String _n(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}
