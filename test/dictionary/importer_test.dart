import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/core/errors.dart';
import 'package:kotohori/features/dictionary/data/db.dart';
import 'package:kotohori/features/dictionary/import/importer.dart';
import 'package:kotohori/features/dictionary/import/index_json.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  Future<int> count(String table) async =>
      (await env.db.customSelect('SELECT COUNT(*) c FROM $table').getSingle())
          .read<int>('c');

  test('imports all banks, metadata, styles and media', () async {
    final r = await env.import('mini_a');
    final d = (await env.repo.installed()).single;
    expect(d.title, 'Mini A');
    expect(d.revision, '2025.01.01.0');
    expect(d.isUpdatable, isTrue);
    expect(d.indexUrl, 'https://example.test/mini_a/index.json');
    expect(d.stylesCss, contains('data-sc-content'));
    expect(await count('terms'), 10);
    expect(await count('term_meta'), 3);
    expect(await count('tags'), 2);
    expect(await count('kanji'), 1);
    expect(
      File(p.join(env.mediaRoot, '${r.dictId}', 'img', 'dot.png')).existsSync(),
      isTrue,
    );
    final glossary = (await env.db.select(env.db.terms).get()).first.glossary;
    expect(jsonDecode(glossary), ['to eat']);
  });

  test('reports progress ending at 1', () async {
    final events = <ImportProgress>[];
    await importDictionaryZip(
      env.db,
      zipFixture('mini_a', env.tmp),
      mediaRoot: env.mediaRoot,
      onProgress: events.add,
    );
    expect(events.last.fraction, 1);
  });

  test('same title + revision is rejected, not duplicated', () async {
    await env.import('mini_a');
    await expectLater(
      env.import('mini_a', zipName: 'again.zip'),
      throwsA(isA<DuplicateDictionaryException>()),
    );
    expect((await env.repo.installed()), hasLength(1));
    expect(await count('terms'), 10);
  });

  test(
    'same title + other revision replaces it, keeping enabled + priority',
    () async {
      await env.import('mini_b');
      await env.import('mini_a');
      final old = (await env.repo.installed()).firstWhere(
        (d) => d.title == 'Mini A',
      );
      await env.repo.setEnabled(old.id, false);
      await env.repo.move(old.id, -1); // Mini A first

      final index = jsonDecode(
        File('test/fixtures/mini_a/index.json').readAsStringSync(),
      ) as Map;
      final r = await env.import(
        'mini_a',
        zipName: 'a2.zip',
        replace: {
          'index.json': jsonEncode({...index, 'revision': '2025.02.01.0'}),
        },
      );
      expect(r.replacedRevision, '2025.01.01.0');

      final list = await env.repo.installed();
      expect(list.map((d) => d.title), ['Mini A', 'Mini B']);
      expect(list.first.revision, '2025.02.01.0');
      expect(list.first.enabled, isFalse);
      expect(await count('terms'), 10 + 2); // old Mini A rows purged
      expect(
        Directory(p.join(env.mediaRoot, '${old.id}')).existsSync(),
        isFalse,
      );
    },
  );

  test('delete removes the dictionary and purges its rows', () async {
    await env.import('mini_a');
    await env.import('mini_b');
    final a = (await env.repo.installed()).firstWhere(
      (d) => d.title == 'Mini A',
    );
    await env.repo.delete(a.id);
    expect((await env.repo.installed()).map((d) => d.title), ['Mini B']);
    expect(await count('terms'), 2);
    expect(
      await count('term_meta') + await count('tags') + await count('kanji'),
      0,
    );
    await env.repo.deleteAll();
    expect(await count('terms'), 0);
  });

  test('invalid zips are rejected and leave nothing behind', () async {
    final notZip = File(p.join(env.tmp.path, 'x.zip'))
      ..writeAsStringSync('nope');
    await expectLater(
      importDictionaryZip(env.db, notZip.path, mediaRoot: env.mediaRoot),
      throwsA(isA<InvalidDictionaryException>()),
    );
    await expectLater(
      env.import(
        'mini_a',
        zipName: 'v2.zip',
        replace: {'index.json': '{"title":"X","revision":"1","format":2}'},
      ),
      throwsA(isA<InvalidDictionaryException>()),
    );
    await expectLater(
      env.import(
        'mini_a',
        zipName: 'bad.zip',
        replace: {'term_bank_1.json': '[oops'},
      ),
      throwsA(isA<InvalidDictionaryException>()),
    );
    expect(await env.db.select(env.db.dictionaries).get(), isEmpty);
    expect(await count('terms'), 0);
  });

  test('cancellation rolls back the partial import', () async {
    await expectLater(
      importDictionaryZip(
        env.db,
        zipFixture('mini_a', env.tmp),
        mediaRoot: env.mediaRoot,
        isCancelled: () => true,
      ),
      throwsA(isA<ImportCancelledException>()),
    );
    expect(await env.db.select(env.db.dictionaries).get(), isEmpty);
    expect(await count('terms'), 0);
  });

  test(
    'importInIsolate: worker connection on a file DB, progress streamed back',
    () async {
      final dbPath = p.join(env.tmp.path, 'file.sqlite');
      final main = AppDb.openSync(File(dbPath));
      await main.select(main.dictionaries).get(); // create schema
      ImportResult? result;
      final events = await importInIsolate(
        dbPath: dbPath,
        zipPath: zipFixture('mini_a', env.tmp),
        mediaRoot: env.mediaRoot,
        onDone: (r) => result = r,
      ).toList();
      expect(events.last.fraction, 1);
      expect(result?.title, 'Mini A');
      expect((await main.select(main.terms).get()), hasLength(10));

      // Errors cross the isolate boundary as DictionaryExceptions.
      await expectLater(
        importInIsolate(
          dbPath: dbPath,
          zipPath: zipFixture('mini_a', env.tmp, zipName: 'dup.zip'),
          mediaRoot: env.mediaRoot,
          onDone: (_) {},
        ).drain<void>(),
        throwsA(isA<DuplicateDictionaryException>()),
      );
      await main.close();
    },
  );

  test('compareRevisions', () {
    expect(compareRevisions('2025.03.04.0', '2025.03.04.0'), 0);
    expect(compareRevisions('2025.03.10.0', '2025.03.04.0'), greaterThan(0));
    expect(compareRevisions('2025.3.4', '2025.03.04.1'), lessThan(0));
    expect(compareRevisions('10', '9'), greaterThan(0));
  });
}
