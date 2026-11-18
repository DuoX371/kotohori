import 'dart:typed_data';

import 'package:archive/archive.dart';

/// A tiny EPUB in memory. Chapters live in `Text/` (one named with a space, so
/// its href is percent-encoded); the OPF sits in `OEBPS/` unless
/// [opfInSubfolder] is false.
Uint8List buildEpub({
  String title = 'テスト',
  String? author = '作者',
  bool opfInSubfolder = true,
  bool nav = true,
  bool ncx = false,
  bool cover = true,
  bool encrypted = false,
  bool obfuscatedFont = false,
  List<String> chapters = const ['<p>本文です。</p>'],
}) {
  final root = opfInSubfolder ? 'OEBPS/' : '';
  final a = Archive()
    ..add(ArchiveFile.string('mimetype', 'application/epub+zip'))
    ..add(
      ArchiveFile.string(
        'META-INF/container.xml',
        '<?xml version="1.0"?><container version="1.0" '
            'xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles>'
            '<rootfile full-path="${root}content.opf" '
            'media-type="application/oebps-package+xml"/></rootfiles></container>',
      ),
    );
  if (encrypted || obfuscatedFont) {
    // DRM encrypts content; font obfuscation (IDPF) only scrambles fonts.
    final (algorithm, uri) = encrypted
        ? (
            'http://www.w3.org/2001/04/xmlenc#aes128-cbc',
            '${root}Text/ch1.xhtml',
          )
        : ('http://www.idpf.org/2008/embedding', '${root}Fonts/f.otf');
    a.add(
      ArchiveFile.string(
        'META-INF/encryption.xml',
        '<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container" '
            'xmlns:enc="http://www.w3.org/2001/04/xmlenc#"><enc:EncryptedData>'
            '<enc:EncryptionMethod Algorithm="$algorithm"/><enc:CipherData>'
            '<enc:CipherReference URI="$uri"/></enc:CipherData>'
            '</enc:EncryptedData></encryption>',
      ),
    );
  }
  String fileName(int i) => i == 0 ? 'chapter one.xhtml' : 'ch$i.xhtml';
  final manifest = StringBuffer(), spine = StringBuffer();
  for (final (i, body) in chapters.indexed) {
    final href = 'Text/${Uri.encodeComponent(fileName(i))}';
    manifest.write(
      '<item id="c$i" href="$href" media-type="application/xhtml+xml"/>',
    );
    spine.write('<itemref idref="c$i"/>');
    a.add(
      ArchiveFile.string(
        '${root}Text/${fileName(i)}',
        '<?xml version="1.0" encoding="utf-8"?>'
            '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c</title>'
            '</head><body>$body</body></html>',
      ),
    );
  }
  if (cover) {
    manifest.write(
      '<item id="cov" href="Images/cover.jpg" media-type="image/jpeg" '
      'properties="cover-image"/>',
    );
    a.add(ArchiveFile.bytes('${root}Images/cover.jpg', [1, 2, 3]));
  }
  if (nav) {
    manifest.write(
      '<item id="nav" href="Text/nav.xhtml" media-type="application/xhtml+xml" '
      'properties="nav"/>',
    );
    final items = [
      for (final (i, _) in chapters.indexed)
        '<li><a href="${Uri.encodeComponent(fileName(i))}#top">第${i + 1}章</a></li>',
    ].join();
    a.add(
      ArchiveFile.string(
        '${root}Text/nav.xhtml',
        '<html xmlns="http://www.w3.org/1999/xhtml" '
            'xmlns:epub="http://www.idpf.org/2007/ops"><body>'
            '<nav epub:type="toc"><ol>$items</ol></nav></body></html>',
      ),
    );
  }
  if (ncx) {
    manifest.write(
      '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
    );
    final points = [
      for (final (i, _) in chapters.indexed)
        '<navPoint id="p$i"><navLabel><text>章${i + 1}</text></navLabel>'
            '<content src="Text/${Uri.encodeComponent(fileName(i))}"/></navPoint>',
    ].join();
    a.add(
      ArchiveFile.string(
        '${root}toc.ncx',
        '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/"><navMap>$points'
            '</navMap></ncx>',
      ),
    );
  }
  a.add(
    ArchiveFile.string(
      '${root}content.opf',
      '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" '
          'version="3.0"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
          '<dc:title>$title</dc:title>'
          '${author == null ? '' : '<dc:creator>$author</dc:creator>'}'
          '</metadata><manifest>$manifest</manifest>'
          '<spine${ncx ? ' toc="ncx"' : ''}>$spine</spine></package>',
    ),
  );
  return ZipEncoder().encodeBytes(a);
}
