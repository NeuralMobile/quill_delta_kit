/// Sample Delta op lists exercising every supported attribute / embed.
final Map<String, List<Map<String, dynamic>>> fixtures = {
  'Empty': [
    {'insert': '\n'},
  ],
  'Inline formats': [
    {'insert': 'Hello '},
    {
      'insert': 'bold',
      'attributes': {'bold': true},
    },
    {'insert': ', '},
    {
      'insert': 'italic',
      'attributes': {'italic': true},
    },
    {'insert': ', '},
    {
      'insert': 'underlined',
      'attributes': {'underline': true},
    },
    {'insert': ', '},
    {
      'insert': 'strikethrough',
      'attributes': {'strike': true},
    },
    {'insert': ', '},
    {
      'insert': 'code',
      'attributes': {'code': true},
    },
    {'insert': '.\n'},
  ],
  'Color + size': [
    {
      'insert': 'Red ',
      'attributes': {'color': '#ff0000'},
    },
    {
      'insert': 'on yellow',
      'attributes': {'background': '#ffff00'},
    },
    {'insert': ' '},
    {
      'insert': 'big',
      'attributes': {'size': 'large'},
    },
    {'insert': ' '},
    {
      'insert': 'huge',
      'attributes': {'size': 'huge'},
    },
    {'insert': ' '},
    {
      'insert': '24px',
      'attributes': {'size': '24'},
    },
    {'insert': '\n'},
  ],
  'Headings': [
    {'insert': 'H1'},
    {
      'insert': '\n',
      'attributes': {'header': 1},
    },
    {'insert': 'H2'},
    {
      'insert': '\n',
      'attributes': {'header': 2},
    },
    {'insert': 'H3'},
    {
      'insert': '\n',
      'attributes': {'header': 3},
    },
    {'insert': 'Body paragraph.\n'},
  ],
  'Lists': [
    {'insert': 'Ordered 1'},
    {
      'insert': '\n',
      'attributes': {'list': 'ordered'},
    },
    {'insert': 'Ordered 2'},
    {
      'insert': '\n',
      'attributes': {'list': 'ordered'},
    },
    {'insert': 'Nested'},
    {
      'insert': '\n',
      'attributes': {'list': 'ordered', 'indent': 1},
    },
    {'insert': 'Bullet 1'},
    {
      'insert': '\n',
      'attributes': {'list': 'bullet'},
    },
    {'insert': 'Bullet 2'},
    {
      'insert': '\n',
      'attributes': {'list': 'bullet'},
    },
  ],
  'Checklist': [
    {'insert': 'Done'},
    {
      'insert': '\n',
      'attributes': {'list': 'checked'},
    },
    {'insert': 'Todo'},
    {
      'insert': '\n',
      'attributes': {'list': 'unchecked'},
    },
    {'insert': 'Subtask'},
    {
      'insert': '\n',
      'attributes': {'list': 'checked', 'indent': 1},
    },
  ],
  'Quote + Code': [
    {'insert': 'Wisdom of the ages'},
    {
      'insert': '\n',
      'attributes': {'blockquote': true},
    },
    {'insert': 'def hello():'},
    {
      'insert': '\n',
      'attributes': {'code-block': 'python'},
    },
    {'insert': '    print("hi")'},
    {
      'insert': '\n',
      'attributes': {'code-block': 'python'},
    },
  ],
  'Align + RTL': [
    {'insert': 'Left'},
    {
      'insert': '\n',
      'attributes': {'align': 'left'},
    },
    {'insert': 'Center'},
    {
      'insert': '\n',
      'attributes': {'align': 'center'},
    },
    {'insert': 'Right'},
    {
      'insert': '\n',
      'attributes': {'align': 'right'},
    },
    {'insert': 'مرحبا'},
    {
      'insert': '\n',
      'attributes': {'direction': 'rtl', 'align': 'right'},
    },
  ],
  'Link + Script': [
    {'insert': 'Visit '},
    {
      'insert': 'flutter.dev',
      'attributes': {'link': 'https://flutter.dev'},
    },
    {'insert': '. Water is H'},
    {
      'insert': '2',
      'attributes': {'script': 'sub'},
    },
    {'insert': 'O. Power: x'},
    {
      'insert': '2',
      'attributes': {'script': 'super'},
    },
    {'insert': '.\n'},
  ],
  'Image + Video': [
    {'insert': 'An image:\n'},
    {
      'insert': {'image': 'https://picsum.photos/200/100'},
      'attributes': {'width': '200', 'height': '100'},
    },
    {'insert': '\nA YouTube video:\n'},
    {
      'insert': {'video': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'},
    },
    {'insert': '\n'},
  ],
  'Audio': [
    {'insert': 'Audio sample:\n'},
    {
      'insert': {'audio': 'https://example.com/sample.mp3'},
    },
    {'insert': '\n'},
  ],
  'Mention + Divider': [
    {'insert': 'Hi '},
    {
      'insert': {
        'mention': {'id': '42', 'value': 'Alice', 'denotationChar': '@'},
      },
    },
    {'insert': ', see below.\n'},
    {
      'insert': {'divider': true},
    },
    {'insert': '\n'},
    {'insert': 'Below the line.\n'},
  ],
  'Formula': [
    {'insert': 'Euler: '},
    {
      'insert': {'formula': 'e^{i\\pi}+1=0'},
    },
    {'insert': '\n'},
  ],
  'Whitespace stress': [
    {'insert': 'Leading   spaces preserved.\n'},
    {'insert': 'NBSP in middle.\n'},
    {'insert': 'Tab\there.\n'},
    {'insert': '\n\n\n'},
    {'insert': 'After triple newline.\n'},
  ],
  'Big mixed doc': [
    {'insert': 'My Article'},
    {
      'insert': '\n',
      'attributes': {'header': 1},
    },
    {'insert': 'Intro with '},
    {
      'insert': 'bold',
      'attributes': {'bold': true},
    },
    {'insert': ', '},
    {
      'insert': 'red',
      'attributes': {'color': '#ff0000'},
    },
    {'insert': ', '},
    {
      'insert': 'a link',
      'attributes': {'link': 'https://example.com'},
    },
    {'insert': '.\n'},
    {'insert': 'Section'},
    {
      'insert': '\n',
      'attributes': {'header': 2},
    },
    {'insert': 'one'},
    {
      'insert': '\n',
      'attributes': {'list': 'ordered'},
    },
    {'insert': 'two'},
    {
      'insert': '\n',
      'attributes': {'list': 'ordered'},
    },
    {'insert': 'sub'},
    {
      'insert': '\n',
      'attributes': {'list': 'ordered', 'indent': 1},
    },
    {'insert': 'Wisdom'},
    {
      'insert': '\n',
      'attributes': {'blockquote': true},
    },
    {'insert': 'def f():'},
    {
      'insert': '\n',
      'attributes': {'code-block': 'python'},
    },
    {'insert': '    return 1'},
    {
      'insert': '\n',
      'attributes': {'code-block': 'python'},
    },
    {
      'insert': {'image': 'https://picsum.photos/300/120'},
    },
    {'insert': '\n'},
    {
      'insert': {'divider': true},
    },
    {'insert': '\n'},
    {'insert': 'task1'},
    {
      'insert': '\n',
      'attributes': {'list': 'checked'},
    },
    {'insert': 'task2'},
    {
      'insert': '\n',
      'attributes': {'list': 'unchecked'},
    },
  ],
};

/// HTML inputs from various editors — load to verify cross-editor decode.
const Map<String, String> htmlFixtures = {
  'Quill':
      '<h1>Title</h1><p>Plain <strong>bold</strong> <em>italic</em>.</p>'
      '<ul data-checked="true"><li>done</li></ul>',
  'TipTap':
      '<h2>TipTap</h2>'
      '<ul data-type="taskList">'
      '<li data-type="taskItem" data-checked="true"><label><input type="checkbox" checked></label><div><p>Buy milk</p></div></li>'
      '<li data-type="taskItem" data-checked="false"><label><input type="checkbox"></label><div><p>Walk dog</p></div></li>'
      '</ul>',
  'CKEditor':
      '<h1>CKEditor</h1>'
      '<p>This is <strong>bold</strong> + <span style="color:#ff0000">red</span>.</p>'
      '<ul class="todo-list">'
      '<li><label class="todo-list__label"><input type="checkbox" checked>'
      '<span class="todo-list__label__description">A</span></label></li>'
      '</ul>'
      '<figure class="media"><oembed url="https://www.youtube.com/watch?v=dQw4w9WgXcQ"></oembed></figure>',
  'ProseMirror':
      '<p><strong><em>bold italic</em></strong></p>'
      '<blockquote><p>quote</p></blockquote>',
  'Table':
      '<table>'
      '<thead><tr><th>Name</th><th>Score</th></tr></thead>'
      '<tbody><tr><td>Alice</td><td>92</td></tr><tr><td>Bob</td><td>85</td></tr></tbody>'
      '</table>',
};
