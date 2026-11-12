import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/services.dart' show PlatformException;
import 'package:path/path.dart' as p;

import '../../platform/anki_bridge.dart';
import '../../platform/media_tools.dart';
import 'anki_settings.dart';
import 'card_builder.dart';
import 'screenshot.dart';
import 'word_audio.dart';

/// Everything shown in the card editor. Text fields are editable there and
/// available at once; media arrives as it is made (listen for changes).
class CardDraft extends ChangeNotifier {
  CardDraft({
    required this.sentence,
    required this.word,
    required this.reading,
    required this.definition,
    required this.source,
    this.imagePath,
    this.audioPath,
    this.wordAudioPath,
    List<String>? mediaWarnings,
  }) : mediaWarnings = mediaWarnings ?? [];

  String sentence;
  String word;
  String reading;
  String definition;
  String source;
  String? imagePath;
  String? audioPath;
  String? wordAudioPath;

  /// Decks of the word's existing cards when the editor opened (null: none).
  /// The editor says so and adds without asking again.
  List<String>? existingDecks;
  bool get alreadyInAnki => existingDecks != null;

  /// Media still being made (shown as placeholders in the editor).
  bool imagePending = false, audioPending = false, wordAudioPending = false;

  /// Completes when every media item has finished (or failed).
  Future<void> mediaReady = Future.value();

  /// e.g. "Screenshot unavailable" — shown in the editor, card can still be sent.
  final List<String> mediaWarnings;

  Map<CardSource, String> get textValues => {
    CardSource.sentence: sentence,
    CardSource.word: word,
    CardSource.reading: reading,
    CardSource.definition: definition,
    CardSource.source: source,
  };

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  var _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class DuplicateNoteException implements Exception {
  DuplicateNoteException(this.word);
  final String word;
}

class CardExporter {
  CardExporter({
    required this.anki,
    required this.media,
    required this.tempDir,
    required this.dio,
  });
  final AnkiBridge anki;
  final Dio dio;
  final MediaTools media;
  final String tempDir;

  String get _mediaDir =>
      p.join(tempDir, 'anki_media'); // shared via FileProvider (file_paths.xml)

  /// Returns the draft at once with its text; screenshot, sentence audio and
  /// word audio are made in parallel and filled in as each finishes. Media
  /// failures don't block the card: they become warnings, the field stays empty.
  /// [screenshot] is called immediately, so the frame is the one on screen now.
  CardDraft prepare({
    required AnkiSettings settings,
    required String cueText,
    required int matchStart,
    required int matchLength,
    required Duration cueStart,
    required Duration cueEnd,
    required Duration subtitleOffset,
    required String word,
    required String reading,
    required String definitionHtml,
    required String videoTitle,
    required String videoSource,
    required Future<Uint8List?> Function() screenshot,
  }) {
    final d = CardDraft(
      sentence: boldSentence(cueText, matchStart, matchLength),
      word: word,
      reading: reading,
      definition: definitionHtml,
      source: videoTitle,
    );
    Future<void> image() async {
      d.imagePending = true;
      try {
        final frame = await screenshot();
        if (frame == null) throw StateError('no frame');
        d.imagePath = await saveScreenshot(frame, settings, cueText);
      } catch (_) {
        d.mediaWarnings.add('Screenshot unavailable for this video');
      }
      d.imagePending = false;
      d._changed();
    }

    Future<void> sentenceAudio() async {
      d.audioPending = true;
      try {
        final (start, end) = audioRange(
          cueStart,
          cueEnd,
          subtitleOffset,
          settings.paddingBeforeMs,
          settings.paddingAfterMs,
        );
        d.audioPath = await saveAudio(videoSource, start, end);
      } catch (e) {
        d.mediaWarnings.add(
          'Sentence audio unavailable: ${e is PlatformException ? e.message : e}',
        );
      }
      d.audioPending = false;
      d._changed();
    }

    Future<void> wordAudio() async {
      d.wordAudioPending = true;
      try {
        d.wordAudioPath = await saveWordAudio(word, reading);
        if (d.wordAudioPath == null) {
          d.mediaWarnings.add('No word audio for $word on JapanesePod101');
        }
      } catch (_) {
        d.mediaWarnings.add(
          'Word audio unavailable: no connection to JapanesePod101',
        );
      }
      d.wordAudioPending = false;
      d._changed();
    }

    d.mediaReady = Future.wait([
      if (settings.includeScreenshot) image(),
      if (settings.includeAudio) sentenceAudio(),
      if (settings.includeWordAudio) wordAudio(),
    ]);
    return d;
  }

  /// Writes the screenshot JPEG; returns its path.
  Future<String> saveScreenshot(
    Uint8List frame,
    AnkiSettings s,
    String? subtitle,
  ) async {
    final shot = await composeScreenshot(
      frame,
      maxWidth: s.fullSizeScreenshot ? null : 640,
      subtitle: s.subtitleInScreenshot ? subtitle : null,
    );
    final path = _newFile('jpg');
    await media.encodeJpeg(
      shot.rgba,
      width: shot.width,
      height: shot.height,
      outPath: path,
    );
    return path;
  }

