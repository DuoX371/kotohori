import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../platform/media_tools.dart';
import '../anki/screenshot.dart';

const _app = MethodChannel('kotohori/app');

/// Puts [frame] (a JPEG from the player) on the clipboard as an image, with
/// [subtitle] drawn on like on screen. Returns true when Android shows its own
/// "copied" preview (13+), so the app needn't say so too.
Future<bool> copyScene(
  Uint8List frame, {
  required String? subtitle,
  required String tempDir,
  required MediaTools media,
}) async {
  // Shared with other apps via FileProvider (file_paths.xml); only the latest copy is kept.
  final dir = Directory(p.join(tempDir, 'shared'));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final path = p.join(
    dir.path,
    'kotohori_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  if (subtitle == null || subtitle.trim().isEmpty) {
    await File(path).writeAsBytes(frame);
  } else {
    final shot = await composeScreenshot(frame, subtitle: subtitle);
    await media.encodeJpeg(
      shot.rgba,
      width: shot.width,
      height: shot.height,
      outPath: path,
      quality: 90,
    );
  }
  return await _app.invokeMethod<bool>('copyImage', {'path': path}) ?? false;
}
