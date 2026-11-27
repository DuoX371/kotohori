import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../app/theme.dart';
import '../../platform/documents.dart';
import '../dictionary/ui/providers.dart' show appPathsProvider, dioProvider;
import '../anki/card_builder.dart' show clock;
import '../player/player_controller.dart' show ResumePoint;
import '../player/player_screen.dart';
import '../settings/settings_screen.dart';
import '../subtitles/cue.dart';
import '../subtitles/embedded_subtitles.dart';
import '../subtitles/subtitle_loader.dart';
import 'display_name.dart';
import 'last_session.dart';
import 'swipe_to_delete.dart';
import 'video_link.dart';
import '../notices/notices_button.dart';

/// Start screen: pick a video and a subtitle file, then play — or restore the last one.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _videoExts = {
    'mp4',
    'mkv',
    'webm',
    'avi',
    'mov',
    'm4v',
    'ts',
    'flv',
    'wmv',
  };
  static const _subExts = {'srt', 'ass', 'ssa', 'vtt'};

  PickedDoc? _video;
  PickedDoc? _subs;
  List<Cue>? _cues;
  String? _subsError;

  /// null = still checking or nothing played yet; false = files moved/renamed/deleted.
  bool? _restorable;
  Uint8List? _thumb;

  static String _ext(String name) => name.toLowerCase().split('.').last;

  String get _dataDir => p.dirname(ref.read(appPathsProvider).dbPath);

  /// A frame of a video, grabbed by the player; one per video in the history.
  File _thumbFor(String videoUri) => File(
    p.join(_dataDir, 'thumbs', '${md5.convert(utf8.encode(videoUri))}.jpg'),
  );

  /// Deletes frames of videos no longer in the history.
  Future<void> _tidyThumbs() async {
    final keep = {
      for (final e in ref.read(playHistoryProvider)) _thumbFor(e.videoUri).path,
    };
    try {
      await for (final f in Directory(p.join(_dataDir, 'thumbs')).list()) {
        if (!keep.contains(f.path)) await f.delete();
      }
    } on FileSystemException {
      // no frames yet
    }
  }

  /// URIs whose read grants must survive a new pick.
  Iterable<String?> get _keep {
    final last = ref.read(lastSessionProvider);
    return [
      _video?.uri,
      _subs?.uri,
      last?.videoUri,
      last?.subsUri,
      for (final e in ref.read(playHistoryProvider)) ...[e.videoUri, e.subsUri],
    ];
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void initState() {
    super.initState();
    _checkRestore();
  }

  Future<void> _pickVideo() async {
    // octet-stream: some file providers don't know the MKV type; the extension is checked below.
    final f = await Documents.pick(
      mimeTypes: [
        'video/*',
        'application/x-matroska',
        'application/octet-stream',
      ],
      keep: _keep,
    );
    if (f == null) return;
    if (!_videoExts.contains(_ext(f.name))) {
      return _snack('Choose a video file (${_videoExts.join(', ')})');
    }
    _setVideo(f);
  }

  Future<void> _openLink() async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    final current = _video?.uri;
    if (!mounted) return;
    final video = await showDialog<PickedDoc>(
      context: context,
      builder: (_) => _LinkDialog(
        check: (link) => checkVideoLink(ref.read(dioProvider), link),
        initial: current != null && isVideoLink(current)
            ? current
            : parseVideoLink(clip)?.toString() ?? '',
      ),
    );
    if (video != null) _setVideo(video);
  }

  void _setVideo(PickedDoc f) => setState(() {
    // Subtitles taken from the previous video don't belong to this one.
    if (embeddedTrackOf(_subs?.uri) != null) {
      _subs = null;
      _cues = null;
      _subsError = null;
    }
    _video = f;
  });

  static Future<bool> _canOpen(String uri) async =>
      isVideoLink(uri) || await Documents.canOpen(uri);

  Future<void> _pickSubs() async {
    final video = _video;
    if (video != null &&
        !isVideoLink(video.uri) &&
        canHaveEmbeddedSubs(video.name)) {
      final choice = await showModalBottomSheet<Object>(
        context: context,
        builder: (_) => _SubtitleSourceSheet(videoUri: video.uri),
      );
      if (choice is EmbeddedTrack) return _useEmbedded(video.uri, choice);
      if (choice != #file) return;
    }
    // */*: Android has no MIME type for .ass/.ssa, so a type filter greys them out.
    final f = await Documents.pick(mimeTypes: ['*/*'], keep: _keep);
    if (f == null) return;
    await _loadSubs(f);
  }

  Future<void> _useEmbedded(String videoUri, EmbeddedTrack t) async {
    final (_, cues) = await EmbeddedSubtitles.read(
      videoUri,
    ); // already scanned by the sheet
    final lines = cues[t.number] ?? const <Cue>[];
    setState(() {
      _subs = (uri: embeddedSubsUri(t.number), name: t.label, size: -1);
      _cues = lines.isEmpty ? null : lines;
      _subsError = lines.isEmpty ? 'This track has no lines' : null;
    });
  }

  /// Returns false if the file could not be read at all.
  Future<bool> _loadSubs(PickedDoc f) async {
    try {
      if (!_subExts.contains(_ext(f.name))) {
        throw const FormatException('Choose a .srt, .ass, .ssa or .vtt file');
      }
      if (f.size > 20 << 20) {
        throw const FormatException('File is too large for a subtitle file');
      }
      final cues = parseSubtitleFile(await Documents.read(f.uri), f.name);
      setState(() {
        _subs = f;
        _cues = cues;
        _subsError = null;
      });
    } on FormatException catch (e) {
      setState(() {
        _subs = f;
        _cues = null;
        _subsError = e.message;
      });
    } on PlatformException {
      return false;
    }
    return true;
  }

  bool _starting = false;

  Future<void> _start(Future<void> Function() open) async {
    if (_starting) return;
    _starting = true;
    try {
      await open();
    } finally {
      _starting = false;
    }
  }

  /// [resume]: the restored session's subtitle sync; a fresh Play starts with no offset.
  Future<void> _play({ResumePoint? resume}) async {
    final v = _video!;
    final session = ref.read(lastSessionProvider.notifier);
    final thumbFile = _thumbFor(v.uri);
    await session.save(
      LastSession(
        videoUri: v.uri,
        videoName: v.name,
        subsUri: _subs?.uri,
        subsName: _subs?.name,
      ).withResumePoint(
        resume ??
            (
              position: Duration.zero,
              offset: Duration.zero,
              subtitlesOn: true,
              sync: const [],
            ),
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          videoUri: v.uri,
          title: v.name,
          cues: _cues ?? const [],
          resume: resume,
          embeddedSubsTrack: embeddedTrackOf(_subs?.uri),
          onSave: session.saveResumePoint,
          onThumbnail: (jpeg) async {
            await thumbFile.parent.create(recursive: true);
            await thumbFile.writeAsBytes(jpeg, flush: true);
            // Leaving the player, the frame lands after Home is back: show it.
            await ResizeImage(FileImage(thumbFile), width: 256).evict();
            if (mounted) await _checkRestore();
          },
        ),
      ),
    );
    await _tidyThumbs();
    await _checkRestore();
  }

  Future<bool> _checkRestore() async {
    final s = ref.read(lastSessionProvider);
    // ref can't be used once the awaits below outlive the screen
    final thumbFile = s == null ? null : _thumbFor(s.videoUri);
    final legacy = File(p.join(_dataDir, 'last_session.jpg'));
    // Subtitles from inside the video need only the video.
    final ok =
        s != null &&
        await _canOpen(s.videoUri) &&
        (s.subsUri == null ||
            embeddedTrackOf(s.subsUri) != null ||
            await Documents.canOpen(s.subsUri!));
    Uint8List? thumb;
    try {
      if (thumbFile != null && legacy.existsSync()) {
        await thumbFile.parent.create(recursive: true);
        await legacy.rename(thumbFile.path);
      }
      thumb = await thumbFile?.readAsBytes();
    } on FileSystemException {
      thumb = null;
    }
    if (mounted) {
      setState(() {
        _restorable = s == null ? null : ok;
        _thumb = thumb;
      });
    }
    return ok;
  }

  void _restoreFailed() {
    setState(() => _restorable = false);
    _snack(
      "Couldn't restore the last session. The file may have been moved, renamed or deleted.",
    );
  }

  Future<void> _forget(LastSession s) async {
    await ref.read(playHistoryProvider.notifier).remove(s.videoUri);
    await _tidyThumbs();
  }

  Future<void> _restoreOlder(LastSession s) async {
    final name = displayName(s.videoName);
    if (!await _canOpen(s.videoUri)) {
      await _forget(s);
      return _snack(
        "Can't find \"$name\" any more, so it was removed from history.",
      );
    }
    final subsUri = s.subsUri;
    if (subsUri != null &&
        embeddedTrackOf(subsUri) == null &&
        !await Documents.canOpen(subsUri)) {
      if (!mounted) return;
      final play = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Can't find the subtitles"),
          content: Text(
            'The subtitles file for "$name" was moved, renamed or deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Remove from history'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Play without subtitles'),
            ),
          ],
        ),
      );
      if (play == null) return;
      if (!play) return _forget(s);
      return _restore(
        LastSession(
          videoUri: s.videoUri,
          videoName: s.videoName,
        ).withResumePoint(s.resumePoint),
        checked: true,
      );
    }
    await _restore(s, checked: true);
  }

  Future<void> _removeOlder(LastSession s) async {
    final history = ref.read(playHistoryProvider.notifier);
    final index = ref
        .read(playHistoryProvider)
        .indexWhere((e) => e.videoUri == s.videoUri);
    await history.remove(s.videoUri);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${displayName(s.videoName)}" from history'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => history.insert(index, s),
          ),
        ),
      );
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear play history?'),
        content: const Text(
          'Removes every video from the list, including the last played one. Your files are not touched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(lastSessionProvider.notifier).clear();
    await _tidyThumbs();
    setState(() {
      _restorable = null;
      _thumb = null;
    });
    _snack('Play history cleared');
  }

  Future<void> _restore(LastSession s, {bool checked = false}) async {
    if (!checked && !await _checkRestore()) return _restoreFailed();
    final subsUri = s.subsUri;
    List<Cue>? cues;
    final track = embeddedTrackOf(subsUri);
    if (track != null) {
      try {
        cues = (await EmbeddedSubtitles.read(s.videoUri)).$2[track];
      } on Exception {
        return _restoreFailed();
      }
    } else if (subsUri != null) {
      try {
        cues = parseSubtitleFile(
          await Documents.read(subsUri),
          s.subsName ?? '',
        );
      } on PlatformException {
        return _restoreFailed();
      } on FormatException {
        cues = null; // parsed fine last time; play without rather than block
      }
    }
    setState(() {
      _video = (uri: s.videoUri, name: s.videoName, size: -1);
      _subs = subsUri == null
          ? null
          : (uri: subsUri, name: s.subsName ?? '', size: -1);
      _cues = cues;
      _subsError = null;
    });
    await _play(resume: s.resumePoint);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cues = _cues;
    final last = ref.watch(lastSessionProvider);
    final older = [
      for (final e in ref.watch(playHistoryProvider))
        if (e.videoUri != last?.videoUri) e,
    ];
    final hero = _LastSessionHero(
      session: last,
      restorable: _restorable,
      thumbnail: _thumb,
      onRestore: last != null && _restorable == true
          ? () => _start(() => _restore(last))
          : null,
    );
    final pickers = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PickTile(
          icon: Icons.movie_outlined,
          label: 'Video',
          empty: 'Choose a video file',
          file: _video?.name,
          detail: switch (_video?.uri) {
            final u? when isVideoLink(u) => Uri.parse(u).host,
            _ => null,
          },
          onTap: _pickVideo,
          onLink: _openLink,
        ),
        const SizedBox(height: 12),
        _PickTile(
          icon: Icons.subtitles_outlined,
          label: 'Subtitles',
          empty: 'Choose .srt, .ass or .vtt',
          file: _subs?.name,
          fromVideo: embeddedTrackOf(_subs?.uri) != null,
          detail:
              _subsError ??
              (cues == null
                  ? null
                  : embeddedTrackOf(_subs?.uri) != null
                  ? '${cues.length} lines, from the video'
                  : '${cues.length} lines'),
          isError: _subsError != null,
          onTap: _pickSubs,
          onClear: _subs == null
              ? null
              : () => setState(() {
                  _subs = null;
                  _cues = null;
                  _subsError = null;
                }),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _video == null ? null : () => _start(_play),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            _video != null && cues == null ? 'Play without subtitles' : 'Play',
          ),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Image.asset(appIconAsset, width: 32, height: 32),
                ),
              ),
              TextSpan(
                text: 'Kotohori',
                style: t.textTheme.titleMedium?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          const NoticesButton(),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) => ListView(
          padding: pagePadding(context, maxWidth: 1200, top: 8),
          children: [
            if (box.maxWidth >= 840)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: hero),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: pickers),
                ],
              )
            else ...[
              hero,
              const SizedBox(height: 20),
              pickers,
            ],
            if (older.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recently played',
                      style: t.textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearHistory,
                    child: const Text('Clear history'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final e in older)
                _HistoryTile(
                  key: ValueKey(e.videoUri),
                  session: e,
                  thumbnail: _thumbFor(e.videoUri),
                  onTap: () => _start(() => _restoreOlder(e)),
                  onDelete: () => _removeOlder(e),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The last video, big, with a frame from it: one tap to get back in.
class _LastSessionHero extends StatelessWidget {
  const _LastSessionHero({
    required this.session,
    required this.restorable,
    required this.thumbnail,
    required this.onRestore,
  });
  final LastSession? session;
  final bool? restorable;
  final Uint8List? thumbnail;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = session;
    final thumb = thumbnail;
    const onImage = Colors.white;
    final (String title, String line) = switch ((s, restorable)) {
      (null, _) => (
        'Nothing played yet',
        'Choose a video and its subtitles. It will wait here for next time.',
      ),
      (final s?, false) => (
        displayName(s.videoName),
        "Can't find the files any more: moved, renamed or deleted.",
      ),
      (final s?, _) => (displayName(s.videoName), _subsLine(s)),
    };
    return Card(
      child: InkWell(
        onTap: onRestore,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The frame from leaving the player arrives just after Home shows.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: thumb != null && s != null
                    ? Image.memory(
                        thumb,
                        key: ObjectKey(thumb),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        cacheWidth: 1280,
                      )
                    : DecoratedBox(
                        key: const ValueKey('blank'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              t.colorScheme.primary.withValues(alpha: 0.22),
                              t.colorScheme.surfaceContainerHigh,
                            ],
                          ),
                        ),
                      ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1],
                    colors: [Colors.transparent, Color(0xE6000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.headlineSmall?.copyWith(
                              color: onImage,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (s != null && restorable != false) ...[
                                Icon(
                                  s.subsName == null
                                      ? Icons.subtitles_off_outlined
                                      : Icons.subtitles_outlined,
                                  size: 16,
                                  color: onImage.withValues(alpha: 0.75),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  line,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    color: restorable == false
                                        ? const Color(0xFFFFB4AB)
                                        : onImage.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: onRestore,
                      icon: const Icon(Icons.play_arrow_rounded),
                      // The time only once there is one: "00:00" says nothing.
                      label: Text(
                        s != null && s.position >= const Duration(seconds: 1)
                            ? 'Resume at ${clock(s.position)}'
                            : 'Restore',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _subsLine(LastSession s) => switch (s.subsName) {
  null => 'No subtitles',
  final n when embeddedTrackOf(s.subsUri) != null => '$n, from the video',
  final n => displayName(n),
};

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    super.key,
    required this.session,
    required this.thumbnail,
    required this.onTap,
    required this.onDelete,
  });
  final LastSession session;
  final File thumbnail;
  final VoidCallback onTap;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = session;
    final at = s.position >= const Duration(seconds: 1)
        ? ' · at ${clock(s.position)}'
        : '';
    final blank = ColoredBox(
      color: t.colorScheme.surfaceContainerHigh,
      child: Icon(Icons.movie_outlined, color: t.colorScheme.onSurfaceVariant),
    );
    return SwipeToDelete(
      onDelete: onDelete,
      gap: 8,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 128,
                    height: 72,
                    child: Image.file(
                      thumbnail,
                      fit: BoxFit.cover,
                      cacheWidth: 256,
                      errorBuilder: (_, _, _) => blank,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName(s.videoName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            s.subsName == null
                                ? Icons.subtitles_off_outlined
                                : Icons.subtitles_outlined,
                            size: 16,
                            color: t.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_subsLine(s)}$at',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.bodyMedium?.copyWith(
                                color: t.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow_rounded,
                  color: t.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A whole-tile file picker: tap anywhere to choose (or change) the file.
class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.icon,
    required this.label,
    required this.empty,
    required this.file,
    required this.onTap,
    this.detail,
    this.isError = false,
    this.onClear,
    this.fromVideo = false,
    this.onLink,
  });
  final IconData icon;
  final String label;
  final String empty;
  final String? file;
  final String? detail;
  final bool isError;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  final VoidCallback? onLink;

  /// A track inside the video: [file] is already a readable label ("English (CR)").
  final bool fromVideo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final f = file;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: f == null
                    ? c.surfaceContainerHigh
                    : c.primary.withValues(alpha: 0.16),
                foregroundColor: f == null ? c.onSurfaceVariant : c.primary,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.textTheme.labelMedium?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f == null ? empty : (fromVideo ? f : displayName(f)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.titleMedium?.copyWith(
                        color: f == null ? c.onSurfaceVariant : null,
                      ),
                    ),
                    if (f != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail ?? f,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: isError ? c.error : c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onLink != null)
                IconButton(
                  tooltip: 'Open a video link',
                  icon: const Icon(Icons.link),
                  onPressed: onLink,
                ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Remove $label',
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    f == null ? Icons.add : Icons.swap_horiz,
                    color: c.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for a video link; pops it as a [PickedDoc] once [check] finds a video.
class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.initial, required this.check});
  final String initial;

  /// The video's name, or null if the link isn't a video.
  final Future<String?> Function(Uri link) check;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;
  var _checking = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_checking) return;
    const invalid = 'Invalid video link';
    final link = parseVideoLink(_text.text);
    if (link == null) return setState(() => _error = invalid);
    setState(() => _checking = true);
    final name = await widget.check(link);
    if (!mounted) return;
    if (name != null) {
      final PickedDoc video = (uri: link.toString(), name: name, size: -1);
      return Navigator.of(context).pop(video);
    }
    setState(() {
      _checking = false;
      _error = invalid;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Open a video link'),
    content: TextField(
      controller: _text,
      autofocus: true,
      readOnly:
          _checking, // not disabled: that drops the focus and the keyboard
      keyboardType: TextInputType.url,
      autocorrect: false,
      onEditingComplete:
          _open, // unlike onSubmitted, keeps the keyboard up to fix a bad link
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        hintText: 'Enter video link here (.mp4, .mkv, .m3u8…)',
        helperMaxLines: 2,
        errorText: _error,
        errorMaxLines: 3,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _checking ? null : _open,
        child: _checking
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Open'),
      ),
    ],
  );
}

/// "Choose a file…" plus the text subtitle tracks found inside the video.
/// Pops [#file] or the chosen [EmbeddedTrack].
class _SubtitleSourceSheet extends StatelessWidget {
  const _SubtitleSourceSheet({required this.videoUri});
  final String videoUri;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Choose a file…'),
              subtitle: const Text('.srt, .ass or .vtt'),
              onTap: () => Navigator.pop(context, #file),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Inside the video',
                style: t.textTheme.titleSmall?.copyWith(
                  color: t.colorScheme.primary,
                ),
              ),
            ),
            FutureBuilder(
              future: EmbeddedSubtitles.read(videoUri),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const ListTile(
                    leading: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    title: Text('Looking for subtitles in the video…'),
                  );
                }
                if (snap.hasError) {
                  final e = snap.error;
                  return ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text("Couldn't read the video's subtitles"),
                    subtitle: Text(e is FormatException ? e.message : '$e'),
                  );
                }
                final tracks = snap.data?.$1 ?? const <EmbeddedTrack>[];
                if (tracks.isEmpty) {
                  return const ListTile(
                    leading: Icon(Icons.subtitles_off_outlined),
                    title: Text('No text subtitles inside this video'),
                  );
                }
                final lines = snap.data!.$2;
                // Japanese first: that's what this app is for.
                final sorted = [...tracks]
                  ..sort(
                    (a, b) =>
                        (a.language == 'ja' ? 0 : 1) -
                        (b.language == 'ja' ? 0 : 1),
                  );
                return Column(
                  children: [
                    for (final tr in sorted)
                      ListTile(
                        leading: const Icon(Icons.subtitles_outlined),
                        title: Text(tr.label),
                        subtitle: Text(
                          '${lines[tr.number]?.length ?? 0} lines',
                        ),
                        onTap: () => Navigator.pop(context, tr),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
