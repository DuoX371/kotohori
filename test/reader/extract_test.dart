import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/book_view.dart';
import 'package:path/path.dart' as p;

void main() {
  test('unpacks a book once and never writes outside its folder', () async {
    final tmp = Directory.systemTemp.createTempSync('kotohori_extract');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final zip = Archive()
      ..add(ArchiveFile.string('OEBPS/Text/a.xhtml', 'a'))
      ..add(ArchiveFile.string('../evil.txt', 'x'));
    final epub = File(p.join(tmp.path, 'b.epub'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(zip));
    final dir = p.join(tmp.path, 'books', 'hash');

    await extractEpub(epub.path, dir);
    expect(
      File(p.join(dir, 'OEBPS', 'Text', 'a.xhtml')).readAsStringSync(),
      'a',
    );
    expect(File(p.join(tmp.path, 'books', 'evil.txt')).existsSync(), isFalse);
    expect(Directory('$dir.part').existsSync(), isFalse);

    File(p.join(dir, 'OEBPS', 'Text', 'a.xhtml')).writeAsStringSync('kept');
    await extractEpub(epub.path, dir); // already there: left alone
    expect(
      File(p.join(dir, 'OEBPS', 'Text', 'a.xhtml')).readAsStringSync(),
      'kept',
    );
  });

  test('chapters start hidden until the reader has laid them out', () async {
    final tmp = Directory.systemTemp.createTempSync('kotohori_extract');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final zip = Archive()
      ..add(
        ArchiveFile.string(
          'Text/c.xhtml',
          '<html><HEAD><title>t</title></HEAD><body><p>本</p></body></html>',
        ),
      )
      ..add(ArchiveFile.string('Images/i.png', 'png'));
    final epub = File(p.join(tmp.path, 'b.epub'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(zip));
    final dir = p.join(tmp.path, 'books', 'hash');
    await extractEpub(epub.path, dir);
    final chapter = File(p.join(dir, 'Text', 'c.xhtml')).readAsStringSync();
    expect(chapter, contains('<style id="kh-hide">'));
    expect(chapter.indexOf('kh-hide'), lessThan(chapter.indexOf('</HEAD>')));
    expect(chapter, contains('<body><p>本</p></body>')); // text untouched
    expect(File(p.join(dir, 'Images', 'i.png')).readAsStringSync(), 'png');
  });

  test('a chapter without a doctype gets one, after any XML declaration', () {
    String fix(String s) => utf8.decode(hidePage(utf8.encode(s)));
    expect(
      fix('<html><head></head><body>本</body></html>'),
      startsWith('<!DOCTYPE html><html>'),
    );
    expect(
      fix('<?xml version="1.0" encoding="utf-8"?>\n<html><head></head></html>'),
      startsWith(
        '<?xml version="1.0" encoding="utf-8"?><!DOCTYPE html>\n<html>',
      ),
    );
    const standard = '<!DOCTYPE html>\n<html><head></head></html>';
    expect(fix(standard).indexOf('<!DOCTYPE'), 0);
    expect('<!DOCTYPE'.allMatches(fix(standard)), hasLength(1));
  });

  test('a folder unpacked by an older version is unpacked again', () async {
    final tmp = Directory.systemTemp.createTempSync('kotohori_extract');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final zip = Archive()
      ..add(ArchiveFile.string('c.xhtml', '<html><head></head><body/></html>'));
    final epub = File(p.join(tmp.path, 'b.epub'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(zip));
    final dir = p.join(tmp.path, 'books', 'hash');
    File(p.join(dir, 'c.xhtml'))
      ..createSync(recursive: true)
      ..writeAsStringSync('old');
    await extractEpub(epub.path, dir);
    expect(
      File(p.join(dir, 'c.xhtml')).readAsStringSync(),
      contains('kh-hide'),
    );
  });
}
