import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/errors.dart';
import '../data/db.dart';
import 'index_json.dart';

class ImportProgress {
  const ImportProgress(this.message, this.fraction);
  final String message;
  final double fraction; // 0..1
}

class ImportCancelledException extends DictionaryException {
  ImportCancelledException() : super('Import cancelled');
}

class ImportResult {
  const ImportResult(
    this.dictId,
    this.title,
    this.revision, {
    this.replacedRevision,
  });
  final int dictId;
  final String title;
  final String revision;

  /// Set when an older/other revision with the same title was replaced.
  final String? replacedRevision;
}

const _batchSize = 5000;
final _bankRe = RegExp(
  r'^(term|term_meta|kanji|kanji_meta|tag)_bank_\d+\.json$',
);

/// Imports a Yomitan v3 zip. Runs on whatever isolate calls it; use
/// [importInIsolate] from the UI.
///
/// Same title + same revision → [DuplicateDictionaryException].
/// Same title + other revision → replaces it, keeping enabled + priority.
Future<ImportResult> importDictionaryZip(
  AppDb db,
  String zipPath, {
  required String mediaRoot,
  void Function(ImportProgress)? onProgress,
  bool Function()? isCancelled,
}) async {
  final input = InputFileStream(zipPath);
  int? dictId;
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (e) {
      throw InvalidDictionaryException('Not a valid zip file');
    }
    final files = {
      for (final f in archive.files)
        if (f.isFile) f.name: f,
    };

    final indexFile = files['index.json'];
    if (indexFile == null) {
      throw InvalidDictionaryException('index.json not found in zip');
    }
    final index = DictionaryIndex.fromJson(_decode(indexFile));

    final existing = await (db.select(
      db.dictionaries,
    )..where((d) => d.title.equals(index.title))).get();
    if (existing.any(
      (d) => d.revision == index.revision && d.importedAt != null,
    )) {
      throw DuplicateDictionaryException(index.title, index.revision);
    }
    final old = existing.where((d) => d.importedAt != null).firstOrNull;
    // Leftover half-import of this title (e.g. app killed mid-import).
    await db.dictionaries.deleteWhere(
      (d) => d.title.equals(index.title) & d.importedAt.isNull(),
    );

    final css = files['styles.css'];
    final maxPriority =
        await (db.selectOnly(db.dictionaries)
              ..addColumns([db.dictionaries.priority.max()]))
            .map((r) => r.read(db.dictionaries.priority.max()))
            .getSingle();
    dictId = await db
        .into(db.dictionaries)
        .insert(
          DictionariesCompanion.insert(
            title: index.title,
            revision: index.revision,
            format: index.format,
            author: Value(index.author),
            attribution: Value(index.attribution),
            description: Value(index.description),
            sourceLanguage: Value(index.sourceLanguage),
            isUpdatable: Value(index.isUpdatable),
            indexUrl: Value(index.indexUrl),
            downloadUrl: Value(index.downloadUrl),
            stylesCss: Value(
              css == null ? '' : utf8.decode(css.content, allowMalformed: true),
            ),
            enabled: Value(old?.enabled ?? true),
            priority: Value(old?.priority ?? (maxPriority ?? -1) + 1),
          ),
        );
    css?.clear();

    final banks = files.keys.where((n) => _bankRe.hasMatch(n)).toList()..sort();
    final media = files.keys
        .where(
          (n) => n != 'index.json' && n != 'styles.css' && !_bankRe.hasMatch(n),
        )
        .toList();
    final total = banks.length + (media.isEmpty ? 0 : 1);
    var rows = 0;

    for (var i = 0; i < banks.length; i++) {
      if (isCancelled?.call() ?? false) throw ImportCancelledException();
      final name = banks[i];
      onProgress?.call(
        ImportProgress('Importing $name ($rows entries)', i / total),
      );
      final file = files[name]!;
      final data = _decode(file);
      file.clear(); // free decompressed bytes before the next bank
      if (data is! List) {
        throw InvalidDictionaryException('$name is not an array');
      }
      final kind = _bankRe.firstMatch(name)!.group(1)!;
      for (var start = 0; start < data.length; start += _batchSize) {
        await Future<void>.delayed(
          Duration.zero,
        ); // let the cancel message through
        if (isCancelled?.call() ?? false) throw ImportCancelledException();
        final chunk = data.sublist(
          start,
          (start + _batchSize).clamp(0, data.length),
        );
        await db.batch((b) => _insertChunk(db, b, kind, dictId!, chunk, name));
        rows += chunk.length;
      }
    }

    if (media.isNotEmpty) {
      onProgress?.call(
        ImportProgress(
          'Extracting ${media.length} media files',
          banks.length / total,
        ),
      );
      final root = p.normalize(p.absolute(mediaRoot, '$dictId'));
      for (final name in media) {
        final out = p.normalize(p.join(root, name));
        if (!p.isWithin(root, out)) continue; // zip-slip guard
        Directory(p.dirname(out)).createSync(recursive: true);
        final os = OutputFileStream(out);
        files[name]!.writeContent(os);
        os.closeSync();
      }
    }

    await db.transaction(() async {
      await (db.update(db.dictionaries)..where((d) => d.id.equals(dictId!)))
          .write(DictionariesCompanion(importedAt: Value(DateTime.now())));
      if (old != null) {
        await db.dictionaries.deleteWhere((d) => d.id.equals(old.id));
      }
    });
    if (old != null) await purgeOrphans(db, mediaRoot: mediaRoot);
    onProgress?.call(
      ImportProgress('Imported ${index.title} ($rows entries)', 1),
    );
    return ImportResult(
      dictId,
      index.title,
      index.revision,
      replacedRevision: old?.revision,
    );
  } catch (_) {
    if (dictId != null) {
      final id = dictId;
      await db.dictionaries.deleteWhere((d) => d.id.equals(id));
      await purgeOrphans(db, mediaRoot: mediaRoot);
    }
    rethrow;
  } finally {
    await input.close();
  }
}

