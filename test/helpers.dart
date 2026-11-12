import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:kotohori/features/dictionary/data/db.dart';
import 'package:kotohori/features/dictionary/data/dictionary_repo.dart';
import 'package:kotohori/features/dictionary/import/importer.dart';
import 'package:path/path.dart' as p;

/// Zips `test/fixtures/<name>` into [outDir]; [replace] overrides file contents by name.
String zipFixture(
  String name,
  Directory outDir, {
  Map<String, String> replace = const {},
  String? zipName,
}) {
  final src = Directory(p.join('test', 'fixtures', name));
  final archive = Archive();
  for (final f in src.listSync(recursive: true).whereType<File>()) {
    final rel = p.relative(f.path, from: src.path).replaceAll(r'\', '/');
    final over = replace[rel];
    archive.add(
      over != null
          ? ArchiveFile.string(rel, over)
          : ArchiveFile.bytes(rel, f.readAsBytesSync()),
    );
  }
  final out = p.join(outDir.path, zipName ?? '$name.zip');
  File(out).writeAsBytesSync(ZipEncoder().encodeBytes(archive));
  return out;
}

class TestEnv {
  TestEnv._(this.tmp, this.db, this.repo);
  final Directory tmp;
  final AppDb db;
  final DictionaryRepo repo;

  String get mediaRoot => p.join(tmp.path, 'media');

  static Future<TestEnv> create() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final tmp = Directory.systemTemp.createTempSync('kotohori_test');
    final db = AppDb(NativeDatabase.memory());
    return TestEnv._(
      tmp,
      db,
      DictionaryRepo(db, mediaRoot: p.join(tmp.path, 'media')),
    );
  }

  Future<ImportResult> import(
    String fixture, {
    Map<String, String> replace = const {},
    String? zipName,
  }) => importDictionaryZip(
    db,
    zipFixture(fixture, tmp, replace: replace, zipName: zipName),
    mediaRoot: mediaRoot,
  );

  Future<void> dispose() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  }
}
