/// Whitespace + entity helpers.
class Ws {
  /// Codepoints that HTML default whitespace rules collapse but Quill must preserve.
  static const significantSpaces = <int>{
    0x00A0, // NBSP
    0x2002, // EN SPACE
    0x2003, // EM SPACE
    0x2009, // THIN SPACE
    0x200B, // ZWSP
    0x200C, // ZWNJ
    0x200D, // ZWJ
    0x202F, // NARROW NBSP
    0x205F, // MEDIUM MATHEMATICAL SPACE
    0x3000, // IDEOGRAPHIC SPACE
    0xFEFF, // BOM / ZWNBSP
    0x00AD, // SOFT HYPHEN
    0x2028, // LINE SEPARATOR
    0x2029, // PARAGRAPH SEPARATOR
  };

  /// HTML-encode text preserving every space, tab, newline.
  /// Uses numeric char refs for invisible / collapsing whitespace.
  ///
  /// Iterates UTF-16 code units (not runes). All [significantSpaces] are BMP,
  /// so surrogate pairs (emoji etc.) pass through unchanged via writeCharCode.
  static String encodeText(String s) {
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final cu = s.codeUnitAt(i);
      switch (cu) {
        case 0x26: // &
          out.write('&amp;');
          break;
        case 0x3C: // <
          out.write('&lt;');
          break;
        case 0x3E: // >
          out.write('&gt;');
          break;
        case 0x22: // "
          out.write('&quot;');
          break;
        case 0x09: // tab
          out.write('&#9;');
          break;
        case 0x0D: // CR
          out.write('&#13;');
          break;
        default:
          if (significantSpaces.contains(cu)) {
            out.write('&#$cu;');
          } else {
            out.writeCharCode(cu);
          }
      }
    }
    return out.toString();
  }

  /// Encode an attribute value (no need to escape `<` / `>` / tab).
  static String encodeAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('\n', '&#10;')
      .replaceAll('\r', '&#13;');
}
