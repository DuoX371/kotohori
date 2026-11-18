import 'library_db.dart';

enum ReadingStatus { notStarted, reading, finished }

/// Where the reader is with [b]: finished at the very end (the last pages are
/// often an afterword, so marking by hand also counts), reading once opened.
ReadingStatus statusOf(Book b) {
  if (b.finishedAt != null || b.progress >= 0.995) {
    return ReadingStatus.finished;
  }
  return b.lastReadAt == null
      ? ReadingStatus.notStarted
      : ReadingStatus.reading;
}

enum ShelfFilter {
  all('All'),
  reading('Reading'),
  finished('Completed');

  const ShelfFilter(this.label);
  final String label;

  List<Book> apply(List<Book> books) => switch (this) {
    all => books,
    reading => [
      for (final b in books)
        if (statusOf(b) == ReadingStatus.reading) b,
    ],
    finished => [
      for (final b in books)
        if (statusOf(b) == ReadingStatus.finished) b,
    ],
  };
}
