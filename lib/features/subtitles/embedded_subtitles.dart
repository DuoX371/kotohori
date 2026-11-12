import 'dart:isolate';

import '../../platform/documents.dart';
import '../../platform/fd_byte_source.dart';
import 'cue.dart';
import 'mkv/mkv_cues.dart';
import 'mkv/mkv_reader.dart';

/// A text subtitle track inside a video file.
class EmbeddedTrack {
  const EmbeddedTrack(this.number, this.label, this.language);
  final int number;

  /// "English (CR)".
  final String label;

  /// Two-letter code, e.g. `en`, `ja`.
  final String language;
}

/// Stands in for a subtitle file's URI when the subtitles come from inside the video.
const _scheme = 'video-track:';
String embeddedSubsUri(int track) => '$_scheme$track';
int? embeddedTrackOf(String? subsUri) =>
    subsUri != null && subsUri.startsWith(_scheme)
    ? int.tryParse(subsUri.substring(_scheme.length))
    : null;

/// Only Matroska carries text subtitle tracks we can read (MP4 ones are rare).
bool canHaveEmbeddedSubs(String videoName) => const {
  'mkv',
  'mka',
  'webm',
}.contains(videoName.toLowerCase().split('.').last);

/// Reads text subtitle tracks from videos, one video cached at a time.
/// The scan runs on a background isolate: it reads every frame header of the
/// file (~0.1–2 s for an episode, depending on storage).
abstract final class EmbeddedSubtitles {
  static String? _uri;
  static Future<(List<EmbeddedTrack>, Map<int, List<Cue>>)>? _scan;

  /// Every text subtitle track with its lines. Throws [FormatException] for non-MKV files.
  static Future<(List<EmbeddedTrack>, Map<int, List<Cue>>)> read(
    String videoUri,
  ) {
    if (_uri == videoUri && _scan != null) return _scan!;
    _uri = videoUri;
    final scan = _readFile(videoUri);
    _scan = scan;
    scan.catchError((Object _) {
      if (_scan == scan) _scan = null; // let a later attempt retry
      return (const <EmbeddedTrack>[], const <int, List<Cue>>{});
    });
    return scan;
  }

  static Future<(List<EmbeddedTrack>, Map<int, List<Cue>>)> _readFile(
    String uri,
  ) async {
    final (:fd, :size) = await Documents.openFd(uri);
    try {
      return await Isolate.run(() {
        final mkv = readMkvSubtitles(FdByteSource(fd, size));
        final text = mkv.tracks.where((t) => t.isText).toList();
        return (
          [
            for (final t in text)
              EmbeddedTrack(t.number, mkvTrackLabel(t), mkvLanguageCode(t)),
          ],
          {
            for (final t in text)
              t.number: mkvTrackCues(t, mkv.blocks[t.number] ?? const []),
          },
        );
      });
    } finally {
      await Documents.closeFd(fd);
    }
  }
}
