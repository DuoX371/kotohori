import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart'
    show prefsProvider;
import 'package:kotohori/features/notices/notices.dart';
import 'package:kotohori/features/reader/epub.dart';
import 'package:kotohori/features/reader/library_db.dart';
import 'package:kotohori/features/reader/reader_providers.dart';
import 'package:kotohori/features/reader/shelf_screen.dart';

Book book(String title, double progress) => Book(
  hash: title,
  title: title,
  chapterLengths: '[100]',
  addedAt: 0,
  chapter: 0,
  offset: 0,
  progress: progress,
  readingMs: 0,
);

Future<void> pump(WidgetTester t, List<Book> books) => t.pumpWidget(
  ProviderScope(
    overrides: [
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
  });

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

  testWidgets('long-press shows the details; Remove there asks first', (
    t,
  ) async {
    await pump(t, [book('Book A', 0.62)]);
    await t.pump();
    await t.longPress(find.text('Book A'));
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
}
