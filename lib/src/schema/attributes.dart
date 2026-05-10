/// Canonical Quill / flutter_quill 11.x attribute keys (single source of truth).
class Attr {
  // Inline.
  static const bold = 'bold';
  static const italic = 'italic';
  static const underline = 'underline';
  static const strike = 'strike';
  static const code = 'code';
  static const small = 'small';
  static const link = 'link';
  static const color = 'color';
  static const background = 'background';
  static const font = 'font';
  static const size = 'size';
  static const script = 'script';
  static const placeholder = 'placeholder';

  // Block (line attrs).
  static const header = 'header';
  static const list = 'list';
  static const blockquote = 'blockquote';
  static const codeBlock = 'code-block';
  static const indent = 'indent';
  static const align = 'align';
  static const direction = 'direction';
  static const lineHeight = 'line-height';

  // Embed sibling attrs (image/video/audio).
  static const width = 'width';
  static const height = 'height';
  static const style = 'style';
  static const token = 'token';

  static const inlineKeys = <String>{
    bold,
    italic,
    underline,
    strike,
    code,
    small,
    link,
    color,
    background,
    font,
    size,
    script,
    placeholder,
  };

  static const blockKeys = <String>{
    header,
    list,
    blockquote,
    codeBlock,
    indent,
    align,
    direction,
    lineHeight,
  };

  /// Mutually exclusive line types.
  static const exclusiveBlocks = <String>{header, list, blockquote, codeBlock};

  static bool isInline(String key) => inlineKeys.contains(key);
  static bool isBlock(String key) => blockKeys.contains(key);
}
