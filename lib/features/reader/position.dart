/// How far through a book (0..1) the reading position is: whole chapters
/// before [chapter] plus [offset] characters into it. [lengths] are the
/// chapters' visible-text lengths.
double bookProgress(List<int> lengths, int chapter, int offset) {
  final total = lengths.fold(0, (a, b) => a + b);
  if (total == 0) return 0;
  var read = 0;
  for (var i = 0; i < chapter && i < lengths.length; i++) {
    read += lengths[i];
  }
  if (chapter < lengths.length) read += offset.clamp(0, lengths[chapter]);
  return (read / total).clamp(0.0, 1.0);
}

/// The page number in the whole book and the book's page count, estimated:
/// other chapters at [charsPerPage] (each at least one page: covers and
/// pictures), the current one with its real [chapterPages]. [page] is the
/// 0-based page in [chapter].
///
/// shortcut: an estimate from one chapter's density; exact counts would need
/// every chapter laid out at the current settings.
({int page, int total}) bookPages(
  List<int> lengths, {
  required int chapter,
  required int page,
  required int chapterPages,
  required double charsPerPage,
}) {
  int pagesOf(int i) => i == chapter
      ? chapterPages
      : (lengths[i] / charsPerPage).ceil().clamp(1, 1 << 30);
  var before = 0, total = 0;
  for (var i = 0; i < lengths.length; i++) {
    final n = pagesOf(i);
    if (i < chapter) before += n;
    total += n;
  }
  return (page: before + page + 1, total: total);
}
