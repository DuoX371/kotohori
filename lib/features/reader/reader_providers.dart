import 'dart:io';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../anki/anki_providers.dart' show cardExporterProvider;
import '../anki/anki_settings.dart' show ankiSettingsProvider;
import '../dictionary/ui/providers.dart' show appPathsProvider, prefsProvider;
import 'book_repo.dart';
import 'book_stats.dart' show blendPace;
import 'book_view.dart' show loadEpubDetails;
import 'epub.dart' show EpubDetails;
import 'library_db.dart';
import 'reader_fonts.dart';

/// A book's details from its stored copy, for the details sheet.
final bookDetailsProvider = FutureProvider.family<EpubDetails, String>(
  (ref, hash) => loadEpubDetails(ref.watch(bookRepoProvider).epubPath(hash)),
);

// Overridden in main().
final libraryDbProvider = Provider<LibraryDb>(
  (_) => throw UnimplementedError(),
);

final bookRepoProvider = Provider(
  (ref) => BookRepo(
    ref.watch(libraryDbProvider),
    booksDir: ref.watch(appPathsProvider).booksDir,
  ),
);

/// The shelf, most recently read first.
final booksProvider = StreamProvider<List<Book>>(
  (ref) => ref.watch(bookRepoProvider).watchAll(),
);

/// The reader's fonts, next to the books in the app's storage.
final readerFontsProvider = Provider(
  (ref) => ReaderFonts(
    p.join(p.dirname(ref.watch(appPathsProvider).booksDir), 'fonts'),
  ),
);

/// Names of the fonts the user added, A–Z.
class AddedFonts extends Notifier<List<String>> {
  @override
  List<String> build() => ref.watch(readerFontsProvider).list();

  Future<String> add(String path) async {
    final name = await ref.read(readerFontsProvider).add(path);
    state = ref.read(readerFontsProvider).list();
    return name;
  }

  Future<void> remove(String name) async {
    await ref.read(readerFontsProvider).remove(name);
    state = ref.read(readerFontsProvider).list();
  }
}

final addedFontsProvider = NotifierProvider<AddedFonts, List<String>>(
  AddedFonts.new,
);

/// An added font loaded into the app, so its chip can show what it looks
/// like. Null if Flutter can't read it (e.g. .woff/.woff2: the page still can).
final addedFontFamilyProvider = FutureProvider.family<String?, String>((
  ref,
  name,
) async {
  final file = File(ref.watch(readerFontsProvider).path(name));
  if (!file.existsSync()) return null;
  final family = 'KhAdded $name';
  try {
    final bytes = await file.readAsBytes();
    await (FontLoader(
      family,
    )..addFont(Future.value(bytes.buffer.asByteData()))).load();
    return family;
  } on Object {
    return null;
  }
});

/// The reader's speed in characters a minute, learnt from reading sessions
/// (null until the first long enough one). Global, like the reader settings.
class ReaderPace extends Notifier<int?> {
  // .cpm: a first test run under the old name learnt from a bot's swipes.
  static const key = 'reader.pace.cpm';

  @override
  int? build() => ref.watch(prefsProvider).getInt(key);

  Future<void> learn(int sessionPace) async {
    state = blendPace(state, sessionPace);
    await ref.read(prefsProvider).setInt(key, state!);
  }
}

final readerPaceProvider = NotifierProvider<ReaderPace, int?>(ReaderPace.new);

/// Cards mined from the book [title] (by their Source field); null when
/// AnkiDroid can't be asked.
final cardsMinedProvider = FutureProvider.family<int?, String>(
  (ref, title) => ref
      .read(cardExporterProvider)
      .cardsFrom(title, ref.read(ankiSettingsProvider)),
);
