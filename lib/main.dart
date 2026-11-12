import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_shell.dart';
import 'app/theme.dart';
import 'features/dictionary/data/db.dart';
import 'features/dictionary/data/dictionary_repo.dart';
import 'features/dictionary/ui/providers.dart';
import 'features/settings/appearance_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Zen Kaku Gothic New',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final support = await getApplicationSupportDirectory();
  final temp = await getTemporaryDirectory();
  final paths = AppPaths(
    dbPath: p.join(support.path, 'kotohori.sqlite'),
    mediaRoot: p.join(support.path, 'dict_media'),
    tempDir: temp.path,
  );
  // file_picker caches a full copy of every picked file (only dictionary zips use it now).
  Directory(p.join(temp.path, 'file_picker')).delete(recursive: true).ignore();
  final db = AppDb.open(File(paths.dbPath));
  final prefs = await SharedPreferences.getInstance();

  // Finish deletes / drop half-imports interrupted by a previous app kill.
  DictionaryRepo(
    db,
    mediaRoot: paths.mediaRoot,
    dbPath: paths.dbPath,
  ).purge(includeUnfinished: true).ignore();

  runApp(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        dbProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const KotohoriApp(),
    ),
  );
}

class KotohoriApp extends ConsumerWidget {
  const KotohoriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snackWidth = snackBarWidth(MediaQuery.sizeOf(context));
    return MaterialApp(
      title: 'Kotohori',
      theme: buildTheme(Brightness.light, snackWidth: snackWidth),
      darkTheme: buildTheme(Brightness.dark, snackWidth: snackWidth),
      themeMode: ref.watch(themeModeProvider),
      home: const AppShell(),
    );
  }
}
