import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/data/db.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('finishes a schema creation that was interrupted earlier', () async {
    // Two connections racing on a fresh file left tables and indexes behind
    // without the schema version: every later open re-ran creation and failed.
    final dir = Directory.systemTemp.createTempSync('kotohori_db');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/k.sqlite');

    final first = AppDb.openSync(file);
    await first.customSelect('SELECT 1').get();
    await first.close();
    sqlite3.open(file.path)
      ..execute('PRAGMA user_version = 0')
      ..close();

    final again = AppDb.openSync(file);
    addTearDown(again.close);
    expect(await again.select(again.dictionaries).get(), isEmpty);
  });
}
