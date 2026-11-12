import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/lookup/lookup.dart';
import 'package:kotohori/features/dictionary/render/css_scope.dart';
import 'package:kotohori/features/dictionary/render/glossary_html.dart';
import 'package:kotohori/features/dictionary/render/lookup_html.dart';

import '../helpers.dart';

void main() {
  group('GlossaryRenderer', () {
    final r = GlossaryRenderer(mediaUrl: (path) => 'media:$path');

    test('plain strings and text items are escaped', () {
      final html = r.glossaryList(
        jsonEncode([
          'a<b>&"c"',
          {'type': 'text', 'text': 'line1\nline2'},
        ]),
      );
      expect(html, contains('a&lt;b&gt;&amp;&quot;c&quot;'));
      expect(html, contains('line1<br>line2'));
    });

    test('structured content: tags, data-sc-*, styles, ruby, tables, links', () {
      final html = r.glossaryList(
        jsonEncode([
          {
            'type': 'structured-content',
            'content': [
              {
                'tag': 'span',
                'data': {'content': 'sense', 'fooBar': 1},
                'style': {
                  'fontWeight': 'bold',
                  'marginLeft': 0.5,
                  'position': 'fixed',
                },
                'content': 'x',
              },
              {
                'tag': 'ruby',
                'content': [
                  '漢',
                  {'tag': 'rt', 'content': 'かん'},
                ],
              },
              {
                'tag': 'table',
                'content': {
                  'tag': 'tr',
                  'content': {'tag': 'td', 'colSpan': 2, 'content': 'c'},
                },
              },
              {'tag': 'a', 'href': '?query=x', 'content': 'q'},
              {'tag': 'a', 'href': 'javascript:alert(1)', 'content': 'bad'},
              {'tag': 'script', 'content': 'alert(1)'},
              {
                'tag': 'span',
                'style': {'color': 'red;background:url(x)'},
                'content': 'y',
              },
              {
                'tag': 'img',
                'path': 'img/a.png',
                'width': 2,
                'height': 1,
                'sizeUnits': 'em',
              },
              {'tag': 'br'},
            ],
          },
        ]),
      );
      expect(
        html,
        contains(
          '<span class="gloss-sc-span" data-sc-content="sense" data-sc-foo-bar="1" style="font-weight:bold;margin-left:0.5em">x</span>',
        ),
      );
      expect(
        html,
        contains(
          '<ruby class="gloss-sc-ruby">漢<rt class="gloss-sc-rt">かん</rt></ruby>',
        ),
      );
      expect(html, contains('<td class="gloss-sc-td" colspan="2">c</td>'));
      expect(html, contains('href="?query=x"'));
      expect(html, isNot(contains('javascript')));
      expect(html, isNot(contains('<script')));
      expect(html, isNot(contains('url(')));
      expect(
        html,
        contains(
          '<img class="gloss-image" src="media:img/a.png" style="width:2em;height:1em">',
        ),
      );
      expect(html, contains('<br>'));
    });

    test('image items without a resolvable path are dropped', () {
      expect(
        GlossaryRenderer().glossaryList(
          jsonEncode([
            {'type': 'image', 'path': 'x.png'},
          ]),
        ),
        isNot(contains('<img')),
      );
    });
  });

  group('scopeCss', () {
    test('prefixes every selector, keeps @media, drops other at-rules', () {
      final css = scopeCss('''
/* c */ a, .b:is(.c, .d) { color: red }
@media (max-width: 1px) { span { x: y } }
@import url("https://evil/x.css");
@font-face { font-family: f; }
''', 'My "Dict"');
      const s = r'[data-dictionary="My \"Dict\""]';
      expect(css, contains('$s a,$s .b:is(.c, .d){ color: red }'));
      expect(css, contains('@media (max-width: 1px){$s span{ x: y }\n}'));
      expect(css, isNot(contains('@import')));
      expect(css, isNot(contains('font-face')));
    });

    test('cannot break out of the style element', () {
      expect(
        scopeCss('a { content: "</style><script>" }', 'D'),
        isNot(contains('</style>')),
      );
    });
  });

  test(
    'Anki definition: all dictionaries or first only, with scoped styles',
    () async {
      final env = await TestEnv.create();
      addTearDown(env.dispose);
      await env.import('mini_a');
      await env.import('mini_b');
      final group = (await Lookup(
        env.repo,
      ).lookup('日本', 0)).groups.first; // Mini A then Mini B
      final b = LookupHtmlBuilder(mediaRoot: env.mediaRoot);

      final all = b.ankiDefinition(group, firstDictionaryOnly: false);
      expect(all, contains('Japan (B)'));
      expect(all, contains('data-dictionary="Mini A"'));
      expect(all, contains('<style>'));
      expect(
        all,
        contains('[data-dictionary="Mini A"]'),
      ); // Mini A's styles.css, scoped

      final first = b.ankiDefinition(group, firstDictionaryOnly: true);
      expect(first, contains('Japan'));
      expect(first, isNot(contains('Japan (B)')));
    },
  );

  test('popup page adds one ＋ per word only when asked', () async {
    final env = await TestEnv.create();
    addTearDown(env.dispose);
    await env.import('mini_a');
    final r = await Lookup(env.repo).lookup('日本語', 0); // 日本語 + 日本
    final b = LookupHtmlBuilder(mediaRoot: env.mediaRoot);
    expect(b.page(r), isNot(contains('Kotohori.postMessage')));
    final withButtons = b.page(r, addButtons: true);
    expect(
      "'0'".allMatches(withButtons).length +
          "'1'".allMatches(withButtons).length,
      2,
    );
    expect(withButtons, contains("Kotohori.postMessage('1')"));
  });

  test('result page renders fixture entry with scoped dictionary CSS and inlined media', () async {
    final env = await TestEnv.create();
    addTearDown(env.dispose);
    await env.import('mini_a');
    final result = await Lookup(env.repo).lookup('日本語', 0);
    final html = LookupHtmlBuilder(mediaRoot: env.mediaRoot).page(result);
    expect(html, contains('<ruby>日本語<rt>にほんご</rt></ruby>'));
    expect(html, contains('data-dictionary="Mini A"'));
    expect(
      html,
      contains('[data-dictionary="Mini A"] [data-sc-content="sense"]'),
    );
    expect(html, contains('src="data:image/png;base64,'));
    expect(html, contains('&lt;script&gt;'));
    expect(html, isNot(contains('<script>')));
  });
}
