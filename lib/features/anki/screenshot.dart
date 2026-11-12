import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Scales a video frame (encoded image bytes) to [maxWidth] (null = full size)
/// and optionally draws [subtitle] near the bottom like the on-screen overlay.
/// Returns raw RGBA pixels for native JPEG encoding.
Future<({Uint8List rgba, int width, int height})> composeScreenshot(
  Uint8List frame, {
  int? maxWidth,
  String? subtitle,
}) async {
  final probe = await ui.instantiateImageCodec(frame);
  final original = (await probe.getNextFrame()).image;
  final scale = maxWidth != null && original.width > maxWidth;
  final codec = scale
      ? await ui.instantiateImageCodec(frame, targetWidth: maxWidth)
      : probe;
  final image = scale ? (await codec.getNextFrame()).image : original;
  final w = image.width, h = image.height;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(image, Offset.zero, Paint());
  if (subtitle != null && subtitle.trim().isNotEmpty) {
    final fontSize = h * 0.065;
    TextPainter painter(Paint? stroke) => TextPainter(
      text: TextSpan(
        text: subtitle,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.25,
          foreground: stroke,
          color: stroke == null ? const Color(0xFFFFFFFF) : null,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w * 0.92);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fontSize * 0.16
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF000000);
    final back = painter(outline), front = painter(null);
    final offset = Offset((w - front.width) / 2, h - front.height - h * 0.05);
    back.paint(canvas, offset);
    front.paint(canvas, offset);
  }
  final out = await recorder.endRecording().toImage(w, h);
  final bytes = await out.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  out.dispose();
  return (rgba: bytes!.buffer.asUint8List(), width: w, height: h);
}
