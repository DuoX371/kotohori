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
      // Ends shift by the same tolerance as starts, so a line ending exactly
      // when the next starts hides as the next appears (no stacked flash).
      if (startOf(c) <= pos + tolerance && pos + tolerance < endOf(c)) c,
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

  /// How far inside a line a card's picture is taken when the video is not
  /// on that line any more (or not yet): clear of the cut at either edge.
  static const frameMargin = Duration(milliseconds: 250);

  /// Where to take the picture for a card about [cue] while the video is at
  /// [pos]. Null: [pos] is on the line, so the frame on screen is right.
  /// Otherwise a moment inside the line: near its end when the video has
  /// moved past it, near its start when the video hasn't reached it.
  Duration? cardFrameTime(Cue cue, Duration pos) {
    final start = startOf(cue), end = endOf(cue);
    if (start <= pos + tolerance && pos < end) return null;
    final half = (end - start) ~/ 2;
    final margin = half < frameMargin ? half : frameMargin;
    final at = pos >= end ? end - margin : start + margin;
    return at < Duration.zero ? Duration.zero : at;
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
