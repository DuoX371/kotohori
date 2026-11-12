import 'dart:isolate';
import 'dart:typed_data';

import 'cue.dart';

/// From the target line starting at [from] (its original time) onward, shift by [shift].
class SyncSegment {
  const SyncSegment(this.from, this.shift);
  final Duration from;
  final Duration shift;

  List<int> toJson() => [from.inMilliseconds, shift.inMilliseconds];
  static SyncSegment fromJson(List<dynamic> j) => SyncSegment(
    Duration(milliseconds: (j[0] as num).toInt()),
    Duration(milliseconds: (j[1] as num).toInt()),
  );

  @override
  bool operator ==(Object other) =>
      other is SyncSegment && other.from == from && other.shift == shift;
  @override
  int get hashCode => Object.hash(from, shift);
  @override
  String toString() => 'SyncSegment($from, $shift)';
}

class AutoSyncResult {
  const AutoSyncResult(this.segments, this.matched);

  /// In time order; the first one starts at the first line.
  final List<SyncSegment> segments;

  /// Share of line starts/ends that landed on a reference start/end (0–1).
  final double matched;
}

/// [autoSync] on a background isolate. Top-level on purpose: a closure written
/// inside a widget would capture the widget's state, which can't be sent.
Future<AutoSyncResult?> autoSyncInBackground(
  List<Cue> target,
  List<Cue> reference,
) => Isolate.run(() => autoSync(target, reference));

/// Shifts every cue by its segment's shift.
List<Cue> applySync(List<Cue> cues, List<SyncSegment> segments) {
  if (segments.isEmpty) return cues;
  Duration shiftFor(Duration start) {
    var s = segments.first.shift;
    for (final seg in segments) {
      if (start >= seg.from) s = seg.shift;
    }
    return s;
  }

  return normalizeCues([
    for (final c in cues)
      Cue(
        c.index,
        c.start + shiftFor(c.start),
        c.end + shiftFor(c.start),
        c.text,
      ),
  ]);
}

