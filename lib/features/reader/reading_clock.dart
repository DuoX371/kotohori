/// Times reading from page to page: the time between two page changes counts
/// only if it was short enough to have been spent reading ([idleLimit]), and
/// stops at a [pause] (app in the background). Also learns how many
/// characters a minute the reader gets through, from ordinary forward page
/// turns only (not jumps).
class ReadingClock {
  ReadingClock({this.idleLimit = const Duration(minutes: 3)});
  final Duration idleLimit;

  /// Forward moves larger than this are jumps (chapter list, links), not reading.
  static const maxStep = 3000;

  /// Characters a minute beyond any reader's pace (fluent native ≈ 600–900).
  static const maxPace = 1500;

  (Duration, int)? _last;
  var _readMs = 0, _paceMs = 0, _paceChars = 0;

  /// The reader is at book character [position] at time [at].
  void at(Duration at, int position) {
    if (_last case (final t, final p)) {
      final gap = at - t;
      if (gap <= idleLimit && !gap.isNegative) {
        _readMs += gap.inMilliseconds;
        final step = position - p;
        // Faster than [maxPace] is skimming (or a test bot), not reading.
        final fast = step * 60000 > maxPace * gap.inMilliseconds;
        if (step > 0 && step <= maxStep && !fast) {
          _paceMs += gap.inMilliseconds;
          _paceChars += step;
        }
      }
    }
    _last = (at, position);
  }

  /// Not reading until the next [at].
  void pause() => _last = null;

  /// Reading time counted since the last call.
  int takeReadMs() {
    final ms = _readMs;
    _readMs = 0;
    return ms;
  }

  /// Characters a minute this session; null before a minute of reading.
  int? get sessionPace =>
      _paceMs < 60000 ? null : (_paceChars * 60000 / _paceMs).round();
}

/// How long [remainingChars] take at [charsPerMinute].
Duration timeLeft({required int remainingChars, required int charsPerMinute}) =>
    Duration(seconds: (remainingChars * 60 / charsPerMinute).round());
