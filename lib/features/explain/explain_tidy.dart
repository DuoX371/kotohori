// Clean-up of the model's answer before it is shown. The prompt asks for all
// of this already, but the lighter models don't reliably follow it.

// "- **word** (reading): rest" (ASCII or full-width brackets and colon). The
// reading's closing bracket may be missing: the line is still being written.
final _bullet = RegExp(
  r'^(\s*[-*•]\s+\*\*)(.+?)(\*\*)\s*(?:[（(]([^)）]*)(?:[)）]|$))?(\s*[:：]?.*)$',
);
// A bullet whose bold word isn't finished yet: "- **引っ剥".
final _startedBullet = RegExp(r'^\s*[-*•]\s*(\*{1,2}[^*]*\*?)?$');
final _kanji = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF々〆]');
final _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Particles every learner knows; a bullet for one alone is noise.
const _basicParticles = {'が', 'を', 'に', 'は', 'の', 'で', 'と', 'も', 'へ'};

/// [markdown] without the Breakdown bullets that only restate the obvious:
/// - bullets for punctuation or for a lone basic particle are dropped;
/// - a "(reading)" after a word with no kanji is removed.
/// Works on a half-written answer too: a bullet is held back until enough of
/// it has arrived to decide, so nothing appears and then vanishes.
String tidyExplanation(String markdown) {
  final out = <String>[];
  final lines = markdown.split('\n');
  for (final (i, line) in lines.indexed) {
    final last = i == lines.length - 1;
    if (last && _startedBullet.hasMatch(line)) continue; // too early to tell
    final m = _bullet.firstMatch(line);
    if (m == null) {
      out.add(line);
      continue;
    }
    final word = m.group(2)!.trim();
    if (!_wordCharacter.hasMatch(word)) continue; // 、 。 ！ …
    if (_basicParticles.contains(word)) continue;
    final reading = m.group(4);
    final keepReading = reading != null && _kanji.hasMatch(word);
    out.add(
      '${m.group(1)}$word${m.group(3)}'
      '${keepReading ? ' ($reading)' : ''}${m.group(5)}',
    );
  }
  return out.join('\n');
}
