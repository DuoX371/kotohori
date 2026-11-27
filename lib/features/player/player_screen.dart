import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/theme.dart';
import '../../platform/pip.dart';
import '../anki/anki_providers.dart';
import '../anki/anki_settings.dart';
import '../anki/card_editor_screen.dart';
import '../anki/card_exporter.dart' show CardDraft;
import '../dictionary/ui/providers.dart'
    show appPathsProvider, htmlBuilderProvider, lookupProvider;
import '../explain/explain_request.dart';
import '../explain/explain_settings.dart';
import '../explain/explain_settings_screen.dart';
import '../home/display_name.dart';
import '../home/video_link.dart';
import '../settings/player_settings.dart';
import '../subtitles/auto_sync.dart';
import '../subtitles/cue.dart';
import '../subtitles/embedded_subtitles.dart';
import 'copy_scene.dart';
import 'cue_list.dart';
import 'explain_panel.dart';
import 'lookup_panel.dart';
import 'player_controller.dart';
import 'player_options_sheet.dart';
import 'seek_flash.dart';
import 'subtitle_overlay.dart';
import 'tap_seeker.dart';
import 'player_toast.dart';

/// After a pinch from zoom [start] to [now] (0 fit … 1 fill): fill or fit?
/// A clear pinch goes the way the fingers moved; a small one snaps back.
bool pinchSnapsToFill(double start, double now) =>
    (now - start).abs() > 0.1 ? now > start : start > 0.5;

/// Furthest pinch-zoom, in times the fitted picture (as YouTube).
const maxZoom = 8.0;

/// Where a pinch ends up: Fit (1) or Fill ([fill]) when it stops near them,
/// otherwise the free zoom it stopped at. [start]/[now] are scales, 1 = fit.
double zoomTarget(double start, double now, double fill) {
  if (now > fill * 1.15) return now;
  if (fill <= 1.001) return 1;
  double t(double s) => ((s - 1) / (fill - 1)).clamp(0.0, 1.0);
  return pinchSnapsToFill(t(start), t(now)) ? fill : 1;
}

/// Size of a [w]×[h] video fitted whole on [screen] (scale 1).
Size fittedSize(Size screen, int? w, int? h) {
  if (w == null || h == null || w == 0 || h == 0) return screen;
  final video = w / h;
  return video > screen.width / screen.height
      ? Size(screen.width, screen.width / video)
      : Size(screen.height * video, screen.height);
}

/// Keeps a picture of [fitted] size at [scale], moved by [pan] from the
/// centre, from sliding past its edges (centred on an axis it doesn't fill).
Offset clampPan(Offset pan, Size screen, Size fitted, double scale) {
  final x = ((fitted.width * scale - screen.width) / 2).clamp(0.0, 1e9);
  final y = ((fitted.height * scale - screen.height) / 2).clamp(0.0, 1e9);
  return Offset(pan.dx.clamp(-x, x), pan.dy.clamp(-y, y));
}

