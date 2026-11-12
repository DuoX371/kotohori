import 'cue.dart';

/// Cue lookups against a playback position, with a global [offset]
/// (positive = subtitles appear later).
class SubtitleTimeline {
  SubtitleTimeline(this.cues, {this.offset = Duration.zero});

  /// Sorted by start (see [normalizeCues]). Replaced when auto sync re-times them.
  List<Cue> cues;
  Duration offset;

  /// Seeking to a cue start lands on the previous video frame (up to ~42 ms
  /// at 24 fps), so positions this close before a start count as started.
  static const tolerance = Duration(milliseconds: 100);

  Duration startOf(Cue c) => c.start + offset;
  Duration endOf(Cue c) => c.end + offset;

  /// Every cue showing at [pos] (ASS can overlap), in start order.
  List<Cue> activeAt(Duration pos) => [
    for (final c in cues)
      if (startOf(c) <= pos + tolerance && pos < endOf(c)) c,
  ];

  /// The last cue that has started by [pos]: the one "replay" and the cue
  /// list treat as current, even in a gap between lines.
  Cue? currentAt(Duration pos) {
    final i = _lastStartedIndex(pos);
    return i < 0 ? null : cues[i];
  }

  Cue? nextAfter(Duration pos) {
    final i = _lastStartedIndex(pos) + 1;
    return i < cues.length ? cues[i] : null;
  }

  /// The cue before the current one (or the current one if it's the first).
  Cue? previousBefore(Duration pos) {
    final i = _lastStartedIndex(pos);
    if (i < 0) return null;
    return cues[i > 0 ? i - 1 : 0];
  }

  /// Offset that makes [cue] start exactly at [pos] ("this line starts now").
  Duration offsetToStart(Cue cue, Duration pos) => pos - cue.start;

  // Binary search: index of the last cue with startOf <= pos, or -1.
  int _lastStartedIndex(Duration pos) {
    var lo = 0, hi = cues.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (startOf(cues[mid]) <= pos + tolerance) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}
