import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../platform/storage_info.dart';
import '../catalog/catalog.dart';
import '../catalog/installer.dart';
import '../data/db.dart';
import '../data/dictionary_repo.dart';
import '../lookup/lookup.dart';
import '../render/lookup_html.dart';

class AppPaths {
  AppPaths({
    required this.dbPath,
    required this.mediaRoot,
    required this.tempDir,
  });
  final String dbPath;
  final String mediaRoot;
  final String tempDir;
}

// Overridden in main().
final appPathsProvider = Provider<AppPaths>((_) => throw UnimplementedError());
final dbProvider = Provider<AppDb>((_) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

final dioProvider = Provider((_) => Dio());
final repoProvider = Provider((ref) {
  final paths = ref.watch(appPathsProvider);
  return DictionaryRepo(
    ref.watch(dbProvider),
    mediaRoot: paths.mediaRoot,
    dbPath: paths.dbPath,
  );
});
final installedProvider = StreamProvider(
  (ref) => ref.watch(repoProvider).watchInstalled(),
);
final lookupProvider = Provider((ref) => Lookup(ref.watch(repoProvider)));
final htmlBuilderProvider = Provider(
  (ref) => LookupHtmlBuilder(mediaRoot: ref.watch(appPathsProvider).mediaRoot),
);
final installerProvider = Provider((ref) {
  final paths = ref.watch(appPathsProvider);
  return DictionaryInstaller(
    dio: ref.watch(dioProvider),
    storage: MethodChannelStorageInfo(),
    tempDir: paths.tempDir,
    dbPath: paths.dbPath,
    mediaRoot: paths.mediaRoot,
  );
});

const _catalogUrlKey = 'catalogUrl';

class CatalogUrl extends Notifier<String> {
  @override
  String build() => ref.watch(prefsProvider).getString(_catalogUrlKey) ?? '';

  Future<void> set(String url) async {
    await ref.read(prefsProvider).setString(_catalogUrlKey, url.trim());
    state = url.trim();
  }
}

final catalogUrlProvider = NotifierProvider<CatalogUrl, String>(CatalogUrl.new);
final catalogProvider = FutureProvider(
  (ref) => loadCatalog(
    ref.watch(dioProvider),
    ref.watch(catalogUrlProvider),
    () => rootBundle.loadString('assets/catalog.json'),
  ),
);

/// Catalog item id → installed dictionary title, so the Recommended screen
/// can show "Installed" (catalog names differ from index.json titles).
class CatalogInstalls extends Notifier<Map<String, String>> {
  static const _prefix = 'catalogInstall.';
  @override
  Map<String, String> build() {
    final prefs = ref.watch(prefsProvider);
    return {
      for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix)))
        k.substring(_prefix.length): prefs.getString(k)!,
    };
  }

  Future<void> record(String itemId, String title) async {
    await ref.read(prefsProvider).setString('$_prefix$itemId', title);
    state = {...state, itemId: title};
  }
}

final catalogInstallsProvider =
    NotifierProvider<CatalogInstalls, Map<String, String>>(CatalogInstalls.new);

class Job {
  const Job({this.state, this.error, this.running = false});
  final InstallState? state;
  final Object? error;
  final bool running;
}

/// Running/finished install jobs keyed by catalog id, `update:<dictId>` or `import`.
class Jobs extends Notifier<Map<String, Job>> {
  final _subs = <String, StreamSubscription<InstallState>>{};
  final _done = <String, Completer<Job>>{};

  @override
  Map<String, Job> build() {
    ref.onDispose(() {
      for (final s in _subs.values) {
        s.cancel();
      }
    });
    return {};
  }

  /// Completes with the final job (state [Installed], or an error) when the stream ends.
  Future<Job> start(String key, Stream<InstallState> stream) {
    final done = _done[key] = Completer<Job>();
    _set(key, const Job(running: true));
    _subs[key] = stream.listen(
      (s) {
        _set(key, Job(state: s, running: true));
        if (s is Installed) ref.read(repoProvider).notifyExternalChange();
      },
      onError: (Object e) {
        _subs.remove(key);
        _set(key, Job(error: e));
        if (!done.isCompleted) done.complete(state[key]);
      },
      onDone: () {
        _subs.remove(key);
        _set(key, Job(state: state[key]?.state, error: state[key]?.error));
        if (!done.isCompleted) done.complete(state[key]);
      },
    );
    return done.future;
  }

  Future<void> cancel(String key) async {
    await _subs.remove(key)?.cancel();
    _set(key, const Job(error: 'Cancelled'));
    final d = _done.remove(key);
    if (d != null && !d.isCompleted) d.complete(state[key]);
  }

  void clear(String key) => state = {...state}..remove(key);

  void _set(String key, Job job) => state = {...state, key: job};
}

final jobsProvider = NotifierProvider<Jobs, Map<String, Job>>(Jobs.new);
