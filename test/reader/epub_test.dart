import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/epub.dart';

import 'epub_fixture.dart';

void main() {
  test('reads title, author, cover, spine and nav TOC (EPUB 3)', () {
    final b = parseEpub(buildEpub(chapters: ['<p>一章。</p>', '<p>二章です。</p>']));
    expect(b.title, 'テスト');
    expect(b.author, '作者');
    expect(b.cover, [1, 2, 3]);
    expect(b.spine.map((c) => c.href), [
      'OEBPS/Text/chapter one.xhtml',
      'OEBPS/Text/ch1.xhtml',
    ]);
    expect(b.spine.map((c) => c.length), [3, 5]);
    expect(b.toc.map((e) => (e.title, e.chapter, e.fragment)), [
      ('第1章', 0, 'top'),
      ('第2章', 1, 'top'),
    ]);
  });

  test('EPUB 2 toc.ncx gives the chapter list', () {
    final b = parseEpub(
      buildEpub(nav: false, ncx: true, chapters: ['<p>a</p>', '<p>b</p>']),
    );
    expect(b.toc.map((e) => (e.title, e.chapter)), [('章1', 0), ('章2', 1)]);
  });

  test('no table of contents: one entry per spine item', () {
    final b = parseEpub(
      buildEpub(nav: false, chapters: ['<p>a</p>', '<p>b</p>']),
    );
    expect(b.toc.map((e) => (e.title, e.chapter)), [
      ('Section 1', 0),
      ('Section 2', 1),
    ]);
  });

  test('OPF at the root, no cover, no author', () {
    final b = parseEpub(
      buildEpub(opfInSubfolder: false, cover: false, author: null),
    );
    expect(b.spine.single.href, 'Text/chapter one.xhtml');
    expect(b.cover, isNull);
    expect(b.author, isNull);
  });

  test('hrefs with ../ resolve against the OPF folder', () {
    final a = ZipDecoder().decodeBytes(buildEpub());
    final opf = a.find('OEBPS/content.opf')!;
    final text = String.fromCharCodes(opf.content).replaceAll(
      'href="Text/chapter%20one.xhtml"',
      'href="Sub/../Text/chapter%20one.xhtml"',
    );
    final out = Archive();
    for (final f in a.files) {
      out.add(
        f.name == opf.name
            ? ArchiveFile.bytes(f.name, Uint8List.fromList(text.codeUnits))
            : f,
      );
    }
    final b = parseEpub(ZipEncoder().encodeBytes(out));
    expect(b.spine.single.href, 'OEBPS/Text/chapter one.xhtml');
  });

  test('DRM and broken files are refused', () {
    expect(
      () => parseEpub(buildEpub(encrypted: true)),
      throwsA(
        isA<EpubException>().having((e) => e.error, 'error', EpubError.drm),
      ),
    );
    expect(
      () => parseEpub(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(
        isA<EpubException>().having((e) => e.error, 'error', EpubError.invalid),
      ),
    );
  });

  test('obfuscated fonts alone are not DRM', () {
    expect(parseEpub(buildEpub(obfuscatedFont: true)).title, 'テスト');
  });

  test('visibleText skips furigana, scripts and styles; decodes entities', () {
    expect(
      visibleText(
        '<html><body><p><ruby>漢<rp>(</rp><rt>かん</rt><rp>)</rp></ruby>字</p></body></html>',
      ),
      '漢字',
    );
    expect(
      visibleText(
        '<html><head><style>p{}</style></head><body><script>x</script>'
        '<p>A&amp;B</p></body></html>',
      ),
      'A&B',
    );
  });
}
