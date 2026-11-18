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
}
