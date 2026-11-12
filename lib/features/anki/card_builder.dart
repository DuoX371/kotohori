import 'dart:convert';

import 'anki_settings.dart';

/// Sentence HTML with the looked-up span in bold; line breaks become `<br>`.
String boldSentence(String text, int start, int length) {
  const esc = HtmlEscape(HtmlEscapeMode.element);
  String e(String s) => esc.convert(s).replaceAll('\n', '<br>');
  final s = start.clamp(0, text.length);
  final end = (start + length).clamp(s, text.length);
  if (end == s) return e(text);
  return '${e(text.substring(0, s))}<b>${e(text.substring(s, end))}</b>${e(text.substring(end))}';
}

/// "12:34" (or "1:02:03").
String clock(Duration at) {
  final h = at.inHours, m = at.inMinutes % 60, s = at.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${h > 0 ? '$h:${two(m)}' : two(m)}:${two(s)}';
}

/// Time range for the sentence-audio clip: the cue (shifted by the subtitle
/// offset) plus padding, never before 0.
(Duration, Duration) audioRange(
  Duration cueStart,
  Duration cueEnd,
  Duration offset,
  int padBeforeMs,
  int padAfterMs,
) {
  var start = cueStart + offset - Duration(milliseconds: padBeforeMs);
  if (start < Duration.zero) start = Duration.zero;
  final end = cueEnd + offset + Duration(milliseconds: padAfterMs);
  return (start, end);
}

/// Guesses what each note-type field should hold from its name.
/// Users can change every guess in Settings → Anki.
Map<String, CardSource> guessFieldMap(List<String> fields) => {
  for (final f in fields) f: _guess(f.toLowerCase()),
};

CardSource _guess(String f) {
  bool has(List<String> words) => words.any(f.contains);
  if (has(['audio', 'sound', '音声'])) {
    return has(['sent', '例文', '文']) ? CardSource.audio : CardSource.wordAudio;
  }
  if (has(['image', 'picture', 'screenshot', 'pic', 'photo', '画像'])) {
    return CardSource.image;
  }
  if (has(['sent', '例文', '文章'])) {
    return has(['furigana', 'reading', 'kana'])
        ? CardSource.none
        : CardSource.sentence;
  }
  if (has(['reading', 'kana', 'furigana', 'pronunciation', '読み'])) {
    return CardSource.reading;
  }
  if (has(['definition', 'meaning', 'gloss', 'english', 'back', '意味'])) {
    return CardSource.definition;
  }
  if (has(['word', 'expression', 'vocab', 'term', 'kanji', 'front', '単語'])) {
    return CardSource.word;
  }
  if (has(['source', '出典'])) return CardSource.source;
  return CardSource.none;
}

/// Values for one note, in the note type's field order. Fields mapped to a
/// source with no value (e.g. audio turned off) are left empty.
List<String> noteFields(
  List<String> modelFields,
  Map<String, CardSource> fieldMap,
  Map<CardSource, String> values,
) => [
  for (final f in modelFields) values[fieldMap[f] ?? CardSource.none] ?? '',
];

/// Escapes text for Anki's search syntax inside double quotes (duplicate check).
String ankiSearchEscape(String s) =>
    s.replaceAllMapped(RegExp(r'["*_\\:]'), (m) => '\\${m[0]}');
