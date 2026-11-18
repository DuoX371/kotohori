// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_db.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterLengthsMeta = const VerificationMeta(
    'chapterLengths',
  );
  @override
  late final GeneratedColumn<String> chapterLengths = GeneratedColumn<String>(
    'chapter_lengths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<int> lastReadAt = GeneratedColumn<int>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offsetMeta = const VerificationMeta('offset');
  @override
  late final GeneratedColumn<int> offset = GeneratedColumn<int>(
    'char_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    hash,
    title,
    author,
    coverPath,
    chapterLengths,
    addedAt,
    lastReadAt,
    chapter,
    offset,
    progress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('chapter_lengths')) {
      context.handle(
        _chapterLengthsMeta,
        chapterLengths.isAcceptableOrUnknown(
          data['chapter_lengths']!,
          _chapterLengthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterLengthsMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    }
    if (data.containsKey('char_offset')) {
      context.handle(
        _offsetMeta,
        offset.isAcceptableOrUnknown(data['char_offset']!, _offsetMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      chapterLengths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_lengths'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_read_at'],
      ),
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      offset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_offset'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  /// SHA-256 of the EPUB file; also names the stored copy.
  final String hash;
  final String title;
  final String? author;
  final String? coverPath;

  /// JSON list of each chapter's visible-text length.
  final String chapterLengths;
  final int addedAt;
  final int? lastReadAt;
  final int chapter;
  final int offset;
  final double progress;
  const Book({
    required this.hash,
    required this.title,
    this.author,
    this.coverPath,
    required this.chapterLengths,
    required this.addedAt,
    this.lastReadAt,
    required this.chapter,
    required this.offset,
    required this.progress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<String>(hash);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['chapter_lengths'] = Variable<String>(chapterLengths);
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<int>(lastReadAt);
    }
    map['chapter'] = Variable<int>(chapter);
    map['char_offset'] = Variable<int>(offset);
    map['progress'] = Variable<double>(progress);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      hash: Value(hash),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      chapterLengths: Value(chapterLengths),
      addedAt: Value(addedAt),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      chapter: Value(chapter),
      offset: Value(offset),
      progress: Value(progress),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      hash: serializer.fromJson<String>(json['hash']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      chapterLengths: serializer.fromJson<String>(json['chapterLengths']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      lastReadAt: serializer.fromJson<int?>(json['lastReadAt']),
      chapter: serializer.fromJson<int>(json['chapter']),
      offset: serializer.fromJson<int>(json['offset']),
      progress: serializer.fromJson<double>(json['progress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<String>(hash),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'coverPath': serializer.toJson<String?>(coverPath),
      'chapterLengths': serializer.toJson<String>(chapterLengths),
      'addedAt': serializer.toJson<int>(addedAt),
      'lastReadAt': serializer.toJson<int?>(lastReadAt),
      'chapter': serializer.toJson<int>(chapter),
      'offset': serializer.toJson<int>(offset),
      'progress': serializer.toJson<double>(progress),
    };
  }

  Book copyWith({
    String? hash,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> coverPath = const Value.absent(),
    String? chapterLengths,
    int? addedAt,
    Value<int?> lastReadAt = const Value.absent(),
    int? chapter,
    int? offset,
    double? progress,
  }) => Book(
    hash: hash ?? this.hash,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    chapterLengths: chapterLengths ?? this.chapterLengths,
    addedAt: addedAt ?? this.addedAt,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
    chapter: chapter ?? this.chapter,
    offset: offset ?? this.offset,
    progress: progress ?? this.progress,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      hash: data.hash.present ? data.hash.value : this.hash,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      chapterLengths: data.chapterLengths.present
          ? data.chapterLengths.value
          : this.chapterLengths,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      offset: data.offset.present ? data.offset.value : this.offset,
      progress: data.progress.present ? data.progress.value : this.progress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('hash: $hash, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('chapterLengths: $chapterLengths, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('chapter: $chapter, ')
          ..write('offset: $offset, ')
          ..write('progress: $progress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hash,
    title,
    author,
    coverPath,
    chapterLengths,
    addedAt,
    lastReadAt,
    chapter,
    offset,
    progress,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.hash == this.hash &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverPath == this.coverPath &&
          other.chapterLengths == this.chapterLengths &&
          other.addedAt == this.addedAt &&
          other.lastReadAt == this.lastReadAt &&
          other.chapter == this.chapter &&
          other.offset == this.offset &&
          other.progress == this.progress);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> hash;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> coverPath;
  final Value<String> chapterLengths;
  final Value<int> addedAt;
  final Value<int?> lastReadAt;
  final Value<int> chapter;
  final Value<int> offset;
  final Value<double> progress;
  final Value<int> rowid;
  const BooksCompanion({
    this.hash = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.chapterLengths = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.chapter = const Value.absent(),
    this.offset = const Value.absent(),
    this.progress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String hash,
    required String title,
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    required String chapterLengths,
    required int addedAt,
    this.lastReadAt = const Value.absent(),
    this.chapter = const Value.absent(),
    this.offset = const Value.absent(),
    this.progress = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       title = Value(title),
       chapterLengths = Value(chapterLengths),
       addedAt = Value(addedAt);
  static Insertable<Book> custom({
    Expression<String>? hash,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverPath,
    Expression<String>? chapterLengths,
    Expression<int>? addedAt,
    Expression<int>? lastReadAt,
    Expression<int>? chapter,
    Expression<int>? offset,
    Expression<double>? progress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverPath != null) 'cover_path': coverPath,
      if (chapterLengths != null) 'chapter_lengths': chapterLengths,
      if (addedAt != null) 'added_at': addedAt,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (chapter != null) 'chapter': chapter,
      if (offset != null) 'char_offset': offset,
      if (progress != null) 'progress': progress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? hash,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? coverPath,
    Value<String>? chapterLengths,
    Value<int>? addedAt,
    Value<int?>? lastReadAt,
    Value<int>? chapter,
    Value<int>? offset,
    Value<double>? progress,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      hash: hash ?? this.hash,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      chapterLengths: chapterLengths ?? this.chapterLengths,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      chapter: chapter ?? this.chapter,
      offset: offset ?? this.offset,
      progress: progress ?? this.progress,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (chapterLengths.present) {
      map['chapter_lengths'] = Variable<String>(chapterLengths.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<int>(lastReadAt.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (offset.present) {
      map['char_offset'] = Variable<int>(offset.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('hash: $hash, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('chapterLengths: $chapterLengths, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('chapter: $chapter, ')
          ..write('offset: $offset, ')
          ..write('progress: $progress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDb extends GeneratedDatabase {
  _$LibraryDb(QueryExecutor e) : super(e);
  $LibraryDbManager get managers => $LibraryDbManager(this);
  late final $BooksTable books = $BooksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [books];
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String hash,
  required String title,
  Value<String?> author,
  Value<String?> coverPath,
  required String chapterLengths,
  required int addedAt,
  Value<int?> lastReadAt,
  Value<int> chapter,
  Value<int> offset,
  Value<double> progress,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> hash,
  Value<String> title,
  Value<String?> author,
  Value<String?> coverPath,
  Value<String> chapterLengths,
  Value<int> addedAt,
  Value<int?> lastReadAt,
  Value<int> chapter,
  Value<int> offset,
  Value<double> progress,
  Value<int> rowid,
});

class $$BooksTableFilterComposer extends Composer<_$LibraryDb, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterLengths => $composableBuilder(
    column: $table.chapterLengths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offset => $composableBuilder(
    column: $table.offset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer extends Composer<_$LibraryDb, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterLengths => $composableBuilder(
    column: $table.chapterLengths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offset => $composableBuilder(
    column: $table.offset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$LibraryDb, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get chapterLengths => $composableBuilder(
    column: $table.chapterLengths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get offset =>
      $composableBuilder(column: $table.offset, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, BaseReferences<_$LibraryDb, $BooksTable, Book>),
          Book,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$LibraryDb db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> hash = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String> chapterLengths = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int?> lastReadAt = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> offset = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                hash: hash,
                title: title,
                author: author,
                coverPath: coverPath,
                chapterLengths: chapterLengths,
                addedAt: addedAt,
                lastReadAt: lastReadAt,
                chapter: chapter,
                offset: offset,
                progress: progress,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hash,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                required String chapterLengths,
                required int addedAt,
                Value<int?> lastReadAt = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int> offset = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                hash: hash,
                title: title,
                author: author,
                coverPath: coverPath,
                chapterLengths: chapterLengths,
                addedAt: addedAt,
                lastReadAt: lastReadAt,
                chapter: chapter,
                offset: offset,
                progress: progress,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  BaseReferences<_$LibraryDb, $BooksTable, Book>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, BaseReferences<_$LibraryDb, $BooksTable, Book>),
      Book,
      PrefetchHooks Function()
    >;

class $LibraryDbManager {
  final _$LibraryDb _db;
  $LibraryDbManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
}
