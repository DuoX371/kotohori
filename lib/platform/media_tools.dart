import 'package:flutter/services.dart';

/// Native media helpers for card export (MediaTools.kt on Android).
abstract interface class MediaTools {
  /// Writes [start]..[end] of the video's audio to [outPath] (.m4a, AAC),
  /// followed by [padEnd] of silence.
  Future<void> clipAudio({
    required String source,
    required Duration start,
    required Duration end,
    required String outPath,
    Duration padEnd = Duration.zero,
  });

  /// Plays a local audio file (card editor preview); replaces any clip still playing.
  Future<void> playAudio(String path);

  Future<void> stopAudio();

  /// Encodes raw RGBA pixels as a JPEG file.
  Future<void> encodeJpeg(
    Uint8List rgba, {
    required int width,
    required int height,
    required String outPath,
    int quality = 85,
  });
}

class MethodChannelMediaTools implements MediaTools {
  static const _ch = MethodChannel('kotohori/media');

  @override
  Future<void> clipAudio({
    required String source,
    required Duration start,
    required Duration end,
    required String outPath,
    Duration padEnd = Duration.zero,
  }) => _ch.invokeMethod('clipAudio', {
    'padEndMs': padEnd.inMilliseconds,
    'source': source,
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
    'out': outPath,
  });

  @override
  Future<void> playAudio(String path) =>
      _ch.invokeMethod('playAudio', {'path': path});

  @override
  Future<void> stopAudio() => _ch.invokeMethod('stopAudio');

  @override
  Future<void> encodeJpeg(
    Uint8List rgba, {
    required int width,
    required int height,
    required String outPath,
    int quality = 85,
  }) => _ch.invokeMethod('encodeJpeg', {
    'rgba': rgba,
    'width': width,
    'height': height,
    'out': outPath,
    'quality': quality,
  });
}
