import 'dart:convert';

import '../ass_parser.dart' show cleanAssText;
import '../cue.dart';
import 'mkv_reader.dart';

/// Lines without a stored duration (rare) stay up until the next one, at most this long.
const _defaultDuration = Duration(seconds: 4);

/// Turns a text track's blocks into cues.
/// ASS/SSA blocks hold the Dialogue fields after Start/End:
/// `ReadOrder,Layer,Style,Name,MarginL,MarginR,MarginV,Effect,Text`.
List<Cue> mkvTrackCues(MkvTrack track, List<MkvBlock> blocks) {
  final ass = track.codec == 'S_TEXT/ASS' || track.codec == 'S_TEXT/SSA';
  final cues = <Cue>[];
  for (final (i, b) in blocks.indexed) {
    final raw = utf8.decode(b.data, allowMalformed: true);
    final text = ass
        ? cleanAssText(_afterCommas(raw, 8))
        : raw
              .replaceAll(RegExp(r'<[^>]*>|\{\\[^}]*\}'), '')
              .replaceAll('\r\n', '\n')
              .trim();
    final next = i + 1 < blocks.length ? blocks[i + 1].start : null;
    var end = b.start + (b.duration ?? _defaultDuration);
    if (b.duration == null && next != null && next > b.start && next < end) {
      end = next;
    }
    cues.add(Cue(0, b.start, end, text));
  }
  return normalizeCues(cues);
}

String _afterCommas(String s, int n) {
  var i = -1;
  for (var k = 0; k < n; k++) {
    i = s.indexOf(',', i + 1);
    if (i < 0) return s;
  }
  return s.substring(i + 1);
}

/// Two-letter language code from either tag style: `eng`/`en`/`en-US` → `en`, `jpn` → `ja`.
String mkvLanguageCode(MkvTrack t) {
  final primary = (t.language ?? 'und').toLowerCase().split('-').first;
  return _threeToTwo[primary] ?? primary;
}

/// "English (CR)", "Japanese", "Spanish (Latin America CR)": what a person picks from.
String mkvTrackLabel(MkvTrack t) {
  final tag = t.language?.toLowerCase();
  final lang =
      _languages[tag] ??
      _languages[mkvLanguageCode(t)] ??
      t.language ??
      'Unknown language';
  final name = t.name?.replaceAll('_', ' ').trim();
  return name == null || name.isEmpty ? lang : '$lang ($name)';
}

const _languages = {
  'jpn': 'Japanese', 'ja': 'Japanese', 'eng': 'English', 'en': 'English', //
  'por': 'Portuguese',
  'pt': 'Portuguese',
  'pt-br': 'Portuguese (Brazil)',
  'spa': 'Spanish',
  'es': 'Spanish',
  'es-419': 'Spanish (Latin America)',
  'fre': 'French',
  'fra': 'French',
  'fr': 'French',
  'ger': 'German',
  'deu': 'German',
  'de': 'German',
  'ita': 'Italian',
  'it': 'Italian',
  'rus': 'Russian', 'ru': 'Russian', 'ara': 'Arabic', 'ar': 'Arabic',
  'chi': 'Chinese',
  'zho': 'Chinese',
  'zh': 'Chinese',
  'kor': 'Korean',
  'ko': 'Korean',
  'und': 'Unknown language',
};

const _threeToTwo = {
  'jpn': 'ja',
  'eng': 'en',
  'por': 'pt',
  'spa': 'es',
  'fre': 'fr',
  'fra': 'fr',
  'ger': 'de',
  'deu': 'de',
  'ita': 'it',
  'rus': 'ru',
  'ara': 'ar',
  'chi': 'zh',
  'zho': 'zh',
  'kor': 'ko',
};
