import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart'
    show prefsProvider;
import 'package:kotohori/features/notices/notices.dart';
import 'package:drift/native.dart';
import 'package:kotohori/features/reader/book_repo.dart';
import 'package:kotohori/features/reader/epub.dart';
import 'package:kotohori/features/reader/library_db.dart';
import 'package:kotohori/features/reader/reader_providers.dart';
import 'package:kotohori/features/reader/shelf_screen.dart';

Book book(String title, double progress, {int? lastReadAt, int? finishedAt}) =>
    Book(
      hash: title,
      title: title,
      chapterLengths: '[100]',
      addedAt: 0,
      chapter: 0,
      offset: 0,
      progress: progress,
      readingMs: 0,
      lastReadAt: lastReadAt,
      finishedAt: finishedAt,
    );

/// Records removals instead of touching files or a database.
class FakeRepo extends BookRepo {
  FakeRepo() : super(LibraryDb(NativeDatabase.memory()), booksDir: 'unused');
  final removed = <String>[];
  final finished = <String, bool>{};

  @override
  Future<void> remove(String hash) async => removed.add(hash);

  @override
  Future<void> setFinished(Iterable<String> hashes, bool value) async {
    for (final h in hashes) {
      finished[h] = value;
    }
  }
}

late FakeRepo repo;

Future<void> pump(WidgetTester t, List<Book> books) => t.pumpWidget(
  ProviderScope(
    overrides: [
      bookRepoProvider.overrideWithValue(repo),
      prefsProvider.overrideWithValue(prefs),
      booksProvider.overrideWith((_) => Stream.value(books)),
      noticesProvider.overrideWithValue(const []),
      bookDetailsProvider.overrideWith(
        (ref, hash) async => EpubDetails(title: hash),
      ),
    ],
    child: const MaterialApp(home: ReaderShelfScreen()),
  ),
);

