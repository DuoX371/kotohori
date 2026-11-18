import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'library_db.g.dart';

/// One book on the shelf. Times are milliseconds since the epoch (drift's
/// DateTime columns keep whole seconds, too coarse to order two quick adds).
class Books extends Table {
  /// SHA-256 of the EPUB file; also names the stored copy.
  TextColumn get hash => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();

  /// JSON list of each chapter's visible-text length.
  TextColumn get chapterLengths => text()();
  IntColumn get addedAt => integer()();
  IntColumn get lastReadAt => integer().nullable()();
  IntColumn get chapter => integer().withDefault(const Constant(0))();
  IntColumn get offset =>
      integer().named('char_offset').withDefault(const Constant(0))();
  RealColumn get progress => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {hash};
}

/// The reader's own database, separate from the dictionaries.
@DriftDatabase(tables: [Books])
class LibraryDb extends _$LibraryDb {
  LibraryDb(super.e);

  factory LibraryDb.open(File file) =>
      LibraryDb(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;
}
