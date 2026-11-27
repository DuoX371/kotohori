import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart';
import 'package:kotohori/features/reader/epub.dart';
import 'package:kotohori/features/reader/reader_providers.dart';
import 'package:kotohori/features/reader/reader_settings.dart';
import 'package:kotohori/features/reader/reader_settings_sheet.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({EpubDetails? details}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tmp = Directory.systemTemp.createTempSync('kh_reader_settings');
  addTearDown(() => tmp.deleteSync(recursive: true));
  final c = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      appPathsProvider.overrideWithValue(
        AppPaths(
          dbPath: p.join(tmp.path, 'db'),
          mediaRoot: tmp.path,
          tempDir: tmp.path,
          booksDir: p.join(tmp.path, 'books'),
        ),
      ),
      if (details != null)
        bookDetailsProvider.overrideWith((ref, _) async => details),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  testWidgets('a wide screen scrolls from the side margins too', (t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600, 500); // tablet landscape, short
    addTearDown(t.view.reset);
    final c = await _container();
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: ReaderSettingsScreen(preview: false)),
      ),
    );
    final before = t.getTopLeft(find.text('Theme')).dy;
    await t.dragFrom(
      const Offset(60, 400),
      const Offset(0, -200),
    ); // left margin
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.text('Theme')).dy, lessThan(before));
  });

  testWidgets('Settings → Reader shows the same controls as the Aa sheet', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tmp = Directory.systemTemp.createTempSync('kh_reader_settings');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final c = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        appPathsProvider.overrideWithValue(
          AppPaths(
            dbPath: p.join(tmp.path, 'db'),
            mediaRoot: tmp.path,
            tempDir: tmp.path,
            booksDir: p.join(tmp.path, 'books'),
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        // The sample page is a WebView, which needs a device.
        child: const MaterialApp(home: ReaderSettingsScreen(preview: false)),
      ),
    );
    expect(find.text('Reader'), findsOneWidget); // the page title
    for (final label in ['Theme', 'Font', 'Text direction', 'Font size']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await t.tap(find.text('Horizontal'));
    await t.pump();
    expect(c.read(readerSettingsProvider).vertical, isFalse);
  });

  test('a book keeps only what it changes; the rest follows global', () async {
    final c = await _container();
    final global = c.read(readerSettingsProvider.notifier);
    final book = c.read(bookSettingsProvider('h').notifier);
    await book.change(
      c
          .read(bookReaderSettingsProvider('h'))
          .copyWith(fontSize: 30, theme: () => ReaderTheme.sepia),
    );
    expect(c.read(bookSettingsProvider('h')), {
      'fontSize': 30.0,
      'theme': 'sepia',
    });
    await book.reset('theme');
    await global.update((s) => s.copyWith(lineSpacing: 2.2, fontSize: 18));
    final s = c.read(bookReaderSettingsProvider('h'));
    expect((s.fontSize, s.lineSpacing), (30.0, 2.2));
    expect(c.read(bookReaderSettingsProvider('other')).fontSize, 18);
    // Back to the global value: no longer the book's own.
    await book.change(s.copyWith(fontSize: 18));
    expect(c.read(bookSettingsProvider('h')), isEmpty);
    expect(c.read(prefsProvider).getString('reader.book.h'), isNull);
  });

  testWidgets('This book tab changes only the book', (t) async {
    final c = await _container();
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: Scaffold(body: ReaderSettingsSheet(inSheet: false, book: 'h')),
        ),
      ),
    );
    await t.tap(find.text('This book'));
    await t.pump();
    await t.tap(find.text('Horizontal'));
    await t.pump();
    expect(c.read(readerSettingsProvider).vertical, isTrue);
    expect(c.read(bookReaderSettingsProvider('h')).vertical, isFalse);
    await t.ensureVisible(find.text('Use global settings'));
    await t.tap(find.text('Use global settings'));
    await t.pump();
    expect(c.read(bookSettingsProvider('h')), isEmpty);
    expect(find.text('Use global settings'), findsNothing);
  });

  test('an English book keeps vertical when it asks for it', () async {
    final c = await _container(
      details: const EpubDetails(title: 'B', language: 'en'),
    );
    await c.read(bookDetailsProvider('h').future);
    expect(c.read(bookReaderSettingsProvider('h')).vertical, isFalse);
    final book = c.read(bookSettingsProvider('h').notifier);
    await book.change(
      c.read(bookReaderSettingsProvider('h')).copyWith(vertical: true),
    );
    expect(c.read(bookSettingsProvider('h')), {'vertical': true});
    expect(c.read(bookReaderSettingsProvider('h')).vertical, isTrue);
  });
}
