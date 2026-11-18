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

  test('details: publisher, year, language, blurb and calibre series', () {
    final d = epubDetails(
      buildEpub(
        extraMetadata:
            '<dc:publisher>小学館</dc:publisher><dc:date>2025-02-18T00:00:00+00:00</dc:date>'
            '<dc:language>ja</dc:language>'
            '<dc:description>&lt;p&gt;文芸部の&lt;b&gt;日常&lt;/b&gt;。&lt;/p&gt;</dc:description>'
            '<meta name="calibre:series" content="負けヒロインが多すぎる！"/>'
            '<meta name="calibre:series_index" content="8.0"/>',
      ),
    );
    expect(d.title, 'テスト');
    expect(d.author, '作者');
    expect(d.publisher, '小学館');
    expect(d.year, '2025');
    expect(d.language, 'ja');
    expect(d.description, '文芸部の日常。');
    expect(d.series, '負けヒロインが多すぎる！');
    expect(d.seriesIndex, '8');
  });

  test('details: EPUB 3 collections; missing fields stay empty', () {
    final d = epubDetails(
      buildEpub(
        extraMetadata:
            '<meta property="belongs-to-collection" id="c1">シリーズ</meta>'
            '<meta refines="#c1" property="group-position">3</meta>',
      ),
    );
    expect((d.series, d.seriesIndex), ('シリーズ', '3'));
    expect((d.publisher, d.year, d.description), (null, null, null));
  });

  test('details: illustrator and translator roles, genres, ISBN', () {
    final d = epubDetails(
      buildEpub(
        author: null,
        extraMetadata:
            // EPUB 2 roles as attributes …
            '<dc:creator opf:role="aut" xmlns:opf="http://www.idpf.org/2007/opf">雨森たきび</dc:creator>'
            '<dc:creator opf:role="ill" xmlns:opf="http://www.idpf.org/2007/opf">いみぎむる</dc:creator>'
            // … EPUB 3 roles as refining metadata.
            '<dc:contributor id="t1">Translator Name</dc:contributor>'
            '<meta refines="#t1" property="role" scheme="marc:relators">trl</meta>'
            '<dc:subject>ライトノベル</dc:subject><dc:subject>ラブコメ</dc:subject>'
            '<dc:identifier>urn:isbn:9784094532099</dc:identifier>',
      ),
    );
    expect(d.author, '雨森たきび');
    expect(d.illustrators, ['いみぎむる']);
    expect(d.translators, ['Translator Name']);
    expect(d.subjects, ['ライトノベル', 'ラブコメ']);
    expect(d.isbn, '9784094532099');
  });
}
