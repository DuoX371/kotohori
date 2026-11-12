class Cue {
  const Cue(this.index, this.start, this.end, this.text);
  final int index;
  final Duration start;
  final Duration end;

  /// Plain text; lines separated by '\n'.
  final String text;

  @override
  String toString() => 'Cue($index, $start–$end, $text)';
}

/// Sorts by start, drops empty/duplicate cues (ASS often repeats a line on
/// several layers for outlines), and renumbers from 0.
List<Cue> normalizeCues(Iterable<Cue> cues) {
  final seen = <(Duration, Duration, String)>{};
  final list =
      cues
          .where(
            (c) =>
                c.text.trim().isNotEmpty &&
                c.end > c.start &&
                seen.add((c.start, c.end, c.text)),
          )
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  return [for (final (i, c) in list.indexed) Cue(i, c.start, c.end, c.text)];
}
