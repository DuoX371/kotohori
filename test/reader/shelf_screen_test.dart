import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/notices/notices.dart';
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
);

Future<void> pump(WidgetTester t, List<Book> books) => t.pumpWidget(
  ProviderScope(
    overrides: [
      booksProvider.overrideWith((_) => Stream.value(books)),
      noticesProvider.overrideWithValue(const []),
    ],
    child: const MaterialApp(home: ReaderShelfScreen()),
  ),
);

void main() {
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

  testWidgets('long-press asks before removing', (t) async {
    await pump(t, [book('Book A', 0.62)]);
    await t.pump();
    await t.longPress(find.text('Book A'));
    await t.pumpAndSettle();
    expect(find.text('Remove "Book A"?'), findsOneWidget);
    expect(
      find.text(
        "Kotohori deletes its copy and your reading position. "
        "Your original file isn't touched.",
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });
}