/// Lines up [target] subtitles with [reference] subtitles of the same video
/// (any language: only the timing is compared).
///
/// Each target line start/end scores a point when it lands within 400 ms of a
/// reference line start/end. Every line gets one of the likely shifts; changing
/// shift between lines costs [splitCost] points, so the result only splits where
/// the releases really differ (e.g. a TV version with an extra sponsor card).
/// Returns null when nothing lines up convincingly.
AutoSyncResult? autoSync(
  List<Cue> target,
  List<Cue> reference, {
  Duration maxShift = const Duration(minutes: 10),
  int splitCost = 8,
}) {
  if (target.length < 5 || reference.length < 5) return null;
  const binMs = 50, tolMs = 400;
  final maxMs = maxShift.inMilliseconds;
  final refEdges = Int32List.fromList(
    [
      for (final c in reference) ...[
        c.start.inMilliseconds,
        c.end.inMilliseconds,
      ],
    ]..sort(),
  );
  bool near(int t, int tol) {
    var lo = 0, hi = refEdges.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (refEdges[mid] < t - tol) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo < refEdges.length && refEdges[lo] <= t + tol;
  }

  // 1. Likely shifts: vote for every (reference edge − target edge) difference.
  final bins = maxMs * 2 ~/ binMs + 1;
  final votes = Int32List(bins);
  for (final c in target) {
    for (final t in [c.start.inMilliseconds, c.end.inMilliseconds]) {
      var lo = 0, hi = refEdges.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (refEdges[mid] < t - maxMs) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      for (var i = lo; i < refEdges.length && refEdges[i] <= t + maxMs; i++) {
        votes[(refEdges[i] - t + maxMs) ~/ binMs]++;
      }
    }
  }
  // Votes within the tolerance count together; keep the 40 best separated peaks.
  const w = tolMs ~/ binMs;
  final smooth = Int32List(bins);
  var run = 0;
  for (var i = 0; i < bins + w; i++) {
    if (i < bins) run += votes[i];
    if (i - 2 * w - 1 >= 0) run -= votes[i - 2 * w - 1];
    if (i - w >= 0 && i - w < bins) smooth[i - w] = run;
  }
  final order = List<int>.generate(bins, (i) => i)
    ..sort((a, b) => smooth[b] - smooth[a]);
  final peaks = <int>[];
  for (final i in order) {
    if (peaks.length == 40 || smooth[i] == 0) break;
    if (peaks.every((p) => (p - i).abs() > 2 * w)) peaks.add(i);
  }
  final candidates = <int>{
    for (final p in peaks)
      for (var d = -w; d <= w; d++)
        if (p + d >= 0 && p + d < bins) (p + d) * binMs - maxMs,
  }.toList();
  if (candidates.isEmpty) return null;

  // 2. Best shift per line, with a cost for switching (dynamic programming).
  final n = target.length, k = candidates.length;
  var prev = Float64List(k);
  final back = List<Int32List>.generate(n, (_) => Int32List(k));
  for (var i = 0; i < n; i++) {
    final s = target[i].start.inMilliseconds, e = target[i].end.inMilliseconds;
    var best = 0;
    for (var j = 1; j < k; j++) {
      if (prev[j] > prev[best]) best = j;
    }
    final jump = prev[best] - splitCost;
    final cur = Float64List(k);
    for (var j = 0; j < k; j++) {
      final o = candidates[j];
      final score = (near(s + o, tolMs) ? 1 : 0) + (near(e + o, tolMs) ? 1 : 0);
      if (prev[j] >= jump) {
        cur[j] = prev[j] + score;
        back[i][j] = j;
      } else {
        cur[j] = jump + score;
        back[i][j] = best;
      }
    }
    prev = cur;
  }
  var j = 0;
  for (var x = 1; x < k; x++) {
    if (prev[x] > prev[j]) j = x;
  }
  final path = Int32List(n);
  for (var i = n - 1; i >= 0; i--) {
    path[i] = j;
    j = back[i][j];
  }

  // 3. Segments; each refined with a tighter tolerance for a precise shift.
  final segments = <SyncSegment>[];
  var matched = 0;
  for (var a = 0; a < n;) {
    var b = a;
    while (b + 1 < n && path[b + 1] == path[a]) {
      b++;
    }
    final coarse = candidates[path[a]];
    var bestShift = coarse, bestScore = -1;
    for (var o = coarse - tolMs; o <= coarse + tolMs; o += 10) {
      var sc = 0;
      for (var i = a; i <= b; i++) {
        if (near(target[i].start.inMilliseconds + o, 120)) sc++;
        if (near(target[i].end.inMilliseconds + o, 120)) sc++;
      }
      if (sc > bestScore ||
          (sc == bestScore &&
              (o - coarse).abs() < (bestShift - coarse).abs())) {
        bestScore = sc;
        bestShift = o;
      }
    }
    for (var i = a; i <= b; i++) {
      if (near(target[i].start.inMilliseconds + bestShift, tolMs)) matched++;
      if (near(target[i].end.inMilliseconds + bestShift, tolMs)) matched++;
    }
    final shift = Duration(milliseconds: bestShift);
    if (segments.isEmpty || segments.last.shift != shift) {
      segments.add(SyncSegment(target[a].start, shift));
    }
    a = b + 1;
  }
  final ratio = matched / (2 * n);
  // A random time lands near some reference edge with probability [chance]
  // (35–40% for dense dialogue); picking shifts per line lifts unrelated
  // subtitles ~10 points above that. Real matches sit 30+ points above.
  return ratio < _chance(refEdges, tolMs) + 0.2
      ? null
      : AutoSyncResult(segments, ratio);
}

/// Share of the reference's time span lying within [tolMs] of one of its edges.
double _chance(Int32List edges, int tolMs) {
  final span = edges.last - edges.first + 2 * tolMs;
  var covered = 0, end = -1 << 40;
  for (final e in edges) {
    final a = e - tolMs, b = e + tolMs;
    covered += b - (a > end ? a : end).clamp(a, b);
    if (b > end) end = b;
  }
  return covered / span;
}

/// "Shifted −32.7 s" or "Shifted −32.7 s, then −42.5 s from 4:52" (times as seen in the video).
String describeSync(List<SyncSegment> segments) {
  String secs(Duration d) {
    final v = d.inMilliseconds / 1000;
    return '${v < 0 ? '\u2212' : '+'}${v.abs().toStringAsFixed(1)} s';
  }

  String at(Duration d) {
    final t = d.isNegative ? Duration.zero : d;
    return '${t.inMinutes}:${(t.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  if (segments.isEmpty) return 'Already in sync';
  final parts = [
    'Shifted ${secs(segments.first.shift)}',
    for (final s in segments.skip(1))
      'then ${secs(s.shift)} from ${at(s.from + s.shift)}',
  ];
  return parts.join(', ');
}
