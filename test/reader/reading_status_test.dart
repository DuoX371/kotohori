import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/library_db.dart';
import 'package:kotohori/features/reader/reading_status.dart';

Book book({double progress = 0, int? lastReadAt, int? finishedAt}) => Book(
  hash: 'h',
  title: 't',
  chapterLengths: '[100]',
  addedAt: 0,
  lastReadAt: lastReadAt,
  chapter: 0,
  offset: 0,
  progress: progress,
  readingMs: 0,
  finishedAt: finishedAt,
);

void main() {
  test('never opened → not started', () {
    expect(statusOf(book()), ReadingStatus.notStarted);
  });

  test('opened → reading, even at 0%', () {
    expect(statusOf(book(lastReadAt: 1)), ReadingStatus.reading);
    expect(statusOf(book(lastReadAt: 1, progress: 0.6)), ReadingStatus.reading);
  });

  test('the end reached, or marked → finished', () {
    expect(
      statusOf(book(lastReadAt: 1, progress: 0.996)),
      ReadingStatus.finished,
    );
    expect(
      statusOf(book(progress: 0.2, finishedAt: 5)),
      ReadingStatus.finished,
    );
  });

  test('filters: All shows everything, others match the status', () {
    final books = [
      book(),
      book(lastReadAt: 1),
      book(progress: 0.3, finishedAt: 5),
    ];
    expect(ShelfFilter.all.apply(books), hasLength(3));
    expect(ShelfFilter.reading.apply(books).single.lastReadAt, 1);
    expect(ShelfFilter.finished.apply(books).single.finishedAt, 5);
  });
}
