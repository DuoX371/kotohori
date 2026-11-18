// Numbers for the book details sheet.

/// "3 h 20 min", "46 min", "< 1 min".
String durationLabel(Duration d) {
  final minutes = (d.inSeconds / 60).round();
  if (minutes < 1) return '< 1 min';
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

/// Characters before chapter [chapter] plus [offset] into it.
int charsRead(List<int> lengths, {required int chapter, required int offset}) {
  var read = 0;
  for (var i = 0; i < lengths.length && i < chapter; i++) {
    read += lengths[i];
  }
  if (chapter < lengths.length) read += offset.clamp(0, lengths[chapter]);
  return read;
}

/// Reading speed after a session: mostly the old value, so one odd session
/// (a hard chapter, lots of lookups) doesn't swing it.
int blendPace(int? old, int session) =>
    old == null ? session : (old * 0.7 + session * 0.3).round();

/// A learner's typical speed in characters a minute, until we know theirs.
const typicalPace = 300;

/// 98000 → "98,000".
String grouped(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
