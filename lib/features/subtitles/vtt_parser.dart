import 'cue.dart';

final _timing = RegExp(
  r'(?:(\d+):)?(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(?:(\d+):)?(\d{2}):(\d{2})\.(\d{3})',
);

/// WebVTT. Skips NOTE/STYLE/REGION blocks; strips tags (`<c.x>`, `<i>`, `<00:01.000>`)
/// and decodes the common entities.
List<Cue> parseVtt(String text) {
  final cues = <Cue>[];
  final blocks = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split(RegExp(r'\n\s*\n'));
  for (final block in blocks) {
    final lines = block.trim().split('\n');
    final t = lines.indexWhere(_timing.hasMatch);
    if (t < 0 || t > 1) continue; // header, NOTE, STYLE, REGION blocks have no timing line up front
    final m = _timing.firstMatch(lines[t])!;
    final body = _entities(
      lines.skip(t + 1).join('\n').replaceAll(RegExp(r'<[^>]*>'), ''),
    ).trim();
    cues.add(Cue(0, _time(m, 1), _time(m, 5), body));
  }
  return normalizeCues(cues);
}

Duration _time(RegExpMatch m, int g) => Duration(
  hours: int.parse(m[g] ?? '0'),
  minutes: int.parse(m[g + 1]!),
  seconds: int.parse(m[g + 2]!),
  milliseconds: int.parse(m[g + 3]!),
);

String _entities(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lrm;', '')
    .replaceAll('&rlm;', '')
    .replaceAll('&amp;', '&');
