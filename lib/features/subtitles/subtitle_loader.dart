import 'dart:convert';

import 'package:charset/charset.dart';

import 'ass_parser.dart';
import 'cue.dart';
import 'srt_parser.dart';
import 'vtt_parser.dart';

/// UTF-8 (with/without BOM) and UTF-16 (BOM) first; anything that isn't valid
/// UTF-8 is treated as Shift-JIS, the usual legacy encoding for Japanese subs.
// shortcut: EUC-JP is not detected; add a check here if such files show up.
String decodeSubtitleBytes(List<int> bytes) {
  if (bytes.length >= 2 &&
      ((bytes[0] == 0xff && bytes[1] == 0xfe) ||
          (bytes[0] == 0xfe && bytes[1] == 0xff))) {
    return utf16.decode(bytes).replaceFirst('﻿', '');
  }
  try {
    return utf8.decode(bytes).replaceFirst('﻿', '');
  } on FormatException {
    return shiftJis.decode(bytes);
  }
}

/// Parses by extension, falling back to sniffing the content.
/// Throws [FormatException] if no cues are found.
List<Cue> parseSubtitleFile(List<int> bytes, String fileName) {
  final text = decodeSubtitleBytes(bytes);
  final ext = fileName.toLowerCase().split('.').last;
  final cues = switch (ext) {
    'ass' || 'ssa' => parseAss(text),
    'vtt' => parseVtt(text),
    'srt' => parseSrt(text),
    _ when text.contains('[Events]') => parseAss(text),
    _ when text.trimLeft().startsWith('WEBVTT') => parseVtt(text),
    _ => parseSrt(text),
  };
  if (cues.isEmpty) throw FormatException('No subtitles found in $fileName');
  return cues;
}
