/// Parse and serialize an inline `style="…"` attribute into a stable map.
class StyleMap {
  StyleMap([Map<String, String>? init]) : _props = init == null ? <String, String>{} : Map.of(init);

  final Map<String, String> _props;

  static StyleMap parse(String? style) {
    final m = StyleMap();
    if (style == null) return m;
    for (final raw in style.split(';')) {
      final s = raw.trim();
      if (s.isEmpty) continue;
      final colon = s.indexOf(':');
      if (colon <= 0) continue;
      final key = s.substring(0, colon).trim().toLowerCase();
      final val = s.substring(colon + 1).trim();
      if (key.isEmpty || val.isEmpty) continue;
      m._props[key] = val;
    }
    return m;
  }

  String? operator [](String key) => _props[key.toLowerCase()];
  void operator []=(String key, String value) => _props[key.toLowerCase()] = value;
  void remove(String key) => _props.remove(key.toLowerCase());
  bool containsKey(String key) => _props.containsKey(key.toLowerCase());
  bool get isEmpty => _props.isEmpty;
  bool get isNotEmpty => _props.isNotEmpty;
  Map<String, String> get props => Map.unmodifiable(_props);

  /// Canonical serialization: alphabetical key order, `key: value;` joined by `; `.
  String toCss() {
    if (_props.isEmpty) return '';
    final keys = _props.keys.toList()..sort();
    return keys.map((k) => '$k: ${_props[k]}').join('; ');
  }
}
