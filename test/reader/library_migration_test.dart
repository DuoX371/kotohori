import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/library_db.dart';

void main() {
  test(
    'an existing shelf (schema 1) keeps its books and gains reading time',
    () async {
      final db = LibraryDb(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
            CREATE TABLE books (hash TEXT NOT NULL, title TEXT NOT NULL,
              author TEXT, cover_path TEXT, chapter_lengths TEXT NOT NULL,
              added_at INTEGER NOT NULL, last_read_at INTEGER,
              chapter INTEGER NOT NULL DEFAULT 0,
              char_offset INTEGER NOT NULL DEFAULT 0,
              progress REAL NOT NULL DEFAULT 0, PRIMARY KEY (hash))''');
            raw.execute(
              "INSERT INTO books (hash, title, chapter_lengths, added_at, chapter, char_offset, progress) "
              "VALUES ('h', '本', '[10]', 1, 3, 42, 0.5)",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(db.close);
      final book = await db.select(db.books).getSingle();
      expect(
        (book.title, book.chapter, book.offset, book.progress),
        ('本', 3, 42, 0.5),
      );
      expect(book.readingMs, 0);
    },
  );
}
