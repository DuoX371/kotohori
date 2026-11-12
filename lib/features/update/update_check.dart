import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictionary/ui/providers.dart' show dioProvider, prefsProvider;

/// Where releases are published (GitHub Releases).
const releasesRepo = 'DuoX371/kotohori';

/// The installed app's version name, e.g. "0.1.0" (from Android, see MainActivity).
final appVersionProvider = FutureProvider<String>(
  (_) async =>
      await const MethodChannel('kotohori/app')
          .invokeMethod<String>('version') ??
      '?',
);

/// A published release newer than the installed app.
typedef AppRelease = ({String version, String url});

/// Compares "1.2.10" with "v1.2.9" numerically (a leading "v" and anything after
/// "-" or "+" are ignored; missing parts count as 0). <0: a is older.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .replaceFirst(RegExp('^v'), '')
      .split(RegExp('[-+]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// The latest GitHub release if it's newer than [installed]; null when up to date
/// or nothing has been released. Throws [DioException] when offline.
Future<AppRelease?> newerRelease(Dio dio, String installed) async {
  try {
    final r = await dio.get<Map<String, Object?>>(
      'https://api.github.com/repos/$releasesRepo/releases/latest',
      options: Options(headers: {'Accept': 'application/vnd.github+json'}),
    );
    final tag = r.data?['tag_name'] as String?;
    final url = r.data?['html_url'] as String?;
    if (tag == null || url == null) return null;
    return compareVersions(tag, installed) > 0
        ? (version: tag.replaceFirst(RegExp('^v'), ''), url: url)
        : null;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null; // no releases yet
    rethrow;
  }
}

/// Checks the installed version against the latest release.
final updateCheckProvider = Provider(
  (ref) =>
      () async => newerRelease(
        ref.read(dioProvider),
        await ref.read(appVersionProvider.future),
      ),
);

/// "Check for updates when Kotohori starts" (on by default).
class CheckOnLaunch extends Notifier<bool> {
  static const _key = 'updates.checkOnLaunch';

  @override
  bool build() => ref.watch(prefsProvider).getBool(_key) ?? true;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(prefsProvider).setBool(_key, on);
  }
}

final checkOnLaunchProvider = NotifierProvider<CheckOnLaunch, bool>(
  CheckOnLaunch.new,
);

/// A newer release found by the launch check (shown under the bell).
class AvailableUpdate extends Notifier<AppRelease?> {
  @override
  AppRelease? build() => null;

  void set(AppRelease? r) => state = r;
}

final availableUpdateProvider = NotifierProvider<AvailableUpdate, AppRelease?>(
  AvailableUpdate.new,
);
