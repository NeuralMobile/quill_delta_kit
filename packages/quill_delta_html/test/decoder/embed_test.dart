import 'package:test/test.dart';

import '../_helpers.dart';

void main() {
  final c = frag();

  group('embed decoder', () {
    test('img', () {
      expect(c.decode('<p><img src="https://x/a.png"></p>').toJson(), [
        {
          'insert': {'image': 'https://x/a.png'}
        },
        {'insert': '\n'}
      ]);
    });

    test('img with width/height/style', () {
      expect(
        c
            .decode(
                '<p><img src="x" width="100" height="50" style="margin: auto" alt="hi"></p>')
            .toJson(),
        [
          {
            'insert': {'image': 'x'},
            'attributes': {
              'alt': 'hi',
              'height': '50',
              'style': 'margin: auto',
              'width': '100'
            }
          },
          {'insert': '\n'}
        ],
      );
    });

    test('audio', () {
      expect(
          c
              .decode('<p><audio controls src="https://x/a.mp3"></audio></p>')
              .toJson(),
          [
            {
              'insert': {'audio': 'https://x/a.mp3'}
            },
            {'insert': '\n'}
          ]);
    });

    test('video direct', () {
      expect(
          c
              .decode('<p><video controls src="https://x/v.mp4"></video></p>')
              .toJson(),
          [
            {
              'insert': {'video': 'https://x/v.mp4'}
            },
            {'insert': '\n'}
          ]);
    });

    test('video iframe youtube -> typed video', () {
      expect(
        c
            .decode(
                '<p><iframe src="https://www.youtube.com/embed/abc"></iframe></p>')
            .toJson(),
        [
          {
            'insert': {'video': 'https://www.youtube.com/embed/abc'}
          },
          {'insert': '\n'}
        ],
      );
    });

    test('video iframe vimeo -> typed video', () {
      expect(
        c
            .decode(
                '<p><iframe src="https://player.vimeo.com/video/123"></iframe></p>')
            .toJson(),
        [
          {
            'insert': {'video': 'https://player.vimeo.com/video/123'}
          },
          {'insert': '\n'}
        ],
      );
    });

    test('CKEditor oembed -> video', () {
      expect(
        c
            .decode(
                '<figure class="media"><oembed url="https://www.youtube.com/watch?v=xyz"></oembed></figure>')
            .toJson(),
        [
          {
            'insert': {'video': 'https://www.youtube.com/watch?v=xyz'}
          },
        ],
      );
    });

    test('hr -> divider', () {
      expect(c.decode('<hr>').toJson(), [
        {
          'insert': {'divider': true}
        },
        {'insert': '\n'}
      ]);
    });

    test('formula via ql-formula class', () {
      expect(
        c
            .decode(
                '<p><span class="ql-formula" data-formula="e=mc^2">e=mc^2</span></p>')
            .toJson(),
        [
          {
            'insert': {'formula': 'e=mc^2'}
          },
          {'insert': '\n'}
        ],
      );
    });

    test('mention quill-style', () {
      const html = '<p><span class="mention" data-mention-id="42" '
          'data-mention-value="Alice" data-denotation-char="@">@Alice</span></p>';
      expect(c.decode(html).toJson(), [
        {
          'insert': {
            'mention': {'denotationChar': '@', 'id': '42', 'value': 'Alice'}
          }
        },
        {'insert': '\n'}
      ]);
    });

    test('mention CKEditor-style', () {
      const html =
          '<p><span class="mention" data-mention="@Bob">@Bob</span></p>';
      final ops = c.decode(html).toJson();
      expect(ops.first['insert']['mention']['value'], 'Bob');
    });

    test('passthrough unknown round-trip', () {
      // Encode unknown -> decode should reproduce.
      final original = deltaOf([
        {
          'insert': {
            'weirdembed': {'k': 'v', 'n': 7}
          }
        },
        {'insert': '\n'}
      ]);
      final html = c.encode(original);
      final back = c.decode(html);
      expect(back.toJson(), original.toJson());
    });
  });
}
