import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

part 'db.g.dart';

@TableIndex(name: 'dict_title_rev', columns: {#title, #revision}, unique: true)
class Dictionaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get revision => text()();
  IntColumn get format => integer()();
  TextColumn get author => text().nullable()();
  TextColumn get attribution => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get sourceLanguage => text().nullable()();
  BoolColumn get isUpdatable => boolean().withDefault(const Constant(false))();
  TextColumn get indexUrl => text().nullable()();
  TextColumn get downloadUrl => text().nullable()();
  TextColumn get stylesCss => text().withDefault(const Constant(''))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Set when an import finished; rows with null are partial and get purged.
  DateTimeColumn get importedAt => dateTime().nullable()();
}

@TableIndex(name: 'terms_expr', columns: {#expression})
@TableIndex(name: 'terms_reading', columns: {#reading})
@TableIndex(name: 'terms_dict', columns: {#dictId})
class Terms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictId => integer()();
  TextColumn get expression => text()();
  TextColumn get reading => text()();
  TextColumn get definitionTags => text()();
  TextColumn get rules => text()();
  IntColumn get score => integer()();
  TextColumn get glossary => text()(); // raw JSON
  IntColumn get sequence => integer().nullable()();
  TextColumn get termTags => text()();
}

@TableIndex(name: 'term_meta_expr', columns: {#expression})
@TableIndex(name: 'term_meta_dict', columns: {#dictId})
class TermMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictId => integer()();
  TextColumn get expression => text()();
  TextColumn get mode => text()(); // freq | pitch | ipa
  TextColumn get data => text()(); // raw JSON
}

@TableIndex(name: 'kanji_char', columns: {#character})
@TableIndex(name: 'kanji_dict', columns: {#dictId})
class Kanji extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictId => integer()();
  TextColumn get character => text()();
  TextColumn get onyomi => text()();
  TextColumn get kunyomi => text()();
  TextColumn get tags => text()();
  TextColumn get meanings => text()(); // raw JSON
  TextColumn get stats => text()(); // raw JSON
}

@TableIndex(name: 'kanji_meta_char', columns: {#character})
@TableIndex(name: 'kanji_meta_dict', columns: {#dictId})
class KanjiMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictId => integer()();
  TextColumn get character => text()();
  TextColumn get mode => text()();
  TextColumn get data => text()();
}

@TableIndex(name: 'tags_dict', columns: {#dictId})
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictId => integer()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get notes => text()();
  IntColumn get score => integer()();
}

/// Tables whose rows belong to a dictionary via `dict_id`.
const dictDataTables = ['terms', 'term_meta', 'kanji', 'kanji_meta', 'tags'];

@DriftDatabase(tables: [Dictionaries, Terms, TermMeta, Kanji, KanjiMeta, Tags])
class AppDb extends _$AppDb {
  AppDb(super.e);

  /// Main-app connection: SQLite runs in drift's background isolate.
  factory AppDb.open(File file) =>
      AppDb(NativeDatabase.createInBackground(file, setup: _setup));

  /// Direct connection, for use inside a worker isolate.
  factory AppDb.openSync(File file) =>
      AppDb(NativeDatabase(file, setup: _setup));

  static void _setup(sqlite.Database db) {
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('PRAGMA busy_timeout=10000');
  }

  @override
  int get schemaVersion => 1;
}
