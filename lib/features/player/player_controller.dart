import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../explain/explain_request.dart';
import '../explain/explain_session.dart';
import '../subtitles/auto_sync.dart';
import '../subtitles/cue.dart';
import '../subtitles/timeline.dart';
import 'lookup_session.dart';
import 'player_toast.dart';

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
    required ExplainFn explain,
    required this.pauseOnLookup,
  }) : timeline = SubtitleTimeline(originalCues),
       lookup = LookupSession(lookup),
       explain = ExplainSession(explain) {
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
  final ExplainSession explain;
  final toast = PlayerToast();
  final bool Function() pauseOnLookup;
  late final StreamSubscription<Duration> _sub;

  /// The open popup (dictionary or Explain) paused the video: closing resumes it.
  var _resumeOnClose = false;

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

  /// The picture for a card about [cue] (JPEG). Normally the frame on screen;
  /// but if the video has moved off that line since the word was tapped, a
  /// frame from inside the line, after which the video returns to where it was.
  Future<Uint8List?> cardFrame(Cue cue) async {
    final back = position;
    final at = timeline.cardFrameTime(cue, back);
    if (at == null) return player.screenshot(format: 'image/jpeg');
    try {
      await player.pause();
      await player.seek(at);
      await _seekFinished();
      return await player.screenshot(format: 'image/jpeg');
    } finally {
      await player.seek(back);
    }
  }

  /// Waits until a seek has really put its frame on screen. The position is
  /// no guide: mpv reports the target at once, long before the frame is there
  /// (a screenshot then still shows the old scene). Its "seeking" flag is.
  Future<void> _seekFinished() async {
    const step = Duration(milliseconds: 40);
    final native = player.platform;
    if (native is! NativePlayer) return Future<void>.delayed(step * 25);
    final waited = Stopwatch()..start();
    do {
      await Future<void>.delayed(step);
    } while (await native.getProperty('seeking') == 'yes' &&
        waited.elapsed < const Duration(seconds: 8));
    await Future<void>.delayed(step * 3); // the frame reaches the output
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
    explain.close();
    timeline.cues = applySync(originalCues, segments);
    _setOffset(offset);
  }

  void toggleSubtitles() {
    subtitlesOn = !subtitlesOn;
    notifyListeners();
  }

  Future<void> tapCharacter(Cue cue, int index) async {
    explain.close(); // one popup at a time; a video it paused stays paused
    if (pauseOnLookup() && player.state.playing) {
      _resumeOnClose = true;
      await player.pause();
    }
    await lookup.tap(cue, index);
  }

  /// Closes the popup; resumes playback only if the lookup paused it.
  void closeLookup() {
    lookup.close();
    _resume();
  }

  /// The lines Explain would explain now: those on screen, else the last one
  /// shown (the video may sit in the silence after it). Empty before the first.
  List<Cue> get explainTargets {
    if (active.isNotEmpty) return active;
    final last = timeline.currentAt(position);
    return [?last];
  }

  /// Pauses and opens the Explain panel on [targets] (from [explainTargets]).
  Future<void> openExplain(
    List<Cue> targets, {
    required String title,
    required String model,
  }) async {
    lookup.close();
    if (player.state.playing) {
      _resumeOnClose = true;
      await player.pause();
    }
    explain.start(
      ExplainRequest(
        title: title,
        lines: explainContext(timeline.cues, targets),
        targets: targets,
        model: model,
      ),
    );
  }

  /// Closes the panel; resumes playback only if a popup paused it.
  void closeExplain() {
    explain.close();
    _resume();
  }

  void _resume() {
    if (!_resumeOnClose) return;
    _resumeOnClose = false;
    player.play();
  }

  @override
  void dispose() {
    _sub.cancel();
    lookup.dispose();
    explain.dispose();
    toast.dispose();
    player.dispose();
    super.dispose();
  }
}
