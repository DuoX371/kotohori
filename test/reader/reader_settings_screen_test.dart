import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/ui/providers.dart';
import 'package:kotohori/features/reader/reader_settings.dart';
import 'package:kotohori/features/reader/reader_settings_sheet.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
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
}
