import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/book_repo.dart';
import 'package:kotohori/features/reader/epub.dart';
import 'package:kotohori/features/reader/library_db.dart';
import 'package:path/path.dart' as p;

import 'epub_fixture.dart';

void main() {
  late Directory tmp;
  late LibraryDb db;
  late BookRepo repo;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kotohori_books');
    db = LibraryDb(NativeDatabase.memory());
    repo = BookRepo(db, booksDir: p.join(tmp.path, 'books'));
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  String epubFile(String name, {String title = 'テスト', bool drm = false}) {
    final f = File(p.join(tmp.path, name))
      ..writeAsBytesSync(buildEpub(title: title, encrypted: drm));
    return f.path;
  }

  test('adding stores the row, the copy and the cover', () async {
    final r = await repo.addFromFile(epubFile('a.epub'));
    expect(r.existed, isFalse);
    expect(r.book.title, 'テスト');
    expect(r.book.author, '作者');
    expect(File(repo.epubPath(r.book.hash)).existsSync(), isTrue);
    expect(File(r.book.coverPath!).readAsBytesSync(), [1, 2, 3]);
    expect(r.book.chapterLengths, '[5]');
  });

  test('the same book from another place is not stored twice', () async {
    final first = await repo.addFromFile(epubFile('a.epub'));
    final again = await repo.addFromFile(epubFile('copy of a.epub'));
    expect(again.existed, isTrue);
    expect(again.book.hash, first.book.hash);
    expect(await repo.watchAll().first, hasLength(1));
    final epubs = Directory(p.join(tmp.path, 'books'))
        .listSync()
        .where((f) => f.path.endsWith('.epub'));
    expect(epubs, hasLength(1));
  });

  test('a DRM book leaves no row and no file', () async {
    await expectLater(
      repo.addFromFile(epubFile('drm.epub', drm: true)),
      throwsA(isA<EpubException>().having((e) => e.error, 'e', EpubError.drm)),
    );
    expect(await repo.watchAll().first, isEmpty);
    final dir = Directory(p.join(tmp.path, 'books'));
    expect(dir.existsSync() ? dir.listSync() : const [], isEmpty);
  });

  test('a failed copy leaves no row', () async {
    File(p.join(tmp.path, 'books')).writeAsStringSync('not a folder');
    await expectLater(repo.addFromFile(epubFile('a.epub')), throwsA(anything));
    expect(await repo.watchAll().first, isEmpty);
  });

  test('most recently read first; position updates progress', () async {
    final a = (await repo.addFromFile(epubFile('a.epub', title: 'A'))).book;
    final b = (await repo.addFromFile(epubFile('b.epub', title: 'B'))).book;
    expect((await repo.watchAll().first).map((x) => x.title), ['B', 'A']);
    await repo.savePosition(a.hash, chapter: 0, offset: 2);
    final books = await repo.watchAll().first;
    expect(books.map((x) => x.title), ['A', 'B']);
    expect(books.first.progress, closeTo(2 / 5, 1e-9));
    expect((books.first.chapter, books.first.offset), (0, 2));
    expect(b.lastReadAt, isNull);
  });

  test(
    'remove deletes the row, the copy, the cover and the extracted files',
    () async {
      final b = (await repo.addFromFile(epubFile('a.epub'))).book;
      Directory(repo.extractedDir(b.hash)).createSync(recursive: true);
      await repo.remove(b.hash);
      expect(await repo.watchAll().first, isEmpty);
      expect(File(repo.epubPath(b.hash)).existsSync(), isFalse);
      expect(File(b.coverPath!).existsSync(), isFalse);
      expect(Directory(repo.extractedDir(b.hash)).existsSync(), isFalse);
    },
  );

  test('reading time adds up per book', () async {
    final b = (await repo.addFromFile(epubFile('a.epub'))).book;
    await repo.addReadingTime(b.hash, 60000);
    await repo.addReadingTime(b.hash, 30000);
    await repo.addReadingTime(b.hash, 0);
    expect((await repo.watchAll().first).single.readingMs, 90000);
  });
}
