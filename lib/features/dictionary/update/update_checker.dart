import 'dart:convert';

import 'package:dio/dio.dart';

import '../data/db.dart';
import '../import/index_json.dart';

class DictionaryUpdate {
  DictionaryUpdate(this.dictionary, this.latestRevision, this.downloadUrl);
  final Dictionary dictionary;
  final String latestRevision;
  final String downloadUrl;
}

class UpdateCheckResult {
  UpdateCheckResult(this.updates, this.failures);
  final List<DictionaryUpdate> updates;

  /// Dictionary title → error message.
  final Map<String, String> failures;
}

/// Fetches each updatable dictionary's remote `indexUrl` and compares revisions.
/// Installing an update is a normal import of [DictionaryUpdate.downloadUrl]:
/// the importer replaces the old revision and keeps enabled state + priority.
Future<UpdateCheckResult> checkForUpdates(
  Dio dio,
  List<Dictionary> installed,
) async {
  final updates = <DictionaryUpdate>[];
  final failures = <String, String>{};
  await Future.wait([
    for (final d in installed)
      if (d.isUpdatable && d.indexUrl != null)
        () async {
          try {
            final r = await dio.get<String>(
              d.indexUrl!,
              options: Options(responseType: ResponseType.plain),
            );
            final remote = jsonDecode(r.data!) as Map;
            final revision = remote['revision'];
            final url = remote['downloadUrl'] as String? ?? d.downloadUrl;
            if (revision is! String || url == null) {
              throw const FormatException(
                'remote index has no revision/downloadUrl',
              );
            }
            if (compareRevisions(revision, d.revision) > 0) {
              updates.add(DictionaryUpdate(d, revision, url));
            }
          } catch (e) {
            failures[d.title] = e is DioException
                ? (e.message ?? e.type.name)
                : '$e';
          }
        }(),
  ]);
  return UpdateCheckResult(updates, failures);
}
