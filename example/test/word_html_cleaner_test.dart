import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta_html_example/word_html_cleaner.dart';

void main() {
  group('WordHtmlCleaner', () {
    test('isWordHtml detects Office signatures', () {
      expect(WordHtmlCleaner.isWordHtml('<html xmlns:o="urn:schemas-microsoft-com:office:office">'), true);
      expect(WordHtmlCleaner.isWordHtml('<p class="MsoNormal">x</p>'), true);
      expect(WordHtmlCleaner.isWordHtml('<p style="mso-margin-top-alt:auto">x</p>'), true);
      expect(WordHtmlCleaner.isWordHtml('<o:p>x</o:p>'), true);
      expect(WordHtmlCleaner.isWordHtml('<!--StartFragment--><p>x</p><!--EndFragment-->'), true);
      expect(WordHtmlCleaner.isWordHtml('<p>plain</p>'), false);
    });

    test('strips StartFragment/EndFragment markers', () {
      const word = '<!--StartFragment--><p>hi</p><!--EndFragment-->';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('StartFragment')));
      expect(cleaned, isNot(contains('EndFragment')));
      expect(cleaned, contains('<p>hi</p>'));
    });

    test('drops <o:p> but keeps inner text', () {
      const word = '<p><o:p>hello</o:p></p>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('o:p')));
      expect(cleaned, contains('hello'));
    });

    test('strips Mso classes', () {
      const word = '<p class="MsoNormal">x</p>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('MsoNormal')));
      expect(cleaned, isNot(contains('class=')));
      expect(cleaned, contains('<p>x</p>'));
    });

    test('strips mso-* style props but keeps real ones', () {
      const word = '<p style="color:#ff0000; mso-margin-top-alt:auto; mso-list:Ignore">x</p>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, contains('color:'));
      expect(cleaned, isNot(contains('mso-')));
    });

    test('strips lang + xmlns attrs', () {
      const word = '<p lang="EN-US" xmlns:o="urn:schemas-microsoft-com:office:office">x</p>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('lang=')));
      expect(cleaned, isNot(contains('xmlns')));
    });

    test('strips conditional comments', () {
      const word = '<![if !supportLists]>marker<![endif]><p>real</p>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('supportLists')));
      expect(cleaned, contains('real'));
    });

    test('folds mso-list paragraphs into <ul>', () {
      const word =
          "<p style='mso-list:l0 level1 lfo1'>"
          "<span style='mso-list:Ignore'>·<span>&nbsp;</span></span>One</p>"
          "<p style='mso-list:l0 level1 lfo1'>"
          "<span style='mso-list:Ignore'>·<span>&nbsp;</span></span>Two</p>";
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, startsWith('<ul>'));
      expect(cleaned, endsWith('</ul>'));
      expect(cleaned, contains('<li>'));
      expect(cleaned, contains('One'));
      expect(cleaned, contains('Two'));
    });

    test('folds mso-list paragraphs into <ol> when marker is numeric', () {
      const word =
          "<p style='mso-list:l0 level1 lfo1'>"
          "<span style='mso-list:Ignore'>1.<span>&nbsp;</span></span>First</p>"
          "<p style='mso-list:l0 level1 lfo1'>"
          "<span style='mso-list:Ignore'>2.<span>&nbsp;</span></span>Second</p>";
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, startsWith('<ol>'));
      expect(cleaned, contains('First'));
      expect(cleaned, contains('Second'));
    });

    test('nested mso-list levels', () {
      const word =
          "<p style='mso-list:l0 level1 lfo1'>"
          "<span style='mso-list:Ignore'>1.</span>Outer</p>"
          "<p style='mso-list:l0 level2 lfo1'>"
          "<span style='mso-list:Ignore'>a.</span>Inner</p>"
          "<p style='mso-list:l0 level1 lfo1'>"
          "<span style='mso-list:Ignore'>2.</span>Outer 2</p>";
      final cleaned = WordHtmlCleaner.clean(word);
      // Outer ol, with nested ol inside the first li.
      expect(cleaned, contains('<ol>'));
      expect(cleaned, contains('Outer'));
      expect(cleaned, contains('Inner'));
      expect(cleaned, contains('Outer 2'));
    });

    test('removes empty <span> wrappers', () {
      const word = '<p><span lang="EN-US"><span>hello</span></span></p>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('<span>')));
      expect(cleaned, contains('hello'));
    });

    test('end-to-end: real Word paragraph', () {
      const word =
          '<html xmlns:o="urn:schemas-microsoft-com:office:office">'
          '<body><!--StartFragment-->'
          '<p class=MsoNormal style="mso-margin-top-alt:auto">'
          '<span lang=EN-US style="font-family:Calibri">'
          '<o:p>Hello </o:p></span>'
          '<b><span lang=EN-US style="font-family:Calibri">world</span></b>'
          '</p>'
          '<!--EndFragment--></body></html>';
      final cleaned = WordHtmlCleaner.clean(word);
      expect(cleaned, isNot(contains('mso')));
      expect(cleaned, isNot(contains('o:p')));
      expect(cleaned, isNot(contains('xmlns')));
      expect(cleaned, isNot(contains('class=')));
      expect(cleaned, isNot(contains('lang=')));
      expect(cleaned, contains('Hello'));
      expect(cleaned, contains('world'));
      expect(cleaned, anyOf(contains('<b>'), contains('<strong>')));
    });
  });
}
