import 'package:flutter/services.dart';

/// A file opened in place through Android's document picker (Documents.kt).
typedef PickedDoc = ({String uri, String name, int size});

abstract final class Documents {
  static const _ch = MethodChannel('kotohori/documents');

  /// [keep]: URIs whose read grant must survive (all other old grants are released).
  static Future<PickedDoc?> pick({
    required List<String> mimeTypes,
    Iterable<String?> keep = const [],
  }) async {
    final m = await _ch.invokeMapMethod<String, Object?>('pick', {
      'mimeTypes': mimeTypes,
      'keep': keep.nonNulls.toList(),
    });
    if (m == null) return null;
    return (
      uri: m['uri']! as String,
      name: m['name']! as String,
      size: (m['size']! as num).toInt(),
    );
  }

  /// Opens [uri] read-only for in-process reads (see FdByteSource); call [closeFd] after.
  static Future<({int fd, int size})> openFd(String uri) async {
    final m = (await _ch.invokeMapMethod<String, Object?>('openFd', {
      'uri': uri,
    }))!;
    return (fd: (m['fd']! as num).toInt(), size: (m['size']! as num).toInt());
  }

  static Future<void> closeFd(int fd) =>
      _ch.invokeMethod('closeFd', {'fd': fd});

  static Future<bool> canOpen(String uri) async =>
      await _ch.invokeMethod<bool>('canOpen', {'uri': uri}) ?? false;

  static Future<Uint8List> read(String uri) async =>
      (await _ch.invokeMethod<Uint8List>('read', {'uri': uri}))!;
}