late SharedPreferences prefs;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = FakeRepo();
  });
  tearDown(() => repo.db.close());

  testWidgets('an empty shelf offers to add the first book', (t) async {
    await pump(t, const []);
    await t.pump();
    expect(find.text('Add your first book'), findsOneWidget);
  });

  testWidgets('books show their title and progress', (t) async {
    await pump(t, [book('Book A', 0.62), book('Book B', 0)]);
    await t.pump();
    expect(find.text('Book A'), findsOneWidget);
    expect(find.text('Book B'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('long-press menu: Details opens the sheet; Remove asks first', (
    t,
  ) async {
    await pump(t, [book('Book A', 0.62)]);
    await t.pump();
    await t.longPress(find.text('Book A'));
    await t.pumpAndSettle();
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    expect(find.text('Continue reading'), findsOneWidget);
    await t.tap(find.text('Remove'));
    await t.pumpAndSettle();
    expect(find.text('Remove "Book A"?'), findsOneWidget);
    // The details stay underneath the question; Cancel returns to them.
    expect(find.text('Continue reading'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Continue reading'), findsOneWidget);
    await t.tap(find.text('Remove'));
    await t.pumpAndSettle();
    expect(
      find.text(
        "Kotohori deletes its copy and your reading position. "
        "Your original file isn't touched.",
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.text('Remove'),
      findsNWidgets(2),
    ); // the sheet's and the dialog's
  });

  testWidgets('select several books and remove them together', (t) async {
    await pump(t, [book('Book A', 0), book('Book B', 0), book('Book C', 0)]);
    await t.pump();
    await t.tap(find.byTooltip('Select'));
    await t.pump();
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.text('Add book'), findsNothing); // hidden while selecting
    await t.tap(find.text('Book A'));
    await t.tap(find.text('Book C'));
    await t.pump();
    expect(find.text('2 selected'), findsOneWidget);
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(find.text('Remove 2 books?'), findsOneWidget);
    await t.tap(find.text('Remove'));
    await t.pumpAndSettle();
    expect(repo.removed, unorderedEquals(['Book A', 'Book C']));
    expect(find.text('Removed 2 books'), findsOneWidget);
    expect(find.text('Reader'), findsOneWidget); // back to the normal bar
  });

  testWidgets('select all, cancel keeps them; close leaves selection', (
    t,
  ) async {
    await pump(t, [book('Book A', 0), book('Book B', 0)]);
    await t.pump();
    await t.tap(find.byTooltip('Select'));
    await t.pump();
    await t.tap(find.byTooltip('Select all'));
    await t.pump();
    expect(find.text('2 selected'), findsOneWidget);
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(repo.removed, isEmpty);
    expect(find.text('2 selected'), findsOneWidget);
    await t.tap(find.byTooltip('Done selecting'));
    await t.pump();
    expect(find.text('Reader'), findsOneWidget);
  });

  testWidgets('chips show only reading or only finished books', (t) async {
    await pump(t, [
      book('New', 0),
      book('Halfway', 0.5, lastReadAt: 1),
      book('Done', 0.4, lastReadAt: 1, finishedAt: 2),
    ]);
    await t.pump();
    expect(find.text('New'), findsOneWidget);
    await t.tap(find.text('Reading'));
    await t.pumpAndSettle();
    expect(find.text('Halfway'), findsOneWidget);
    expect(find.text('New'), findsNothing);
    expect(find.text('Done'), findsNothing);
    await t.tap(find.text('Completed'));
    await t.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Halfway'), findsNothing);
  });

  testWidgets('selected books can be marked finished, or not', (t) async {
    await pump(t, [
      book('A', 0.5, lastReadAt: 1),
      book('B', 0.4, lastReadAt: 1, finishedAt: 2),
    ]);
    await t.pump();
    await t.tap(find.byTooltip('Select'));
    await t.pump();
    await t.tap(find.text('A'));
    await t.pump();
    await t.tap(find.text('Mark completed'));
    await t.pump();
    expect(repo.finished, {'A': true});
    expect(find.text('Reader'), findsOneWidget); // selection ends
    await t.tap(find.byTooltip('Select'));
    await t.pump();
    await t.tap(find.text('B')); // already finished
    await t.pump();
    await t.tap(find.text('Mark not completed'));
    await t.pump();
    expect(repo.finished['B'], isFalse);
  });

  testWidgets('long-press menu marks a book finished, and undoes a mark', (
    t,
  ) async {
    await pump(t, [
      book('Open', 0.3, lastReadAt: 1),
      book('Marked', 0.3, lastReadAt: 1, finishedAt: 2),
      book('Read through', 1, lastReadAt: 1),
    ]);
    await t.pump();
    // Two covers show it instead of the bar (plus the tab).
    expect(find.text('Completed'), findsNWidgets(3));
    await t.longPress(find.text('Open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mark as completed'));
    await t.pumpAndSettle();
    expect(repo.finished, {'Open': true});
    await t.longPress(find.text('Marked'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mark as not completed'));
    await t.pumpAndSettle();
    expect(repo.finished['Marked'], isFalse);
    // Finished by reading to the end: nothing to undo.
    await t.longPress(find.text('Read through'));
    await t.pumpAndSettle();
    expect(find.text('Mark as not completed'), findsNothing);
    expect(find.text('Mark as completed'), findsNothing);
  });

  testWidgets('select all turns into deselect all', (t) async {
    await pump(t, [book('A', 0), book('B', 0)]);
    await t.pump();
    await t.tap(find.byTooltip('Select'));
    await t.pump();
    await t.tap(find.byTooltip('Select all'));
    await t.pump();
    expect(find.text('2 selected'), findsOneWidget);
    await t.tap(find.byTooltip('Deselect all'));
    await t.pump();
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.byTooltip('Select all'), findsOneWidget);
  });

  testWidgets('Undo after marking puts back only what changed', (t) async {
    await pump(t, [
      book('A', 0.5, lastReadAt: 1),
      book('B', 0.4, lastReadAt: 1, finishedAt: 2),
    ]);
    await t.pump();
    await t.tap(find.byTooltip('Select'));
    await t.pump();
    await t.tap(find.text('A'));
    await t.tap(find.text('B'));
    await t.pump();
    await t.tap(find.text('Mark completed'));
    await t.pump();
    expect(repo.finished, {'A': true, 'B': true});
    await t.pumpAndSettle(); // the message slides in
    await t.tap(find.text('Undo'));
    await t.pump();
    expect(repo.finished, {'A': false, 'B': true}); // B was already marked
  });

  testWidgets('the tab is remembered; an empty one says what to do', (t) async {
    await pump(t, [book('A', 0)]);
    await t.pump();
    await t.tap(find.text('Completed'));
    await t.pumpAndSettle();
    expect(find.text('Hold a book to mark it completed.'), findsOneWidget);
    expect(prefs.getInt('reader.shelf.tab'), 2);
  });
}
