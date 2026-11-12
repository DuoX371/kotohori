import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/dictionary/data/db.dart';
import 'package:kotohori/features/dictionary/import/importer.dart';
import 'package:kotohori/features/dictionary/lookup/lookup.dart';
import 'package:kotohori/features/dictionary/data/dictionary_repo.dart';
import 'package:kotohori/features/dictionary/render/lookup_html.dart';
import 'package:path/path.dart' as p;

/// Opt-in benchmark: `JITENDEX_ZIP=/path/jitendex-yomitan.zip flutter test test/dictionary/large_import_test.dart`
void main() {
  final zip = Platform.environment['JITENDEX_ZIP'];
  test(
    'imports a real large dictionary through the isolate path',
    () async {
      final tmp = Directory.systemTemp.createTempSync('kotohori_bench');
      final dbPath = p.join(tmp.path, 'bench.sqlite');
      final db = AppDb.openSync(File(dbPath));
      await db.select(db.dictionaries).get();
      final sw = Stopwatch()..start();
      var lastRss = 0;
      await importInIsolate(
        dbPath: dbPath,
        zipPath: zip!,
        mediaRoot: p.join(tmp.path, 'm'),
        onDone: (_) {},
      ).forEach(
        (e) => lastRss = ProcessInfo.currentRss > lastRss
            ? ProcessInfo.currentRss
            : lastRss,
      );
      final terms =
          (await db.customSelect('SELECT COUNT(*) c FROM terms').getSingle())
              .read<int>('c');
      // ignore: avoid_print
      print(
        'import: ${sw.elapsed.inSeconds}s, $terms terms, peak RSS ~${ProcessInfo.maxRss >> 20} MB, '
        'db ${File(dbPath).lengthSync() >> 20} MB',
      );

      final lookup = Lookup(
        DictionaryRepo(db, mediaRoot: p.join(tmp.path, 'm')),
      );
      for (final q in ['食べなかった', '日本語を勉強しています', 'してしまった']) {
        sw.reset();
        final r = await lookup.lookup(q, 0);
        // ignore: avoid_print
        print(
          'lookup $q: ${sw.elapsedMilliseconds} ms → ${r.groups.first.expression} (${r.groups.length} groups)',
        );
        final html = LookupHtmlBuilder(mediaRoot: p.join(tmp.path, 'm'))
            .page(r);
        expect(html, isNot(contains('<script')));
        if (q == '食べなかった') {
          File(p.join(Directory.systemTemp.path, 'kotohori_sample.html'))
              .writeAsStringSync(html);
        }
      }
      expect(terms, greaterThan(100000));
      await db.close();
      tmp.deleteSync(recursive: true);
    },
    skip: zip == null ? 'set JITENDEX_ZIP to run' : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
