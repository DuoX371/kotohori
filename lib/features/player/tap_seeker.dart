/// Which part of the video a tap landed on (left and right thirds seek).
enum TapSide { left, middle, right }

/// YouTube-style double-tap seeking: a double tap on the left or right third
/// seeks 5 s that way, and each further tap on that side soon after adds 5 s.
class TapSeeker {
  static const step = 5;
  static const doubleTap = Duration(milliseconds: 300);
  static const keepGoing = Duration(milliseconds: 700);

  Duration? _lastTap, _lastSeek;
  TapSide? _lastSide;
  int _streak = 0;

  /// Seconds seeked in the current streak (for the "10 seconds" flash).
  int get total => _streak * step;

  /// Seconds to seek now (negative: back), or null when this tap isn't a
  /// seek (it may be a single tap: show/hide the controls).
  int? tap(Duration at, TapSide side) {
    final dir = switch (side) {
      TapSide.left => -1,
      TapSide.right => 1,
      TapSide.middle => 0,
    };
    final streaking =
        _lastSeek != null && at - _lastSeek! <= keepGoing && side == _lastSide;
    final double =
        _lastTap != null && at - _lastTap! <= doubleTap && side == _lastSide;
    if (dir != 0 && (streaking || double)) {
      _streak = streaking ? _streak + 1 : 1;
      _lastSeek = at;
      _lastTap = null;
      return dir * step;
    }
    _streak = 0;
    _lastSeek = null;
    _lastTap = at;
    _lastSide = side;
    return null;
  }
}
