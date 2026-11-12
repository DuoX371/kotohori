import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show prefsProvider;
import '../player/player_controller.dart' show ResumePoint;
import '../subtitles/auto_sync.dart';

/// The last video played: its subtitles and their sync (not the playback position).
class LastSession {
  const LastSession({
    required this.videoUri,
    required this.videoName,
    this.subsUri,
    this.subsName,
    this.position = Duration.zero,
    this.offset = Duration.zero,
    this.subtitlesOn = true,
    this.sync = const [],
  });

  final String videoUri;
  final String videoName;
  final String? subsUri;
  final String? subsName;
  final Duration position;
  final Duration offset;
  final bool subtitlesOn;

  /// Auto-sync result for these subtitles.
  final List<SyncSegment> sync;

  ResumePoint get resumePoint => (
    position: position,
    offset: offset,
    subtitlesOn: subtitlesOn,
    sync: sync,
  );

  LastSession withResumePoint(ResumePoint p) => LastSession(
    videoUri: videoUri,
    videoName: videoName,
    subsUri: subsUri,
    subsName: subsName,
    position: p.position,
    offset: p.offset,
    subtitlesOn: p.subtitlesOn,
    sync: p.sync,
  );

  Map<String, Object?> toJson() => {
    'videoUri': videoUri,
    'videoName': videoName,
    'subsUri': subsUri,
    'subsName': subsName,
    'positionMs': position.inMilliseconds,
    'offsetMs': offset.inMilliseconds,
    'subtitlesOn': subtitlesOn,
    'sync': [for (final s in sync) s.toJson()],
  };

  static LastSession? fromJson(Map<String, Object?> j) {
    final uri = j['videoUri'], name = j['videoName'];
    if (uri is! String || name is! String) return null;
    return LastSession(
      videoUri: uri,
      videoName: name,
      subsUri: j['subsUri'] as String?,
      subsName: j['subsName'] as String?,
      position: Duration(milliseconds: (j['positionMs'] as num?)?.toInt() ?? 0),
      offset: Duration(milliseconds: (j['offsetMs'] as num?)?.toInt() ?? 0),
      subtitlesOn: j['subtitlesOn'] as bool? ?? true,
      sync: [
        for (final s in j['sync'] as List<dynamic>? ?? const [])
          if (s is List && s.length == 2) SyncSegment.fromJson(s),
      ],
    );
  }
}

class LastSessionNotifier extends Notifier<LastSession?> {
  static const _key = 'session.last';

  @override
  LastSession? build() {
    try {
      final raw = ref.watch(prefsProvider).getString(_key);
      return raw == null
          ? null
          : LastSession.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveResumePoint(ResumePoint p) async {
    final s = state;
    if (s != null) await save(s.withResumePoint(p));
  }

  Future<void> save(LastSession s) async {
    state = s;
    await ref.read(prefsProvider).setString(_key, jsonEncode(s.toJson()));
  }
}

final lastSessionProvider = NotifierProvider<LastSessionNotifier, LastSession?>(
  LastSessionNotifier.new,
);