  Future<String> saveAudio(
    String videoSource,
    Duration start,
    Duration end,
  ) async {
    final path = _newFile('m4a');
    await media.clipAudio(
      source: videoSource,
      start: start,
      end: end,
      outPath: path,
    );
    return path;
  }

  /// Downloads the word's JapanesePod101 recording; null if it has none.
  Future<String?> saveWordAudio(String word, String reading) async {
    final res = await dio.getUri<List<int>>(
      jpodAudioUrl(word, reading),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    if (bytes.isEmpty || isJpodMissingClip(bytes)) return null;
    final mp3 = File(_newFile('mp3'));
    await mp3.writeAsBytes(bytes, flush: true);
    // The recordings stop right at the last sound; players that start/stop
    // audio output slowly clip that. Re-encode with a little trailing silence.
    final path = _newFile('m4a');
    try {
      await media.clipAudio(
        source: mp3.path,
        start: Duration.zero,
        end: const Duration(minutes: 1),
        outPath: path,
        padEnd: const Duration(milliseconds: 400),
      );
      return path;
    } catch (_) {
      return mp3.path; // unpadded is still better than nothing
    } finally {
      if (File(path).existsSync()) mp3.deleteSync();
    }
  }

  String _newFile(String ext) {
    Directory(_mediaDir).createSync(recursive: true);
    return p.join(
      _mediaDir,
      'kotohori_${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
  }

  /// Checks AnkiDroid, asks for permission if needed, checks duplicates
  /// (unless [allowDuplicate]), uploads media and adds the note.
  Future<void> send(
    CardDraft d,
    AnkiSettings s, {
    bool allowDuplicate = false,
  }) async {
    await d
        .mediaReady; // Add pressed before the media was ready: finish it first
    final status = await anki.status();
    if (!status.installed) throw AnkiException('AnkiDroid is not installed');
    if (!status.permission && !await anki.requestPermission()) {
      throw AnkiException(
        'Kotohori needs permission to add cards to AnkiDroid',
        isPermission: true,
      );
    }
    final model = (await anki.models())
        .where((m) => m.id == s.modelId)
        .firstOrNull;
    if (model == null || s.deckId == null) {
      throw AnkiException('Choose a deck and note type in Settings → Anki');
    }

    final search = duplicateSearch(model, s, d.word);
    if (!allowDuplicate &&
        search != null &&
        await anki.countNotes(search) > 0) {
      throw DuplicateNoteException(d.word);
    }

    final values = d.textValues;
    final used = s.fieldMap.values.toSet();
    if (d.imagePath != null && used.contains(CardSource.image)) {
      values[CardSource.image] = await anki.addMedia(
        d.imagePath!,
        name: 'kotohori_image',
        isAudio: false,
      );
    }
    if (d.wordAudioPath != null && used.contains(CardSource.wordAudio)) {
      values[CardSource.wordAudio] = await anki.addMedia(
        d.wordAudioPath!,
        name: 'kotohori_word',
        isAudio: true,
      );
    }
    if (d.audioPath != null && used.contains(CardSource.audio)) {
      values[CardSource.audio] = await anki.addMedia(
        d.audioPath!,
        name: 'kotohori_audio',
        isAudio: true,
      );
    }
    await anki.addNote(
      modelId: model.id,
      deckId: s.deckId!,
      fields: noteFields(model.fields, s.fieldMap, values),
      tags: const ['kotohori'],
    );
  }

  /// Anki search for notes of [model] whose Word field is [word]; null when no
  /// field holds the word (then duplicates can't be told apart).
  static String? duplicateSearch(AnkiModel model, AnkiSettings s, String word) {
    final wordField = s.fieldMap.entries
        .where((e) => e.value == CardSource.word)
        .firstOrNull
        ?.key;
    if (wordField == null ||
        word.isEmpty ||
        !model.fields.contains(wordField)) {
      return null;
    }
    return '"note:${ankiSearchEscape(model.name)}" "${ankiSearchEscape(wordField)}:${ankiSearchEscape(word)}"';
  }

  /// Words that already have a card (same check as [send]) → the decks those
  /// cards are in. Read-only and silent: never asks for permission; on any
  /// problem it reports nothing.
  Future<Map<String, List<String>>> wordsInAnki(
    Iterable<String> words,
    AnkiSettings s,
  ) async {
    try {
      final status = await anki.status();
      if (!status.installed || !status.permission || s.modelId == null) {
        return {};
      }
      final model = (await anki.models())
          .where((m) => m.id == s.modelId)
          .firstOrNull;
      if (model == null) return {};
      final found = <String, List<String>>{};
      for (final w in words.toSet()) {
        final search = duplicateSearch(model, s, w);
        if (search == null) continue;
        final decks = await anki.noteDecks(search);
        if (decks.isNotEmpty) found[w] = decks;
      }
      return found;
    } on AnkiException {
      return {};
    }
  }

  /// Removes temporary media files of a finished or cancelled card.
  /// Waits for media still being made, so nothing is left behind.
  Future<void> discard(CardDraft d) async {
    await d.mediaReady;
    for (final path in [d.imagePath, d.audioPath, d.wordAudioPath]) {
      if (path == null) continue;
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  }
}
