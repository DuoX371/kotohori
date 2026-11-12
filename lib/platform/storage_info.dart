import 'package:flutter/services.dart';

abstract interface class StorageInfo {
  /// Free bytes on the volume holding [path]; null if unknown.
  Future<int?> freeBytes(String path);
}

/// Android: `StatFs` via MainActivity.kt. Other platforms report unknown
/// (an iOS adapter can implement the same channel later).
class MethodChannelStorageInfo implements StorageInfo {
  static const _channel = MethodChannel('kotohori/storage');

  @override
  Future<int?> freeBytes(String path) async {
    try {
      return await _channel.invokeMethod<int>('freeBytes', {'path': path});
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