Object? _decode(ArchiveFile f) {
  try {
    return jsonDecode(utf8.decode(f.content, allowMalformed: true));
  } on FormatException catch (e) {
    throw InvalidDictionaryException('${f.name}: invalid JSON (${e.message})');
  }
}

String _str(Object? v) => v is String ? v : '';
int _int(Object? v) => v is num ? v.toInt() : 0;

void _insertChunk(
  AppDb db,
  Batch b,
  String kind,
  int dictId,
  List<dynamic> chunk,
  String bank,
) {
  for (final row in chunk) {
    if (row is! List || row.isEmpty) {
      throw InvalidDictionaryException('$bank: malformed row');
    }
    switch (kind) {
      case 'term':
        final expression = _str(row[0]);
        final reading = _str(row.elementAtOrNull(1));
        b.insert(
          db.terms,
          TermsCompanion.insert(
            dictId: dictId,
            expression: expression,
            reading: reading.isEmpty ? expression : reading,
            definitionTags: _str(row.elementAtOrNull(2)),
            rules: _str(row.elementAtOrNull(3)),
            score: _int(row.elementAtOrNull(4)),
            glossary: jsonEncode(row.elementAtOrNull(5) ?? const []),
            sequence: Value(
              row.elementAtOrNull(6) is num ? (row[6] as num).toInt() : null,
            ),
            termTags: _str(row.elementAtOrNull(7)),
          ),
        );
      case 'term_meta':
        b.insert(
          db.termMeta,
          TermMetaCompanion.insert(
            dictId: dictId,
            expression: _str(row[0]),
            mode: _str(row.elementAtOrNull(1)),
            data: jsonEncode(row.elementAtOrNull(2)),
          ),
        );
      case 'kanji':
        b.insert(
          db.kanji,
          KanjiCompanion.insert(
            dictId: dictId,
            character: _str(row[0]),
            onyomi: _str(row.elementAtOrNull(1)),
            kunyomi: _str(row.elementAtOrNull(2)),
            tags: _str(row.elementAtOrNull(3)),
            meanings: jsonEncode(row.elementAtOrNull(4) ?? const []),
            stats: jsonEncode(row.elementAtOrNull(5) ?? const {}),
          ),
        );
      case 'kanji_meta':
        b.insert(
          db.kanjiMeta,
          KanjiMetaCompanion.insert(
            dictId: dictId,
            character: _str(row[0]),
            mode: _str(row.elementAtOrNull(1)),
            data: jsonEncode(row.elementAtOrNull(2)),
          ),
        );
      case 'tag':
        b.insert(
          db.tags,
          TagsCompanion.insert(
            dictId: dictId,
            name: _str(row[0]),
            category: _str(row.elementAtOrNull(1)),
            sortOrder: _int(row.elementAtOrNull(2)),
            notes: _str(row.elementAtOrNull(3)),
            score: _int(row.elementAtOrNull(4)),
          ),
        );
    }
  }
}

