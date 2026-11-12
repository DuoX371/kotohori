import 'package:flutter/services.dart';

/// Android picture-in-picture (the mini player when pressing Home), see MainActivity.
abstract final class Pip {
  static const _ch = MethodChannel('kotohori/pip');

  /// [enabled]: Home turns the app into the mini player. [width]/[height]: the
  /// video's size, for the window's shape.
  /// [playing]: the mini window shows Pause (else Play).
  static Future<void> configure({
    required bool enabled,
    bool playing = false,
    int? width,
    int? height,
  }) => _ch.invokeMethod('configure', {
    'enabled': enabled,
    'playing': playing,
    'width': width,
    'height': height,
  });

  /// [closed]: the mini window was dismissed (not expanded back). [onAction]:
  /// a mini window button, "previous", "toggle" or "next".
  static void listen(
    void Function(bool inPip, bool closed)? onChanged, {
    void Function(String action)? onAction,
  }) => _ch.setMethodCallHandler(
    onChanged == null
        ? null
        : (call) async {
            switch (call.method) {
              case 'changed':
                final m = call.arguments as Map;
                onChanged(m['inPip'] == true, m['closed'] == true);
              case 'action':
                onAction?.call(call.arguments as String);
            }
          },
  );
}
