import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('cross-editor input', () {
    group('Quill JS output', () {
      test('basic paragraph with formatting', () {
        const html = '<p>Hello <strong>bold</strong> '
            '<em>italic</em> <u>underline</u> <s>strike</s></p>';
        final ops = c.decode(html).toJson();
        expect(ops, [
          {'insert': 'Hello '},
          {
            'insert': 'bold',
            'attributes': {'bold': true}
          },
          {'insert': ' '},
          {
            'insert': 'italic',
            'attributes': {'italic': true}
          },
          {'insert': ' '},
          {
            'insert': 'underline',
            'attributes': {'underline': true}
          },
          {'insert': ' '},
          {
            'insert': 'strike',
            'attributes': {'strike': true}
          },
          {'insert': '\n'}
        ]);
      });

      test('Quill checkbox list (ql-* classes)', () {
        const html = '<ul data-checked="true">'
            '<li>done</li>'
            '</ul>';
        expect(c.decode(html).toJson(), [
          {'insert': 'done'},
          {
            'insert': '\n',
            'attributes': {'list': 'checked'}
          }
        ]);
      });

      test('Quill code block', () {
        const html = '<pre>const x = 1;\nconst y = 2;</pre>';
        expect(c.decode(html).toJson(), [
          {'insert': 'const x = 1;'},
          {
            'insert': '\n',
            'attributes': {'code-block': true}
          },
          {'insert': 'const y = 2;'},
          {
            'insert': '\n',
            'attributes': {'code-block': true}
          }
        ]);
      });
    });

    group('TipTap output', () {
      test('TipTap basic paragraph', () {
        const html = '<p>Hello <strong>world</strong></p>';
        expect(c.decode(html).toJson(), [
          {'insert': 'Hello '},
          {
            'insert': 'world',
            'attributes': {'bold': true}
          },
          {'insert': '\n'}
        ]);
      });

      test('TipTap task list', () {
        const html = '<ul data-type="taskList">'
            '<li data-type="taskItem" data-checked="true"><label><input type="checkbox" checked></label><div><p>Buy milk</p></div></li>'
            '<li data-type="taskItem" data-checked="false"><label><input type="checkbox"></label><div><p>Walk dog</p></div></li>'
            '</ul>';
        expect(c.decode(html).toJson(), [
          {'insert': 'Buy milk'},
          {
            'insert': '\n',
            'attributes': {'list': 'checked'}
          },
          {'insert': 'Walk dog'},
          {
            'insert': '\n',
            'attributes': {'list': 'unchecked'}
          }
        ]);
      });

      test('TipTap heading + paragraph', () {
        const html = '<h2>Title</h2><p>Body</p>';
        expect(c.decode(html).toJson(), [
          {'insert': 'Title'},
          {
            'insert': '\n',
            'attributes': {'header': 2}
          },
          {'insert': 'Body\n'}
        ]);
      });

      test('TipTap iframe (generic)', () {
        const html = '<p><iframe src="https://example.com/widget" width="400"></iframe></p>';
        final ops = c.decode(html).toJson();
        // No matching provider -> generic IframeAdapter (which is gated by IframePolicy
        // — default policy allows https + any host).
        expect(ops.first, {
          'insert': {
            'iframe': {'src': 'https://example.com/widget', 'width': '400'}
          }
        });
      });
    });

    group('CKEditor output', () {
      test('CKEditor heading + bold', () {
        const html = '<h1>Hello</h1><p>This is <strong>bold</strong> text.</p>';
        expect(c.decode(html).toJson(), [
          {'insert': 'Hello'},
          {
            'insert': '\n',
            'attributes': {'header': 1}
          },
          {'insert': 'This is '},
          {
            'insert': 'bold',
            'attributes': {'bold': true}
          },
          {'insert': ' text.\n'}
        ]);
      });

      test('CKEditor todo list', () {
        const html = '<ul class="todo-list">'
            '<li><label class="todo-list__label"><input type="checkbox" checked>'
            '<span class="todo-list__label__description">A</span></label></li>'
            '<li><label class="todo-list__label"><input type="checkbox">'
            '<span class="todo-list__label__description">B</span></label></li>'
            '</ul>';
        expect(c.decode(html).toJson(), [
          {'insert': 'A'},
          {
            'insert': '\n',
            'attributes': {'list': 'checked'}
          },
          {'insert': 'B'},
          {
            'insert': '\n',
            'attributes': {'list': 'unchecked'}
          }
        ]);
      });

      test('CKEditor MediaEmbed oembed', () {
        const html = '<figure class="media"><oembed url="https://www.youtube.com/watch?v=abc"></oembed></figure>';
        expect(c.decode(html).toJson(), [
          {
            'insert': {'video': 'https://www.youtube.com/watch?v=abc'}
          }
        ]);
      });

      test('CKEditor figure-wrapped image', () {
        const html =
            '<figure class="image"><img src="https://x/y.png" width="200"><figcaption>caption</figcaption></figure>';
        final ops = c.decode(html).toJson();
        // Adapter doesn't know "figure.image" specifically — figure transparent, img picked up.
        expect(ops.any((o) => o['insert'] is Map && (o['insert'] as Map)['image'] == 'https://x/y.png'), true);
      });

      test('CKEditor mention', () {
        const html = '<p><span class="mention" data-mention="@Alice">@Alice</span> hi</p>';
        final ops = c.decode(html).toJson();
        expect(ops.first['insert']['mention']['value'], 'Alice');
      });

      test('CKEditor block quote with multiple paragraphs', () {
        const html = '<blockquote><p>first</p><p>second</p></blockquote>';
        expect(c.decode(html).toJson(), [
          {'insert': 'first'},
          {
            'insert': '\n',
            'attributes': {'blockquote': true}
          },
          {'insert': 'second'},
          {
            'insert': '\n',
            'attributes': {'blockquote': true}
          }
        ]);
      });
    });

    group('ProseMirror / Lexical patterns', () {
      test('ProseMirror nested marks', () {
        const html = '<p><strong><em>hi</em></strong></p>';
        expect(c.decode(html).toJson(), [
          {
            'insert': 'hi',
            'attributes': {'bold': true, 'italic': true}
          },
          {'insert': '\n'}
        ]);
      });

      test('Lexical-style anchor with rel/target', () {
        const html = '<p><a href="https://x" target="_blank" rel="noopener">link</a></p>';
        final ops = c.decode(html).toJson();
        expect(ops.first['attributes']['link'], 'https://x');
      });
    });
  });
}
