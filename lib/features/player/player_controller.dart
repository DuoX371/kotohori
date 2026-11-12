import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../subtitles/auto_sync.dart';
import '../subtitles/cue.dart';
import '../subtitles/timeline.dart';
import 'lookup_session.dart';

/// Where playback stopped, plus subtitle sync and on/off: restored with the last session.
typedef ResumePoint = ({
  Duration position,
  Duration offset,
  bool subtitlesOn,
  List<SyncSegment> sync,
});

/// Owns the media_kit player and the subtitle state the overlay shows.
/// Cue maths lives in [SubtitleTimeline]; this class only wires it to playback.
class PlayerController extends ChangeNotifier {
  /// [pauseOnLookup] is read at tap time so the setting can change mid-video.
  PlayerController(
    this.originalCues, {
    required LookupFn lookup,
    required this.pauseOnLookup,
  }) : timeline = SubtitleTimeline(originalCues),
       lookup = LookupSession(lookup) {
    _sub = player.stream.position.listen(_refresh);
  }

  final player = Player();
  late final video = VideoController(player);
  final SubtitleTimeline timeline;

  /// The lines as loaded, before auto sync re-timed them.
  final List<Cue> originalCues;

  /// Auto-sync result in effect (empty = lines at their file times).
  List<SyncSegment> sync = const [];
  final LookupSession lookup;
  final bool Function() pauseOnLookup;
  late final StreamSubscription<Duration> _sub;
  var _resumeAfterLookup = false;

  static const offsetStep = Duration(milliseconds: 100);

  List<Cue> active = const [];

  Future<void> open(
    String uri, {
    required bool autoplay,
    Duration start = Duration.zero,
  }) async {
    // We render subtitles ourselves. Set before open: otherwise mpv auto-loads a
    // same-named .srt / embedded track and burns it into the video frame.
    final native = player.platform;
    if (native is NativePlayer) {
      await native.setProperty('sub-auto', 'no');
      await native.setProperty('sid', 'no');
      await native.setProperty('sub-visibility', 'no');
    }
    await player.open(
      Media(uri, start: start > Duration.zero ? start : null),
      play: autoplay,
    );
  }

  Duration get position => player.state.position;

  void _refresh(Duration pos) {
    final next = timeline.activeAt(pos);
    if (listEquals(
      next.map((c) => c.index).toList(),
      active.map((c) => c.index).toList(),
    )) {
      return;
    }
    active = next;
    notifyListeners();
  }

  Future<void> seekToCue(Cue? cue) async {
    if (cue == null) return;
    final t = timeline.startOf(cue);
    await player.seek(t < Duration.zero ? Duration.zero : t);
    _refresh(timeline.startOf(cue));
  }

  Future<void> nextCue() => seekToCue(timeline.nextAfter(position));
  Future<void> previousCue() => seekToCue(timeline.previousBefore(position));
  Future<void> replayCue() async {
    await seekToCue(timeline.currentAt(position));
    await player.play();
  }

  Future<void> seekBy(Duration delta) {
    final t = position + delta;
    final end = player.state.duration;
    return player.seek(
      t < Duration.zero
          ? Duration.zero
          : (end > Duration.zero && t > end ? end : t),
    );
  }

  void shiftOffset(Duration delta) => _setOffset(timeline.offset + delta);

  void resetOffset() => _setOffset(Duration.zero);

  /// Makes [cue] start at the current position. Returns false if there is no cue.
  bool syncCueToNow(Cue? cue) {
    if (cue == null) return false;
    _setOffset(timeline.offsetToStart(cue, position));
    return true;
  }

  void _setOffset(Duration offset) {
    timeline.offset = offset;
    active = const [];
    _refresh(position);
    notifyListeners();
  }

  bool subtitlesOn = true;

  ResumePoint get resumePoint => (
    position: position,
    offset: timeline.offset,
    subtitlesOn: subtitlesOn,
    sync: sync,
  );

  /// Re-times the lines (auto sync); [offset] goes on top for fine-tuning.
  void setSync(List<SyncSegment> segments, {Duration offset = Duration.zero}) {
    sync = segments;
    lookup.close(); // its highlight points at line indices that change
    timeline.cues = applySync(originalCues, segments);
    _setOffset(offset);
  }

  void toggleSubtitles() {
    subtitlesOn = !subtitlesOn;
    notifyListeners();
  }

  Future<void> tapCharacter(Cue cue, int index) async {
    if (pauseOnLookup() && player.state.playing) {
      _resumeAfterLookup = true;
      await player.pause();
    }
    await lookup.tap(cue, index);
  }

  /// Closes the popup; resumes playback only if the lookup paused it.
  void closeLookup() {
    lookup.close();
    if (_resumeAfterLookup) {
      _resumeAfterLookup = false;
      player.play();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    lookup.dispose();
    player.dispose();
    super.dispose();
  }
}
