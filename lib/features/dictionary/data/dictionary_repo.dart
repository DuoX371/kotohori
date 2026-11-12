import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../import/importer.dart';
import 'db.dart';

class DictionaryRepo {
  /// [dbPath] null (tests, in-memory DB) → purges run on [db] directly.
  DictionaryRepo(this.db, {required this.mediaRoot, this.dbPath});

  final AppDb db;
  final String mediaRoot;
  final String? dbPath;

  SimpleSelectStatement<$DictionariesTable, Dictionary> get _installed =>
      db.select(db.dictionaries)
        ..where((d) => d.importedAt.isNotNull())
        ..orderBy([(d) => OrderingTerm(expression: d.priority)]);

  Stream<List<Dictionary>> watchInstalled() => _installed.watch();
  Future<List<Dictionary>> installed() => _installed.get();

  /// Enabled dictionaries, highest priority (lowest number) first.
  Future<List<Dictionary>> enabled() =>
      (_installed..where((d) => d.enabled.equals(true))).get();

  Future<void> setEnabled(int id, bool enabled) =>
      (db.update(db.dictionaries)..where((d) => d.id.equals(id))).write(
        DictionariesCompanion(enabled: Value(enabled)),
      );

  Future<void> setAllEnabled(bool enabled) => db
      .update(db.dictionaries)
      .write(DictionariesCompanion(enabled: Value(enabled)));

  /// Moves a dictionary up (delta < 0) or down; renumbers priorities 0..n-1.
  Future<void> move(int id, int delta) => db.transaction(() async {
    final list = await installed();
    final i = list.indexWhere((d) => d.id == id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= list.length) return;
    list.insert(j, list.removeAt(i));
    for (var k = 0; k < list.length; k++) {
      if (list[k].priority != k) {
        await (db.update(db.dictionaries)
              ..where((d) => d.id.equals(list[k].id)))
            .write(DictionariesCompanion(priority: Value(k)));
      }
    }
  });

  /// Removes the dictionary row immediately (hidden from lists and lookups),
  /// then purges its data in the background.
  Future<void> delete(int id) async {
    await db.dictionaries.deleteWhere((d) => d.id.equals(id));
    await purge();
  }

  Future<void> deleteAll() async {
    await db.delete(db.dictionaries).go();
    await purge();
  }

  Future<void> purge({bool includeUnfinished = false}) async {
    final path = dbPath, media = mediaRoot;
    if (path == null) {
      return purgeOrphans(
        db,
        mediaRoot: media,
        includeUnfinished: includeUnfinished,
      );
    }
    await Isolate.run(() async {
      final worker = AppDb.openSync(File(path));
      try {
        await purgeOrphans(
          worker,
          mediaRoot: media,
          includeUnfinished: includeUnfinished,
        );
      } finally {
        await worker.close();
      }
    });
  }

  /// Call after a worker isolate changed the DB so stream queries refresh.
  void notifyExternalChange() =>
      db.notifyUpdates({TableUpdate.onTable(db.dictionaries)});
}
