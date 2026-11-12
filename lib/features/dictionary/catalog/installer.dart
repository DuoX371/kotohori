import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../core/errors.dart';
import '../../../platform/storage_info.dart';
import '../import/importer.dart';

sealed class InstallState {
  const InstallState();
}

class Downloading extends InstallState {
  const Downloading(this.received, this.total);
  final int received;
  final int total; // -1 if unknown
}

class Importing extends InstallState {
  const Importing(this.progress);
  final ImportProgress progress;
}

class Installed extends InstallState {
  const Installed(this.result);
  final ImportResult result;
}

/// Zip + extracted JSON + DB rows + indexes, relative to the zip size.
const storageFactor = 4;

/// Download from the original URL → import in a worker isolate, as one stream.
/// Cancelling the subscription cancels whichever step is running.
class DictionaryInstaller {
  DictionaryInstaller({
    required this.dio,
    required this.storage,
    required this.tempDir,
    required this.dbPath,
    required this.mediaRoot,
  });

  final Dio dio;
  final StorageInfo storage;
  final String tempDir;
  final String dbPath;
  final String mediaRoot;

  Stream<InstallState> install(String url) {
    final cancel = CancelToken();
    StreamSubscription<InstallState>? importSub;
    late final StreamController<InstallState> ctrl;
    final zip = p.join(
      tempDir,
      'dl_${DateTime.now().microsecondsSinceEpoch}.zip',
    );

    Future<void> run() async {
      try {
        var checked = false;
        await dio.download(
          url,
          zip,
          cancelToken: cancel,
          onReceiveProgress: (rec, total) {
            if (!checked && total > 0) {
              checked = true;
              storage.freeBytes(tempDir).then((free) {
                if (free != null && free < total * storageFactor) {
                  cancel.cancel(
                    InsufficientStorageException(total * storageFactor, free),
                  );
                }
              });
            }
            if (!ctrl.isClosed) ctrl.add(Downloading(rec, total));
          },
        );
        importSub = importFile(zip).listen(
          ctrl.add,
          onError: ctrl.addError,
          onDone: () {
            _deleteQuietly(zip);
            ctrl.close();
          },
        );
      } on DioException catch (e) {
        _deleteQuietly(zip);
        if (!ctrl.isClosed) {
          ctrl.addError(
            e.error is DictionaryException
                ? e.error!
                : DictionaryException(_dioMessage(e)),
          );
          await ctrl.close();
        }
      }
    }

    ctrl = StreamController<InstallState>(
      onListen: run,
      onCancel: () async {
        cancel.cancel();
        await importSub?.cancel();
        _deleteQuietly(zip);
      },
    );
    return ctrl.stream;
  }

  /// Imports a local zip (file picker or downloaded) in a worker isolate.
  Stream<InstallState> importFile(String zipPath) {
    late final StreamController<InstallState> ctrl;
    StreamSubscription<ImportProgress>? sub;
    ctrl = StreamController<InstallState>(
      onListen: () {
        sub =
            importInIsolate(
              dbPath: dbPath,
              zipPath: zipPath,
              mediaRoot: mediaRoot,
              onDone: (r) => ctrl.add(Installed(r)),
            ).listen(
              (pr) => ctrl.add(Importing(pr)),
              onError: ctrl.addError,
              onDone: ctrl.close,
            );
      },
      onCancel: () => sub?.cancel(),
    );
    return ctrl.stream;
  }

  static String _dioMessage(DioException e) => switch (e.type) {
    DioExceptionType.cancel => 'Download cancelled',
    DioExceptionType.badResponse =>
      'Download failed: HTTP ${e.response?.statusCode}',
    _ => 'Download failed: ${e.message ?? e.type.name}',
  };
}

void _deleteQuietly(String path) {
  try {
    File(path).deleteSync();
  } catch (_) {}
}
