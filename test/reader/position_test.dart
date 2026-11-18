import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/position.dart';

void main() {
  test('progress counts the chapters before plus the offset', () {
    expect(bookProgress([10, 0, 30], 2, 15), 25 / 40);
    expect(bookProgress([10, 30], 0, 0), 0);
  });

  test('empty books and offsets past the end stay in 0..1', () {
    expect(bookProgress([0, 0], 1, 0), 0);
    expect(bookProgress([10, 10], 1, 99), 1);
    expect(bookProgress([10], 5, 0), 1);
  });

  test(
    'book pages: chapters before at the current page size, then the page',
    () {
      // 300 characters a page; chapters of 600, 50 (one short page) and 900.
      final p = bookPages(
        [600, 50, 900],
        chapter: 2,
        page: 1,
        chapterPages: 3,
        charsPerPage: 300,
      );
      expect(p, (page: 2 + 1 + 2, total: 2 + 1 + 3));
    },
  );

  test('empty chapters (covers, pictures) still count one page', () {
    expect(
      bookPages(
        [0, 0, 300],
        chapter: 0,
        page: 0,
        chapterPages: 1,
        charsPerPage: 300,
      ),
      (page: 1, total: 3),
    );
  });
}