/// Deletes rows (in batches) and media whose dictionary row no longer exists,
/// plus dictionaries left half-imported by a crash. Safe to re-run.
Future<void> purgeOrphans(
  AppDb db, {
  required String mediaRoot,
  bool includeUnfinished = false,
}) async {
  if (includeUnfinished) {
    await db.dictionaries.deleteWhere((d) => d.importedAt.isNull());
  }
  final live = (await db.select(db.dictionaries).get())
      .map((d) => d.id)
      .toSet();
  for (final t in dictDataTables) {
    var after = -1;
    while (true) {
      // Index seek per distinct dict_id instead of a full-table scan.
      final r = await db
          .customSelect(
            'SELECT dict_id FROM $t WHERE dict_id > ? ORDER BY dict_id LIMIT 1',
            variables: [Variable.withInt(after)],
          )
          .getSingleOrNull();
      if (r == null) break;
      after = r.read<int>('dict_id');
      if (live.contains(after)) continue;
      while (await db.customUpdate(
            'DELETE FROM $t WHERE rowid IN (SELECT rowid FROM $t WHERE dict_id = ? LIMIT 10000)',
            variables: [Variable.withInt(after)],
            updateKind: UpdateKind.delete,
          ) >
          0) {}
    }
  }
  final dir = Directory(mediaRoot);
  if (dir.existsSync()) {
    for (final e in dir.listSync().whereType<Directory>()) {
      final id = int.tryParse(p.basename(e.path));
      if (id != null && !live.contains(id)) e.deleteSync(recursive: true);
    }
  }
}

/// Runs [importDictionaryZip] in a worker isolate with its own SQLite
/// connection. Cancelling the subscription asks the worker to stop between
/// batches; it then rolls back its partial dictionary.
Stream<ImportProgress> importInIsolate({
  required String dbPath,
  required String zipPath,
  required String mediaRoot,
  required void Function(ImportResult) onDone,
}) {
  late final StreamController<ImportProgress> ctrl;
  final rp = ReceivePort();
  SendPort? control;
  ctrl = StreamController<ImportProgress>(
    onListen: () async {
      await Isolate.spawn(_worker, (rp.sendPort, dbPath, zipPath, mediaRoot));
      rp.listen((m) {
        switch (m) {
          case SendPort s:
            control = s;
          case ImportProgress pr:
            ctrl.add(pr);
          case ImportResult r:
            onDone(r);
            rp.close();
            ctrl.close();
          case (Object e, StackTrace st):
            ctrl.addError(e, st);
            rp.close();
            ctrl.close();
        }
      });
    },
    onCancel: () => control?.send(#cancel),
  );
  return ctrl.stream;
}

Future<void> _worker((SendPort, String, String, String) args) async {
  final (out, dbPath, zipPath, mediaRoot) = args;
  final controlPort = ReceivePort();
  var cancelled = false;
  controlPort.listen((_) => cancelled = true);
  out.send(controlPort.sendPort);
  final db = AppDb.openSync(File(dbPath));
  try {
    final r = await importDictionaryZip(
      db,
      zipPath,
      mediaRoot: mediaRoot,
      onProgress: out.send,
      isCancelled: () => cancelled,
    );
    out.send(r);
  } catch (e, st) {
    out.send((e is DictionaryException ? e : DictionaryException('$e'), st));
  } finally {
    await db.close();
    controlPort.close();
  }
}
