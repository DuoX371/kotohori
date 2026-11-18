import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart'
    show prefsProvider;
import 'package:kotohori/features/reader/book_details_sheet.dart';
import 'package:kotohori/features/reader/epub.dart';
import 'package:kotohori/features/reader/library_db.dart';
import 'package:kotohori/features/reader/reader_providers.dart';

final book = Book(
  hash: 'h',
  title: '負けヒロインが多すぎる！ ８',
  author: '雨森たきび',
  chapterLengths: '[100]',
  addedAt: DateTime(2026, 11, 17).millisecondsSinceEpoch,
  lastReadAt: DateTime(2026, 11, 18).millisecondsSinceEpoch,
  chapter: 0,
  offset: 0,
  progress: 0.12,
  readingMs: 2 * 3600 * 1000,
);

Future<void> pump(
  WidgetTester t, {
  VoidCallback? onContinue,
  VoidCallback? onRemove,
}) => t.pumpWidget(
  ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      bookDetailsProvider('h').overrideWith(
        (_) async => const EpubDetails(
          title: '負けヒロインが多すぎる！ ８',
          author: '雨森たきび',
          publisher: '小学館',
          year: '2025',
          description: '文芸部の日常。',
          series: '負けヒロインが多すぎる！',
          seriesIndex: '8',
        ),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: BookDetails(book, onContinue: onContinue, onRemove: onRemove),
      ),
    ),
  ),
);

late SharedPreferences prefs;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('shows the book, its details and progress', (t) async {
    await pump(t, onContinue: () {}, onRemove: () {});
    await t.pump();
    expect(find.text('負けヒロインが多すぎる！ ８'), findsOneWidget);
    expect(find.text('雨森たきび'), findsOneWidget);
    expect(find.text('小学館 · 2025'), findsOneWidget);
    expect(find.text('負けヒロインが多すぎる！ #8'), findsOneWidget);
    expect(find.text('文芸部の日常。'), findsOneWidget);
    expect(find.textContaining('12% read'), findsOneWidget);
    expect(find.text('Continue reading'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('inside the reader: no continue or remove buttons', (t) async {
    await pump(t);
    await t.pump();
    expect(find.text('Continue reading'), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('the language shows by name next to the publisher', (t) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          bookDetailsProvider('h').overrideWith(
            (_) async =>
                const EpubDetails(title: 't', publisher: '小学館', language: 'ja'),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: BookDetails(book))),
      ),
    );
    await t.pump();
    expect(find.text('小学館 · Japanese'), findsOneWidget);
  });

  test('language names: known codes by name, others as written', () {
    expect(languageName('ja'), 'Japanese');
    expect(languageName('ja-JP'), 'Japanese');
    expect(languageName('en'), 'English');
    expect(languageName('tlh'), 'TLH');
  });

  testWidgets('credits, genres, length, time and cards mined', (t) async {
    SharedPreferences.setMockInitialValues({'reader.pace.cpm': 100});
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          bookDetailsProvider('h').overrideWith(
            (_) async => const EpubDetails(
              title: 't',
              illustrators: ['いみぎむる'],
              subjects: ['ラブコメ'],
              isbn: '9784094532099',
            ),
          ),
          cardsMinedProvider(book.title).overrideWith((_) async => 37),
        ],
        child: MaterialApp(home: Scaffold(body: BookDetails(book))),
      ),
    );
    await t.pump();
    expect(find.text('Illustration: いみぎむる'), findsOneWidget);
    expect(find.text('ラブコメ'), findsOneWidget);
    expect(find.text('1 chapter · 100 characters'), findsOneWidget);
    expect(find.text('2 h'), findsOneWidget); // time spent
    expect(
      find.text('~1 min at your pace'),
      findsOneWidget,
    ); // 100 chars at 100/min
    expect(find.text('37'), findsOneWidget);
    expect(find.text('ISBN 9784094532099'), findsOneWidget);
  });
}