/// Height of the black bar under a [w]×[h] video shown at [scale] (1 = fit) on
/// [screen]; 0 when the picture reaches the bottom edge or the size is unknown.
double letterboxBottom(Size screen, int? w, int? h, double scale) {
  if (w == null || h == null || w == 0 || h == 0 || screen.isEmpty) return 0;
  final fitHeight = (screen.width * h / w).clamp(0.0, screen.height);
  return ((screen.height - fitHeight * scale) / 2).clamp(0.0, screen.height);
}

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.videoUri,
    required this.title,
    required this.cues,
    this.resume,
    this.embeddedSubsTrack,
    this.onSave,
    this.onThumbnail,
  });
  final String videoUri;
  final String title;
  final List<Cue> cues;
  final ResumePoint? resume;

  /// The video's own track the subtitles came from (not usable as a sync reference).
  final int? embeddedSubsTrack;

  /// Told the subtitle setup when the player closes or the app goes to the background.
  final void Function(ResumePoint)? onSave;

  /// Gets a JPEG frame now and then, for the home screen's last-session card.
  final void Function(Uint8List jpeg)? onThumbnail;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  static final _darkTheme = buildTheme(Brightness.dark);
  late final c = PlayerController(
    widget.cues,
    lookup: ref.read(lookupProvider).lookup,
    explain: _askAi,
    pauseOnLookup: () => ref.read(pauseOnLookupProvider),
  );
  final _scaffold = GlobalKey<ScaffoldState>();

  /// Sends the lines to Gemini with the key in settings (read now: it can change mid-video).
  Stream<String> _askAi(ExplainRequest r) async* {
    final client = await ref.read(geminiClientProvider(r.model).future);
    final prompt = explainPrompt(r);
    yield* client.ask(system: prompt.system, user: prompt.user);
  }

  /// ✨ in the top bar: explains the subtitle line on screen.
  Future<void> _explain() async {
    final problem = explainSetupProblem(
      apiKey: await ref.read(explainApiKeyProvider.future),
    );
    if (!mounted) return;
    if (problem != null) {
      final go = await showDialog<bool>(
        context: _scaffold.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('Set up Explain'),
          content: Text(problem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (go == true) _openExplainSettings();
      return;
    }
    final targets = c.explainTargets;
    if (targets.isEmpty) {
      return c.toast.show('No subtitle line to explain here');
    }
    await c.openExplain(
      targets,
      title: displayName(widget.title),
      model: ref.read(explainModelProvider),
    );
  }

  void _openExplainSettings() {
    if (!mounted) return;
    c.player.pause();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExplainSettingsScreen()),
    );
  }

  var _controls = true;
  var _landscape = true;

  void _applyOrientation() => SystemChrome.setPreferredOrientations(
    _landscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp],
  );

  void _rotate() {
    setState(() => _landscape = !_landscape);
    _applyOrientation();
  }

  Timer? _hideTimer;
  String? _error;
  var _errorAt = Duration.zero;
  static const _errorClears = Duration(seconds: 1);

  /// In the mini player (Android picture-in-picture): video + subtitles only.
  var _pip = false;
  final _pipSubs = <StreamSubscription<Object?>>[];

  /// Home makes a mini player only while the video plays.
  void _updatePip() {
    final s = c.player.state;
    // Stays allowed while in the mini window, so pausing there keeps it open.
    Pip.configure(
      enabled: s.playing || _pip,
      playing: s.playing,
      width: s.width,
      height: s.height,
    );
  }

  void _onPip(bool inPip, bool closed) {
    if (!mounted) return;
    if (inPip) {
      if (c.lookup.isOpen) c.closeLookup();
      if (c.explain.isOpen) c.closeExplain();
      _hideTimer?.cancel();
    }
    setState(() {
      _pip = inPip;
      if (inPip) _controls = false;
    });
    _updatePip();
    if (closed) {
      c.player.pause();
      _save();
    }
  }

  /// The picture's zoom (1 = fit: whole picture, black bars) and how far it
  /// is moved from the centre. Follows the fingers while pinching; on release
  /// glides to Fit or Fill if near them.
  late final _view = ValueNotifier<(double, Offset)>((
    ref.read(videoFillProvider) ? _fillScale(_screen) : 1,
    Offset.zero,
  ));

  late final _glide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_glideStep);
  (double, Offset) _glideFrom = (1, Offset.zero), _glideTo = (1, Offset.zero);

  void _glideStep() {
    final t = Curves.easeOutCubic.transform(_glide.value);
    _view.value = (
      _glideFrom.$1 + (_glideTo.$1 - _glideFrom.$1) * t,
      Offset.lerp(_glideFrom.$2, _glideTo.$2, t)!,
    );
  }

  double _scaleAtStart = 1;
  Offset _panAtStart = Offset.zero, _focusAtStart = Offset.zero;

  Size get _screen => MediaQuery.sizeOf(context);
  Size? _viewScreen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screen != _viewScreen) {
      final first = _viewScreen == null;
      _viewScreen = _screen;
      if (!first) _resetView(); // turned, or the mini player came and went
    }
  }

  Size _fitted(Size screen) {
    final s = c.player.state;
    return fittedSize(screen, s.width, s.height);
  }

  void _resetView() {
    _glide.stop();
    _view.value = (
      ref.read(videoFillProvider) ? _fillScale(_screen) : 1,
      Offset.zero,
    );
  }

  /// How much the fitted picture must grow to fill the screen (1: same shape).
  double _fillScale(Size screen) {
    final s = c.player.state;
    final w = s.width, h = s.height;
    if (w == null || h == null || w == 0 || h == 0 || screen.isEmpty) return 1;
    final video = w / h, box = screen.width / screen.height;
    return video > box ? video / box : box / video;
  }

  void _onPinchStart(ScaleStartDetails d) {
    _glide.stop();
    _scaleAtStart = _view.value.$1;
    _panAtStart = _view.value.$2;
    _focusAtStart = d.localFocalPoint;
  }

  void _onPinchUpdate(ScaleUpdateDetails d) {
    final screen = _screen;
    final zoomed = _scaleAtStart > _fillScale(screen) * 1.01;
    if (d.pointerCount < 2 && !zoomed) return;
    final scale = (_scaleAtStart * (d.pointerCount < 2 ? 1 : d.scale)).clamp(
      1.0,
      maxZoom,
    );
    final centre = screen.center(Offset.zero);
    final spot = (_focusAtStart - centre - _panAtStart) / _scaleAtStart;
    final pan = d.localFocalPoint - centre - spot * scale;
    _view.value = (scale, clampPan(pan, screen, _fitted(screen), scale));
  }

  void _onPinchEnd() {
    final screen = _screen, fill = _fillScale(screen);
    final (scale, pan) = _view.value;
    final to = zoomTarget(_scaleAtStart, scale, fill);
    _glideFrom = (scale, pan);
    _glideTo = (to, clampPan(pan, screen, _fitted(screen), to));
    _glide.forward(from: 0);
    setState(() {});
    if (to > fill * 1.01) return;
    final filled = to > 1;
    final wasSnapped = _scaleAtStart <= fill * 1.01;
    if (wasSnapped && filled == ref.read(videoFillProvider)) return;
    ref.read(videoFillProvider.notifier).set(filled);
    c.toast.show(
      filled ? 'Fill screen' : 'Fit to screen',
      duration: const Duration(seconds: 1),
    );
  }

  late final _lifecycle = AppLifecycleListener(onHide: _save);

  void _save() {
    // Before the file has loaded the position is still 0: keep the saved one.
    if (c.player.state.duration <= Duration.zero) return;
    // Read now (the player may be disposed next), store after the current frame:
    // dispose() runs mid-build, where providers must not change.
    final point = c.resumePoint, onSave = widget.onSave;
    if (onSave != null) Future.microtask(() => onSave(point));
  }

  Timer? _saveTimer;

  Future<void> _grabThumbnail() async {
    final onThumbnail = widget.onThumbnail;
    if (onThumbnail == null) return;
    if (c.player.state.duration <= Duration.zero) return; // not loaded yet
    final jpeg = await c.player.screenshot(format: 'image/jpeg');
    if (jpeg != null) onThumbnail(jpeg);
  }

  bool _leaving = false;

  Future<void>? _exitGrab;

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    if (c.player.state.playing) {
      c.player.pause();
      _exitGrab = _grabThumbnail();
    }
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
    if (widget.resume case final r?) {
      c.setSync(r.sync, offset: r.offset);
      if (!r.subtitlesOn) c.toggleSubtitles();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _applyOrientation();
    Pip.listen(
      _onPip,
      onAction: (a) => switch (a) {
        'previous' => c.previousCue(),
        'toggle' => c.player.playOrPause(),
        'next' => c.nextCue(),
        _ => null,
      },
    );
    _pipSubs.addAll([
      c.player.stream.playing.listen((playing) {
        _updatePip();
        if (!playing && !_leaving) _grabThumbnail();
      }),
      // The video's size decides how far "fill" zooms.
      c.player.stream.width.listen((_) {
        _updatePip();
        if (mounted) setState(_resetView);
      }),
      c.player.stream.height.listen((_) {
        _updatePip();
        if (mounted) setState(_resetView);
      }),
      c.player.stream.position.listen((pos) {
        if (_error != null && (pos - _errorAt).abs() > _errorClears) {
          setState(() => _error = null);
        }
      }),
    ]);
    c.player.stream.error.listen((e) {
      if (!mounted) return;
      _errorAt = c.player.state.position;
      setState(() => _error = e);
    });
    c
        .open(
          widget.videoUri,
          autoplay: ref.read(autoplayProvider),
          start: widget.resume?.position ?? Duration.zero,
        )
        .then((_) => _poke());
    c.lookup.addListener(_refocusOnClose);
    c.explain.addListener(_refocusOnClose);
    // So the resume point survives the app being killed.
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _save());
  }

  /// However the popup closes (X, Esc, tapping the video), keyboard focus may
  /// still sit on its removed WebView, so the next Space would be lost.
  void _refocusOnClose() {
    if (!c.lookup.isOpen && !c.explain.isOpen) _keys.requestFocus();
  }

  @override
  void dispose() {
    c.lookup.removeListener(_refocusOnClose);
    c.explain.removeListener(_refocusOnClose);
    _save();
    for (final s in _pipSubs) {
      s.cancel();
    }
    Pip.listen(null);
    Pip.configure(enabled: false);
    _lifecycle.dispose();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _keys.dispose();
    _singleTap?.cancel();
    _flashOff?.cancel();
    _glide.dispose();
    _view.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
      [],
    ); // back to the app's normal rotation
    final grab = _exitGrab;
    if (grab == null) {
      c.dispose();
    } else {
      grab
          .timeout(const Duration(seconds: 2))
          .catchError((Object _) {})
          .whenComplete(c.dispose);
    }
    super.dispose();
  }

  /// Shows controls and schedules auto-hide while playing.
  void _poke() {
    _hideTimer?.cancel();
    if (!_controls) setState(() => _controls = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && c.player.state.playing) setState(() => _controls = false);
    });
  }

  // Double-tap seeking (left/right thirds), like YouTube.
  final _seeker = TapSeeker();
  final _tapClock = Stopwatch()..start();
  Timer? _singleTap, _flashOff;
  SeekFlashData? _flash;
  var _flashVisible = false;

  void _onTapUp(TapUpDetails d) {
    final w = MediaQuery.sizeOf(context).width, x = d.localPosition.dx;
    final side = x < w / 3
        ? TapSide.left
        : (x > w * 2 / 3 ? TapSide.right : TapSide.middle);
    _singleTap?.cancel();
    final seconds = _seeker.tap(_tapClock.elapsed, side);
    if (seconds != null) {
      c.seekBy(Duration(seconds: seconds));
      setState(() {
        _flash = (
          forward: seconds > 0,
          seconds: _seeker.total,
          at: d.localPosition,
          pulse: (_flash?.pulse ?? 0) + 1,
        );
        _flashVisible = true;
      });
      _flashOff?.cancel();
      _flashOff = Timer(TapSeeker.keepGoing, () {
        if (mounted) setState(() => _flashVisible = false);
      });
      return;
    }
    // The middle (and closing the popup) reacts at once; on the sides a single
    // tap waits briefly in case it becomes a double tap.
    if (side == TapSide.middle || c.lookup.isOpen || c.explain.isOpen) {
      return _toggleControls();
    }
    _singleTap = Timer(TapSeeker.doubleTap, () {
      if (mounted) _toggleControls();
    });
  }

  void _toggleControls() {
    _keys.requestFocus(); // take keyboard focus back from the popup's WebView
    if (c.lookup.isOpen) {
      return c.closeLookup(); // tapping the video dismisses the popup first
    }
    if (c.explain.isOpen) return c.closeExplain();
    if (_controls) {
      _hideTimer?.cancel();
      setState(() => _controls = false);
    } else {
      _poke();
    }
  }

  /// Lines the subtitles up with a text track inside the video (English if there is one).
  Future<void> _autoSync() async {
    final say = c.toast.show;
    say(
      'Matching with the subtitles inside the video…',
      duration: const Duration(minutes: 1),
    );
    try {
      final (tracks, lines) = await EmbeddedSubtitles.read(widget.videoUri);
      final refs = tracks.where(
        (t) =>
            t.number != widget.embeddedSubsTrack &&
            (lines[t.number]?.length ?? 0) >= 5,
      );
      if (refs.isEmpty) {
        return say('This video has no other text subtitles to match against.');
      }
      final ref = refs.firstWhere(
        (t) => t.language == 'en',
        orElse: () => refs.first,
      );
      final target = c.originalCues, reference = lines[ref.number]!;
      final result = await autoSyncInBackground(target, reference);
      if (!mounted) return;
      if (result == null) {
        return say(
          "Couldn't match these subtitles to the ${ref.label} track. Try Sync to a subtitle line instead.",
          duration: const Duration(seconds: 6),
        );
      }
      final before = (c.sync, c.timeline.offset);
      c.setSync(result.segments);
      say(
        describeSync(result.segments),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => c.setSync(before.$1, offset: before.$2),
        ),
      );
    } catch (e) {
      // Any failure must replace the "Matching…" message, not leave it hanging.
      if (mounted) {
        say(
          "Couldn't read the subtitles inside the video: ${e is FormatException ? e.message : e}",
        );
      }
    }
  }

  /// ＋ in the popup: pause, grab the current frame and open the card editor.
  /// Bumped when the card editor closes, so the popup re-checks what's in Anki.
  final _ankiChanged = ValueNotifier(0);

  /// The card for the word at [groupIndex] of the popup, its media being made.
  CardDraft? _draft(int groupIndex) {
    final result = c.lookup.result, h = c.lookup.highlight;
    if (result == null || h == null || groupIndex >= result.groups.length) {
      return null;
    }
    final group = result.groups[groupIndex];
    final (cueIndex, start, highlighted) = h;
    final cue = c.timeline.cues[cueIndex];
    final settings = ref.read(ankiSettingsProvider);
    c.player.pause();
    return ref
        .read(cardExporterProvider)
        .prepare(
          settings: settings,
          cueText: cue.text,
          matchStart: start,
          matchLength: c.lookup.followedLink
              ? highlighted
              : group.matchedLength,
          cueStart: cue.start,
          cueEnd: cue.end,
          subtitleOffset: c.timeline.offset,
          word: group.expression,
          reading: group.reading,
          definitionHtml: ref
              .read(htmlBuilderProvider)
              .ankiDefinition(
                group,
                firstDictionaryOnly: settings.firstDictionaryOnly,
              ),
          videoTitle: displayName(
            widget.title,
          ), // "Show - 02", not the release file name
          videoSource: widget.videoUri,
          screenshot: () => c.cardFrame(cue),
        );
  }

  Future<void> _addCard(int groupIndex, List<String>? existingDecks) async {
    final draft = _draft(groupIndex);
    if (draft == null) return;
    draft.existingDecks = existingDecks;
    final added = await Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => CardEditorScreen(draft: draft)),
    );
    if (added == true && mounted) {
      c.toast.show(
        'Added "${draft.word}" to Anki',
        duration: const Duration(seconds: 2),
      );
    }
    _ankiChanged.value++;
  }

  /// Quick add in the popup: adds the card at once, skipping the editor.
  Future<bool> _quickAdd(int groupIndex) async {
    final draft = _draft(groupIndex);
    if (draft == null) return false;
    final (added, message) = await ref
        .read(cardExporterProvider)
        .quickSend(draft, ref.read(ankiSettingsProvider));
    if (!mounted) return added;
    c.toast.show(message, duration: const Duration(seconds: 2));
    if (added) _ankiChanged.value++;
    return added;
  }

  /// Copies the frame on screen, with the subtitles if they're showing, to share.
  Future<void> _copyScene() async {
    final say = c.toast.show;
    try {
      final frame = await c.player.screenshot(format: 'image/jpeg');
      if (frame == null) throw StateError('no frame');
      final systemShows = await copyScene(
        frame,
        subtitle: c.subtitlesOn
            ? c.active.map((cue) => cue.text).join('\n')
            : null,
        tempDir: ref.read(appPathsProvider).tempDir,
        media: ref.read(mediaToolsProvider),
      );
      if (!systemShows) say('Scene copied');
    } catch (_) {
      say("Couldn't copy this scene");
    }
  }

  /// Runs a control action and keeps the controls visible.
  VoidCallback _act(FutureOr<void> Function() f) => () {
    f();
    _poke();
  };

  final _keys = FocusNode(debugLabel: 'player keys');

  /// Hardware keyboard shortcuts. Consumes the key so focused buttons don't also react.
  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final repeat = e is KeyRepeatEvent;
    final FutureOr<void> Function()? action = switch (e.logicalKey) {
      LogicalKeyboardKey.space when !repeat => c.player.playOrPause,
      LogicalKeyboardKey.arrowLeft => () => c.seekBy(
        const Duration(seconds: -5),
      ),
      LogicalKeyboardKey.arrowRight => () => c.seekBy(
        const Duration(seconds: 5),
      ),
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyA => c.previousCue,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyD => c.nextCue,
      LogicalKeyboardKey.keyR when !repeat => c.replayCue,
      LogicalKeyboardKey.keyS when !repeat => c.toggleSubtitles,
      LogicalKeyboardKey.keyE
          when !repeat && ref.read(explainEnabledProvider) =>
        c.explain.isOpen ? c.closeExplain : _explain,
      LogicalKeyboardKey.escape when c.lookup.isOpen => c.closeLookup,
      LogicalKeyboardKey.escape when c.explain.isOpen => c.closeExplain,
      _ => null,
    };
    if (action == null) return KeyEventResult.ignored;
    _act(action)();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Focus(
        focusNode: _keys,
        autofocus: true,
        onKeyEvent: _onKey,
        // The player is always dark, whatever the app theme.
        child: Theme(
          data: _darkTheme.copyWith(
            snackBarTheme: _darkTheme.snackBarTheme.copyWith(
              width: snackBarWidth(MediaQuery.sizeOf(context)),
            ),
          ),
          child: Scaffold(
            key: _scaffold,
            backgroundColor: Colors.black,
            endDrawer: Drawer(child: SafeArea(child: CueList(c))),
            body: ListenableBuilder(
              listenable: Listenable.merge([c.lookup, c.explain]),
              builder: (context, _) => _body(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    // Popup: right side in landscape, bottom half in portrait. Subtitles move out of its way.
    final size = MediaQuery.sizeOf(context);
    final open = c.lookup.isOpen || c.explain.isOpen;
    final wide = size.width > size.height;
    final panelWidth = size.width * 0.42;
    final panelHeight = size.height * 0.5;
    // Sit on the picture, not on the black bar under it (16:9 video on a 16:10 tablet).
    final s = c.player.state;
    final bar = letterboxBottom(
      size,
      s.width,
      s.height,
      _glide.isAnimating ? _glideTo.$1 : _view.value.$1,
    );
    final subtitleBottom = (open && !wide)
        ? panelHeight + 16
        : (_controls ? 120.0 : bar + 24);
    final subtitleRight = (open && wide) ? panelWidth + 24 : 16.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        // First, and kept in the mini player too, so the video never re-attaches.
        ClipRect(
          child: ValueListenableBuilder(
            valueListenable: _view,
            builder: (context, view, video) => _pip
                ? video!
                : Transform.translate(
                    offset: view.$2,
                    child: Transform.scale(scale: view.$1, child: video),
                  ),
            child: Video(
              controller: c.video,
              controls: NoVideoControls,
              subtitleViewConfiguration: const SubtitleViewConfiguration(
                visible: false,
              ),
            ),
          ),
        ),
        if (_pip)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Align(
              alignment: Alignment.bottomCenter,
              // Subtitles shrink with the small window.
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    (size.width / 900).clamp(0.3, 1.0),
                  ),
                ),
                child: SubtitleOverlay(c),
              ),
            ),
          ),
        if (!_pip) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _onTapUp,
            onScaleStart: _onPinchStart,
            onScaleUpdate: _onPinchUpdate,
            onScaleEnd: (_) => _onPinchEnd(),
          ),
          if (_flash case final flash?)
            Positioned.fill(child: SeekFlash(flash, visible: _flashVisible)),
          if (_error == null)
            IgnorePointer(
              child: Center(
                child: StreamBuilder(
                  stream: c.player.stream.buffering,
                  initialData: c.player.state.buffering,
                  builder: (_, b) => b.data == true
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Playback error: $_error',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.only(
              bottom: subtitleBottom,
              left: 16,
              right: subtitleRight,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SubtitleOverlay(c),
            ),
          ),
          IgnorePointer(
            ignoring: !_controls,
            child: AnimatedOpacity(
              opacity: _controls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [_topBar(), const Spacer(), _bottomBar()],
              ),
            ),
          ),
          wide
              ? Positioned(
                  top: 8,
                  right: 8,
                  bottom: 8,
                  width: panelWidth,
                  child: SafeArea(child: _panel(open, const Offset(1.05, 0))),
                )
              : Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: panelHeight,
                  child: _panel(open, const Offset(0, 1)),
                ),
          // Under the top bar, clear of the play controls; above the popup.
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: PlayerToastView(c.toast),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// The lookup popup slides in from the edge it docks to ([from], in panel
  /// sizes) and back out on close, still showing its last word as it goes.
  Widget _panel(bool open, Offset from) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: Duration(milliseconds: still ? 0 : 260),
      reverseDuration: Duration(milliseconds: still ? 0 : 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, t) => SlideTransition(
        position: Tween(begin: from, end: Offset.zero).animate(t),
        child: FadeTransition(opacity: t, child: child),
      ),
      child: c.explain.isOpen
          ? ExplainPanel(
              key: const ValueKey('explain'),
              c.explain,
              onClose: c.closeExplain,
              onOpenSettings: _openExplainSettings,
            )
          : c.lookup.isOpen
          ? LookupPanel(
              key: const ValueKey('lookup'),
              c.lookup,
              onClose: c.closeLookup,
              onAdd: _addCard,
              onQuickAdd: _quickAdd,
              ankiChanged: _ankiChanged,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _topBar() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xB3000000), Color(0x40000000), Colors.transparent],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          const BackButton(color: Colors.white),
          Expanded(
            child: Text(
              displayName(widget.title),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ref.watch(explainEnabledProvider))
            IconButton(
              tooltip: 'Explain this line',
              color: Colors.white,
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _act(_explain),
            ),
          IconButton(
            tooltip: 'Copy scene',
            color: Colors.white,
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: _act(_copyScene),
          ),
          ListenableBuilder(
            listenable: c,
            builder: (_, _) => IconButton(
              tooltip: c.subtitlesOn
                  ? 'Turn subtitles off'
                  : 'Turn subtitles on',
              color: Colors.white,
              icon: Icon(
                c.subtitlesOn
                    ? Icons.subtitles_rounded
                    : Icons.subtitles_off_outlined,
              ),
              onPressed: _act(c.toggleSubtitles),
            ),
          ),
          IconButton(
            tooltip: 'Player options',
            color: Colors.white,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              _hideTimer?.cancel();
              showPlayerOptions(
                _scaffold.currentContext!,
                c,
                onAutoSync:
                    canHaveEmbeddedSubs(widget.title) &&
                        !isVideoLink(widget.videoUri)
                    ? _autoSync
                    : null,
              ).then((_) => _poke());
            },
          ),
          IconButton(
            tooltip: 'Subtitle list',
            color: Colors.white,
            icon: const Icon(Icons.format_list_bulleted_rounded),
            onPressed: () => _scaffold.currentState?.openEndDrawer(),
          ),
        ],
      ),
    ),
  );

  /// Android 16+ ignores app orientation requests on large screens (smallest
  /// width >= 600 dp): there the device's own rotation decides, so the rotate
  /// button only shows on phones.
  bool get _canRotate => MediaQuery.sizeOf(context).shortestSide < 600;

  Widget _bottomBar() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xD9000000), Color(0x59000000), Colors.transparent],
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seekBar(),
            // Playback buttons centred; rotate pinned to the right edge. The left
            // spacer mirrors it so the centre stays centred and nothing overlaps on phones.
            Row(
              children: [
                if (_canRotate) const SizedBox(width: 48),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btn(
                        Icons.skip_previous_rounded,
                        'Previous subtitle',
                        c.previousCue,
                      ),
                      const SizedBox(width: 8),
                      _btn(
                        Icons.replay_rounded,
                        'Replay subtitle',
                        c.replayCue,
                      ),
                      const SizedBox(width: 16),
                      StreamBuilder<bool>(
                        stream: c.player.stream.playing,
                        initialData: c.player.state.playing,
                        builder: (_, s) => IconButton.filled(
                          iconSize: 36,
                          padding: const EdgeInsets.all(12),
                          tooltip: s.data! ? 'Pause' : 'Play',
                          icon: Icon(
                            s.data!
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          onPressed: _act(c.player.playOrPause),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _btn(Icons.skip_next_rounded, 'Next subtitle', c.nextCue),
                    ],
                  ),
                ),
                if (_canRotate)
                  _btn(
                    Icons.screen_rotation_rounded,
                    _landscape ? 'Rotate to portrait' : 'Rotate to landscape',
                    _rotate,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _btn(
    IconData icon,
    String tooltip,
    FutureOr<void> Function() f, {
    double size = 28,
  }) => IconButton(
    icon: Icon(icon, size: size),
    color: Colors.white,
    tooltip: tooltip,
    onPressed: _act(f),
  );

  // Rebuilds on position, duration and buffer: paused videos emit no position
  // ticks, so the duration and the still-loading buffer need their own rebuilds.
  Widget _seekBar() => StreamBuilder<Duration>(
    stream: c.player.stream.duration,
    builder: (_, _) => StreamBuilder<Duration>(
      stream: c.player.stream.buffer,
      builder: (_, _) => StreamBuilder<Duration>(
        stream: c.player.stream.position,
        builder: (_, _) {
          final pos = c.player.state.position, dur = c.player.state.duration;
          // How far ahead is loaded (a stream's download), as YouTube shows it.
          final loaded = c.player.state.buffer.inMilliseconds;
          final max = dur.inMilliseconds.toDouble();
          const time = TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFeatures: [FontFeature.tabularFigures()],
          );
          return Row(
            children: [
              Text(formatDuration(pos), style: time),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    inactiveTrackColor: Colors.white24,
                    secondaryActiveTrackColor: Colors.white54,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                  ),
                  child: Slider(
                    value: pos.inMilliseconds.clamp(0, max).toDouble(),
                    max: max <= 0 ? 1 : max,
                    secondaryTrackValue: loaded.clamp(0, max).toDouble(),
                    onChanged: max <= 0
                        ? null
                        : (v) {
                            c.player.seek(Duration(milliseconds: v.round()));
                            _poke();
                          },
                  ),
                ),
              ),
              Text(formatDuration(dur), style: time),
            ],
          );
        },
      ),
    ),
  );
}
