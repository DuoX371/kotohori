import 'cue.dart';

final _timing = RegExp(
  r'(\d+):(\d{1,2}):(\d{1,2})[,.](\d{1,3})\s*-->\s*(\d+):(\d{1,2}):(\d{1,2})[,.](\d{1,3})',
);

/// SubRip. Strips HTML-ish tags (`<i>`, `<font …>`) and ASS-style `{\an8}` tags.
List<Cue> parseSrt(String text) {
  final cues = <Cue>[];
  final blocks = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final lines = block.trim().split('\n');
    final t = lines.indexWhere(_timing.hasMatch);
    if (t < 0) continue;
    final m = _timing.firstMatch(lines[t])!;
    final body = lines
        .skip(t + 1)
        .join('\n')
        .replaceAll(RegExp(r'<[^>]*>|\{\\[^}]*\}'), '')
        .trim();
    cues.add(Cue(0, _time(m, 1), _time(m, 5), body));
  }
  return normalizeCues(cues);
}

Duration _time(RegExpMatch m, int g) => Duration(
  hours: int.parse(m[g]!),
  minutes: int.parse(m[g + 1]!),
  seconds: int.parse(m[g + 2]!),
  milliseconds: int.parse(m[g + 3]!.padRight(3, '0')),
);
