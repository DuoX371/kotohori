import 'cue.dart';

final _time = RegExp(r'^(\d+):(\d{1,2}):(\d{1,2})[.:](\d{1,3})$');
final _override = RegExp(r'\{[^}]*\}');
final _drawing = RegExp(r'\\p(\d+)');

/// ASS / SSA. Uses the [Events] `Format:` line to find Start/End/Text,
/// reads only `Dialogue:` lines (Comment events are ignored), strips
/// override tags and drops vector-drawing text (between {\p1} and {\p0}).
List<Cue> parseAss(String text) {
  final cues = <Cue>[];
  var inEvents = false;
  List<String>? format;
  for (final raw
      in text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
    final line = raw.trim();
    if (line.startsWith('[')) {
      inEvents = line.toLowerCase() == '[events]';
      continue;
    }
    if (!inEvents) continue;
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final key = line.substring(0, colon).trim();
    final value = line.substring(colon + 1).trimLeft();
    if (key == 'Format') {
      format = value.split(',').map((f) => f.trim().toLowerCase()).toList();
    } else if (key == 'Dialogue' && format != null) {
      final fields = _splitFields(value, format.length);
      if (fields.length != format.length) continue;
      final start = _parseTime(fields[format.indexOf('start')]);
      final end = _parseTime(fields[format.indexOf('end')]);
      final textIdx = format.indexOf('text');
      if (start == null || end == null || textIdx < 0) continue;
      cues.add(Cue(0, start, end, cleanAssText(fields[textIdx])));
    }
  }
  return normalizeCues(cues);
}

/// Splits on commas; the last field (Text) keeps any commas it contains.
List<String> _splitFields(String s, int count) {
  final out = <String>[];
  var rest = s;
  while (out.length < count - 1) {
    final i = rest.indexOf(',');
    if (i < 0) break;
    out.add(rest.substring(0, i).trim());
    rest = rest.substring(i + 1);
  }
  out.add(rest);
  return out;
}

Duration? _parseTime(String s) {
  final m = _time.firstMatch(s.trim());
  if (m == null) return null;
  final frac = m[4]!;
  return Duration(
    hours: int.parse(m[1]!),
    minutes: int.parse(m[2]!),
    seconds: int.parse(m[3]!),
    milliseconds: frac.length == 2
        ? int.parse(frac) * 10
        : int.parse(frac.padRight(3, '0')),
  );
}

String cleanAssText(String s) {
  final out = StringBuffer();
  var drawing = false;
  var last = 0;
  for (final m in _override.allMatches(s)) {
    if (!drawing) out.write(s.substring(last, m.start));
    final p = _drawing.allMatches(m[0]!).lastOrNull;
    if (p != null) drawing = int.parse(p[1]!) > 0;
    last = m.end;
  }
  if (!drawing) out.write(s.substring(last));
  return out
      .toString()
      .replaceAll(RegExp(r'\\[Nn]'), '\n')
      .replaceAll(r'\h', ' ')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .join('\n');
}
