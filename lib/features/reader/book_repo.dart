import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'epub.dart';
import 'library_db.dart';
import 'position.dart';

/// The bookshelf: copies of the user's EPUBs (named by their SHA-256) and
/// where they are in each.
class BookRepo {
  BookRepo(this.db, {required this.booksDir});
  final LibraryDb db;
  final String booksDir;

  String epubPath(String hash) => p.join(booksDir, '$hash.epub');
  String _coverPath(String hash) => p.join(booksDir, '$hash.cover');

  /// Where the reader unpacks the book to show it.
  String extractedDir(String hash) => p.join(booksDir, hash);

  /// Adds the EPUB at [path]. The same file already on the shelf is not
  /// copied again ([existed]). Throws [EpubException] before writing anything.
  Future<({Book book, bool existed})> addFromFile(String path) async {
    final bytes = await File(path).readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final known = await (db.select(
      db.books,
    )..where((b) => b.hash.equals(hash))).getSingleOrNull();
    if (known != null) return (book: known, existed: true);

    final epub = await parseEpubInBackground(bytes);
    final copy = File(epubPath(hash));
    final cover = epub.cover == null ? null : File(_coverPath(hash));
    try {
      await Directory(booksDir).create(recursive: true);
      await copy.writeAsBytes(bytes, flush: true);
      await cover?.writeAsBytes(epub.cover!, flush: true);
      final row = BooksCompanion.insert(
        hash: hash,
        title: epub.title,
        author: Value(epub.author),
        coverPath: Value(cover?.path),
        chapterLengths: jsonEncode([for (final c in epub.spine) c.length]),
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return (
        book: await db.into(db.books).insertReturning(row),
        existed: false,
      );
    } on Object {
      // Nothing half-added: no orphan copy without a row.
      for (final f in [copy, ?cover]) {
        if (f.existsSync()) f.deleteSync();
      }
      rethrow;
    }
  }

  /// The shelf, most recently read (or added) first.
  Stream<List<Book>> watchAll() =>
      (db.select(db.books)..orderBy([
            (b) => OrderingTerm.desc(coalesce([b.lastReadAt, b.addedAt])),
          ]))
          .watch();

  Future<void> savePosition(
    String hash, {
    required int chapter,
    required int offset,
  }) async {
    final book = await (db.select(
      db.books,
    )..where((b) => b.hash.equals(hash))).getSingleOrNull();
    if (book == null) return;
    final lengths = (jsonDecode(book.chapterLengths) as List).cast<int>();
    await (db.update(db.books)..where((b) => b.hash.equals(hash))).write(
      BooksCompanion(
        chapter: Value(chapter),
        offset: Value(offset),
        progress: Value(bookProgress(lengths, chapter, offset)),
        lastReadAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Adds [ms] of reading to the book's total.
  Future<void> addReadingTime(String hash, int ms) async {
    if (ms <= 0) return;
    await db.customUpdate(
      'UPDATE books SET reading_ms = reading_ms + ? WHERE hash = ?',
      variables: [Variable(ms), Variable(hash)],
      updates: {db.books},
    );
  }

  Future<void> setFinished(Iterable<String> hashes, bool finished) async {
    await (db.update(db.books)..where((b) => b.hash.isIn(hashes))).write(
      BooksCompanion(
        finishedAt: Value(
          finished ? DateTime.now().millisecondsSinceEpoch : null,
        ),
      ),
    );
  }

  /// Removes the book and everything Kotohori stored for it. The user's
  /// original file is never touched.
  Future<void> remove(String hash) async {
    await (db.delete(db.books)..where((b) => b.hash.equals(hash))).go();
    for (final f in [File(epubPath(hash)), File(_coverPath(hash))]) {
      if (f.existsSync()) f.deleteSync();
    }
    final dir = Directory(extractedDir(hash));
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// [parseEpub] off the UI thread, so adding books (several at once, or a big
/// one) doesn't freeze the app. Top-level so the isolate gets only [bytes].
Future<EpubBook> parseEpubInBackground(Uint8List bytes) =>
    Isolate.run(() => parseEpub(bytes));
