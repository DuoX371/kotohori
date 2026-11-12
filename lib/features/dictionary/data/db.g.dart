// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $DictionariesTable extends Dictionaries
    with TableInfo<$DictionariesTable, Dictionary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<int> format = GeneratedColumn<int>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceLanguageMeta = const VerificationMeta(
    'sourceLanguage',
  );
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
    'source_language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUpdatableMeta = const VerificationMeta(
    'isUpdatable',
  );
  @override
  late final GeneratedColumn<bool> isUpdatable = GeneratedColumn<bool>(
    'is_updatable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_updatable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _indexUrlMeta = const VerificationMeta(
    'indexUrl',
  );
  @override
  late final GeneratedColumn<String> indexUrl = GeneratedColumn<String>(
    'index_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadUrlMeta = const VerificationMeta(
    'downloadUrl',
  );
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
    'download_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stylesCssMeta = const VerificationMeta(
    'stylesCss',
  );
  @override
  late final GeneratedColumn<String> stylesCss = GeneratedColumn<String>(
    'styles_css',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    revision,
    format,
    author,
    attribution,
    description,
    sourceLanguage,
    isUpdatable,
    indexUrl,
    downloadUrl,
    stylesCss,
    enabled,
    priority,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Dictionary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('source_language')) {
      context.handle(
        _sourceLanguageMeta,
        sourceLanguage.isAcceptableOrUnknown(
          data['source_language']!,
          _sourceLanguageMeta,
        ),
      );
    }
    if (data.containsKey('is_updatable')) {
      context.handle(
        _isUpdatableMeta,
        isUpdatable.isAcceptableOrUnknown(
          data['is_updatable']!,
          _isUpdatableMeta,
        ),
      );
    }
    if (data.containsKey('index_url')) {
      context.handle(
        _indexUrlMeta,
        indexUrl.isAcceptableOrUnknown(data['index_url']!, _indexUrlMeta),
      );
    }
    if (data.containsKey('download_url')) {
      context.handle(
        _downloadUrlMeta,
        downloadUrl.isAcceptableOrUnknown(
          data['download_url']!,
          _downloadUrlMeta,
        ),
      );
    }
    if (data.containsKey('styles_css')) {
      context.handle(
        _stylesCssMeta,
        stylesCss.isAcceptableOrUnknown(data['styles_css']!, _stylesCssMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dictionary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dictionary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      ),
      isUpdatable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_updatable'],
      )!,
      indexUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}index_url'],
      ),
      downloadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_url'],
      ),
      stylesCss: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}styles_css'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      ),
    );
  }

  @override
  $DictionariesTable createAlias(String alias) {
    return $DictionariesTable(attachedDatabase, alias);
  }
}

class Dictionary extends DataClass implements Insertable<Dictionary> {
  final int id;
  final String title;
  final String revision;
  final int format;
  final String? author;
  final String? attribution;
  final String? description;
  final String? sourceLanguage;
  final bool isUpdatable;
  final String? indexUrl;
  final String? downloadUrl;
  final String stylesCss;
  final bool enabled;
  final int priority;

  /// Set when an import finished; rows with null are partial and get purged.
  final DateTime? importedAt;
  const Dictionary({
    required this.id,
    required this.title,
    required this.revision,
    required this.format,
    this.author,
    this.attribution,
    this.description,
    this.sourceLanguage,
    required this.isUpdatable,
    this.indexUrl,
    this.downloadUrl,
    required this.stylesCss,
    required this.enabled,
    required this.priority,
    this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['revision'] = Variable<String>(revision);
    map['format'] = Variable<int>(format);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || attribution != null) {
      map['attribution'] = Variable<String>(attribution);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || sourceLanguage != null) {
      map['source_language'] = Variable<String>(sourceLanguage);
    }
    map['is_updatable'] = Variable<bool>(isUpdatable);
    if (!nullToAbsent || indexUrl != null) {
      map['index_url'] = Variable<String>(indexUrl);
    }
    if (!nullToAbsent || downloadUrl != null) {
      map['download_url'] = Variable<String>(downloadUrl);
    }
    map['styles_css'] = Variable<String>(stylesCss);
    map['enabled'] = Variable<bool>(enabled);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || importedAt != null) {
      map['imported_at'] = Variable<DateTime>(importedAt);
    }
    return map;
  }

  DictionariesCompanion toCompanion(bool nullToAbsent) {
    return DictionariesCompanion(
      id: Value(id),
      title: Value(title),
      revision: Value(revision),
      format: Value(format),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      attribution: attribution == null && nullToAbsent
          ? const Value.absent()
          : Value(attribution),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sourceLanguage: sourceLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLanguage),
      isUpdatable: Value(isUpdatable),
      indexUrl: indexUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(indexUrl),
      downloadUrl: downloadUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadUrl),
      stylesCss: Value(stylesCss),
      enabled: Value(enabled),
      priority: Value(priority),
      importedAt: importedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(importedAt),
    );
  }

  factory Dictionary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dictionary(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      revision: serializer.fromJson<String>(json['revision']),
      format: serializer.fromJson<int>(json['format']),
      author: serializer.fromJson<String?>(json['author']),
      attribution: serializer.fromJson<String?>(json['attribution']),
      description: serializer.fromJson<String?>(json['description']),
      sourceLanguage: serializer.fromJson<String?>(json['sourceLanguage']),
      isUpdatable: serializer.fromJson<bool>(json['isUpdatable']),
      indexUrl: serializer.fromJson<String?>(json['indexUrl']),
      downloadUrl: serializer.fromJson<String?>(json['downloadUrl']),
      stylesCss: serializer.fromJson<String>(json['stylesCss']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      priority: serializer.fromJson<int>(json['priority']),
      importedAt: serializer.fromJson<DateTime?>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'revision': serializer.toJson<String>(revision),
      'format': serializer.toJson<int>(format),
      'author': serializer.toJson<String?>(author),
      'attribution': serializer.toJson<String?>(attribution),
      'description': serializer.toJson<String?>(description),
      'sourceLanguage': serializer.toJson<String?>(sourceLanguage),
      'isUpdatable': serializer.toJson<bool>(isUpdatable),
      'indexUrl': serializer.toJson<String?>(indexUrl),
      'downloadUrl': serializer.toJson<String?>(downloadUrl),
      'stylesCss': serializer.toJson<String>(stylesCss),
      'enabled': serializer.toJson<bool>(enabled),
      'priority': serializer.toJson<int>(priority),
      'importedAt': serializer.toJson<DateTime?>(importedAt),
    };
  }

  Dictionary copyWith({
    int? id,
    String? title,
    String? revision,
    int? format,
    Value<String?> author = const Value.absent(),
    Value<String?> attribution = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> sourceLanguage = const Value.absent(),
    bool? isUpdatable,
    Value<String?> indexUrl = const Value.absent(),
    Value<String?> downloadUrl = const Value.absent(),
    String? stylesCss,
    bool? enabled,
    int? priority,
    Value<DateTime?> importedAt = const Value.absent(),
  }) => Dictionary(
    id: id ?? this.id,
    title: title ?? this.title,
    revision: revision ?? this.revision,
    format: format ?? this.format,
    author: author.present ? author.value : this.author,
    attribution: attribution.present ? attribution.value : this.attribution,
    description: description.present ? description.value : this.description,
    sourceLanguage: sourceLanguage.present
        ? sourceLanguage.value
        : this.sourceLanguage,
    isUpdatable: isUpdatable ?? this.isUpdatable,
    indexUrl: indexUrl.present ? indexUrl.value : this.indexUrl,
    downloadUrl: downloadUrl.present ? downloadUrl.value : this.downloadUrl,
    stylesCss: stylesCss ?? this.stylesCss,
    enabled: enabled ?? this.enabled,
    priority: priority ?? this.priority,
    importedAt: importedAt.present ? importedAt.value : this.importedAt,
  );
  Dictionary copyWithCompanion(DictionariesCompanion data) {
    return Dictionary(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      revision: data.revision.present ? data.revision.value : this.revision,
      format: data.format.present ? data.format.value : this.format,
      author: data.author.present ? data.author.value : this.author,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      description: data.description.present
          ? data.description.value
          : this.description,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      isUpdatable: data.isUpdatable.present
          ? data.isUpdatable.value
          : this.isUpdatable,
      indexUrl: data.indexUrl.present ? data.indexUrl.value : this.indexUrl,
      downloadUrl: data.downloadUrl.present
          ? data.downloadUrl.value
          : this.downloadUrl,
      stylesCss: data.stylesCss.present ? data.stylesCss.value : this.stylesCss,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      priority: data.priority.present ? data.priority.value : this.priority,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dictionary(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('format: $format, ')
          ..write('author: $author, ')
          ..write('attribution: $attribution, ')
          ..write('description: $description, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('isUpdatable: $isUpdatable, ')
          ..write('indexUrl: $indexUrl, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('stylesCss: $stylesCss, ')
          ..write('enabled: $enabled, ')
          ..write('priority: $priority, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    revision,
    format,
    author,
    attribution,
    description,
    sourceLanguage,
    isUpdatable,
    indexUrl,
    downloadUrl,
    stylesCss,
    enabled,
    priority,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dictionary &&
          other.id == this.id &&
          other.title == this.title &&
          other.revision == this.revision &&
          other.format == this.format &&
          other.author == this.author &&
          other.attribution == this.attribution &&
          other.description == this.description &&
          other.sourceLanguage == this.sourceLanguage &&
          other.isUpdatable == this.isUpdatable &&
          other.indexUrl == this.indexUrl &&
          other.downloadUrl == this.downloadUrl &&
          other.stylesCss == this.stylesCss &&
          other.enabled == this.enabled &&
          other.priority == this.priority &&
          other.importedAt == this.importedAt);
}

class DictionariesCompanion extends UpdateCompanion<Dictionary> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> revision;
  final Value<int> format;
  final Value<String?> author;
  final Value<String?> attribution;
  final Value<String?> description;
  final Value<String?> sourceLanguage;
  final Value<bool> isUpdatable;
  final Value<String?> indexUrl;
  final Value<String?> downloadUrl;
  final Value<String> stylesCss;
  final Value<bool> enabled;
  final Value<int> priority;
  final Value<DateTime?> importedAt;
  const DictionariesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.revision = const Value.absent(),
    this.format = const Value.absent(),
    this.author = const Value.absent(),
    this.attribution = const Value.absent(),
    this.description = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.isUpdatable = const Value.absent(),
    this.indexUrl = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.stylesCss = const Value.absent(),
    this.enabled = const Value.absent(),
    this.priority = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  DictionariesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String revision,
    required int format,
    this.author = const Value.absent(),
    this.attribution = const Value.absent(),
    this.description = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.isUpdatable = const Value.absent(),
    this.indexUrl = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.stylesCss = const Value.absent(),
    this.enabled = const Value.absent(),
    this.priority = const Value.absent(),
    this.importedAt = const Value.absent(),
  }) : title = Value(title),
       revision = Value(revision),
       format = Value(format);
  static Insertable<Dictionary> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? revision,
    Expression<int>? format,
    Expression<String>? author,
    Expression<String>? attribution,
    Expression<String>? description,
    Expression<String>? sourceLanguage,
    Expression<bool>? isUpdatable,
    Expression<String>? indexUrl,
    Expression<String>? downloadUrl,
    Expression<String>? stylesCss,
    Expression<bool>? enabled,
    Expression<int>? priority,
    Expression<DateTime>? importedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (revision != null) 'revision': revision,
      if (format != null) 'format': format,
      if (author != null) 'author': author,
      if (attribution != null) 'attribution': attribution,
      if (description != null) 'description': description,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (isUpdatable != null) 'is_updatable': isUpdatable,
      if (indexUrl != null) 'index_url': indexUrl,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (stylesCss != null) 'styles_css': stylesCss,
      if (enabled != null) 'enabled': enabled,
      if (priority != null) 'priority': priority,
      if (importedAt != null) 'imported_at': importedAt,
    });
  }

  DictionariesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? revision,
    Value<int>? format,
    Value<String?>? author,
    Value<String?>? attribution,
    Value<String?>? description,
    Value<String?>? sourceLanguage,
    Value<bool>? isUpdatable,
    Value<String?>? indexUrl,
    Value<String?>? downloadUrl,
    Value<String>? stylesCss,
    Value<bool>? enabled,
    Value<int>? priority,
    Value<DateTime?>? importedAt,
  }) {
    return DictionariesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      revision: revision ?? this.revision,
      format: format ?? this.format,
      author: author ?? this.author,
      attribution: attribution ?? this.attribution,
      description: description ?? this.description,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      isUpdatable: isUpdatable ?? this.isUpdatable,
      indexUrl: indexUrl ?? this.indexUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      stylesCss: stylesCss ?? this.stylesCss,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (format.present) {
      map['format'] = Variable<int>(format.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (isUpdatable.present) {
      map['is_updatable'] = Variable<bool>(isUpdatable.value);
    }
    if (indexUrl.present) {
      map['index_url'] = Variable<String>(indexUrl.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (stylesCss.present) {
      map['styles_css'] = Variable<String>(stylesCss.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionariesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('format: $format, ')
          ..write('author: $author, ')
          ..write('attribution: $attribution, ')
          ..write('description: $description, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('isUpdatable: $isUpdatable, ')
          ..write('indexUrl: $indexUrl, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('stylesCss: $stylesCss, ')
          ..write('enabled: $enabled, ')
          ..write('priority: $priority, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }
}

class $TermsTable extends Terms with TableInfo<$TermsTable, Term> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictIdMeta = const VerificationMeta('dictId');
  @override
  late final GeneratedColumn<int> dictId = GeneratedColumn<int>(
    'dict_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expressionMeta = const VerificationMeta(
    'expression',
  );
  @override
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionTagsMeta = const VerificationMeta(
    'definitionTags',
  );
  @override
  late final GeneratedColumn<String> definitionTags = GeneratedColumn<String>(
    'definition_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rulesMeta = const VerificationMeta('rules');
  @override
  late final GeneratedColumn<String> rules = GeneratedColumn<String>(
    'rules',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _glossaryMeta = const VerificationMeta(
    'glossary',
  );
  @override
  late final GeneratedColumn<String> glossary = GeneratedColumn<String>(
    'glossary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termTagsMeta = const VerificationMeta(
    'termTags',
  );
  @override
  late final GeneratedColumn<String> termTags = GeneratedColumn<String>(
    'term_tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictId,
    expression,
    reading,
    definitionTags,
    rules,
    score,
    glossary,
    sequence,
    termTags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'terms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Term> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dict_id')) {
      context.handle(
        _dictIdMeta,
        dictId.isAcceptableOrUnknown(data['dict_id']!, _dictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dictIdMeta);
    }
    if (data.containsKey('expression')) {
      context.handle(
        _expressionMeta,
        expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta),
      );
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('definition_tags')) {
      context.handle(
        _definitionTagsMeta,
        definitionTags.isAcceptableOrUnknown(
          data['definition_tags']!,
          _definitionTagsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionTagsMeta);
    }
    if (data.containsKey('rules')) {
      context.handle(
        _rulesMeta,
        rules.isAcceptableOrUnknown(data['rules']!, _rulesMeta),
      );
    } else if (isInserting) {
      context.missing(_rulesMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('glossary')) {
      context.handle(
        _glossaryMeta,
        glossary.isAcceptableOrUnknown(data['glossary']!, _glossaryMeta),
      );
    } else if (isInserting) {
      context.missing(_glossaryMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('term_tags')) {
      context.handle(
        _termTagsMeta,
        termTags.isAcceptableOrUnknown(data['term_tags']!, _termTagsMeta),
      );
    } else if (isInserting) {
      context.missing(_termTagsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Term map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Term(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dict_id'],
      )!,
      expression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      definitionTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_tags'],
      )!,
      rules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      glossary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glossary'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      ),
      termTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term_tags'],
      )!,
    );
  }

  @override
  $TermsTable createAlias(String alias) {
    return $TermsTable(attachedDatabase, alias);
  }
}

class Term extends DataClass implements Insertable<Term> {
  final int id;
  final int dictId;
  final String expression;
  final String reading;
  final String definitionTags;
  final String rules;
  final int score;
  final String glossary;
  final int? sequence;
  final String termTags;
  const Term({
    required this.id,
    required this.dictId,
    required this.expression,
    required this.reading,
    required this.definitionTags,
    required this.rules,
    required this.score,
    required this.glossary,
    this.sequence,
    required this.termTags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dict_id'] = Variable<int>(dictId);
    map['expression'] = Variable<String>(expression);
    map['reading'] = Variable<String>(reading);
    map['definition_tags'] = Variable<String>(definitionTags);
    map['rules'] = Variable<String>(rules);
    map['score'] = Variable<int>(score);
    map['glossary'] = Variable<String>(glossary);
    if (!nullToAbsent || sequence != null) {
      map['sequence'] = Variable<int>(sequence);
    }
    map['term_tags'] = Variable<String>(termTags);
    return map;
  }

  TermsCompanion toCompanion(bool nullToAbsent) {
    return TermsCompanion(
      id: Value(id),
      dictId: Value(dictId),
      expression: Value(expression),
      reading: Value(reading),
      definitionTags: Value(definitionTags),
      rules: Value(rules),
      score: Value(score),
      glossary: Value(glossary),
      sequence: sequence == null && nullToAbsent
          ? const Value.absent()
          : Value(sequence),
      termTags: Value(termTags),
    );
  }

  factory Term.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Term(
      id: serializer.fromJson<int>(json['id']),
      dictId: serializer.fromJson<int>(json['dictId']),
      expression: serializer.fromJson<String>(json['expression']),
      reading: serializer.fromJson<String>(json['reading']),
      definitionTags: serializer.fromJson<String>(json['definitionTags']),
      rules: serializer.fromJson<String>(json['rules']),
      score: serializer.fromJson<int>(json['score']),
      glossary: serializer.fromJson<String>(json['glossary']),
      sequence: serializer.fromJson<int?>(json['sequence']),
      termTags: serializer.fromJson<String>(json['termTags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictId': serializer.toJson<int>(dictId),
      'expression': serializer.toJson<String>(expression),
      'reading': serializer.toJson<String>(reading),
      'definitionTags': serializer.toJson<String>(definitionTags),
      'rules': serializer.toJson<String>(rules),
      'score': serializer.toJson<int>(score),
      'glossary': serializer.toJson<String>(glossary),
      'sequence': serializer.toJson<int?>(sequence),
      'termTags': serializer.toJson<String>(termTags),
    };
  }

  Term copyWith({
    int? id,
    int? dictId,
    String? expression,
    String? reading,
    String? definitionTags,
    String? rules,
    int? score,
    String? glossary,
    Value<int?> sequence = const Value.absent(),
    String? termTags,
  }) => Term(
    id: id ?? this.id,
    dictId: dictId ?? this.dictId,
    expression: expression ?? this.expression,
    reading: reading ?? this.reading,
    definitionTags: definitionTags ?? this.definitionTags,
    rules: rules ?? this.rules,
    score: score ?? this.score,
    glossary: glossary ?? this.glossary,
    sequence: sequence.present ? sequence.value : this.sequence,
    termTags: termTags ?? this.termTags,
  );
  Term copyWithCompanion(TermsCompanion data) {
    return Term(
      id: data.id.present ? data.id.value : this.id,
      dictId: data.dictId.present ? data.dictId.value : this.dictId,
      expression: data.expression.present
          ? data.expression.value
          : this.expression,
      reading: data.reading.present ? data.reading.value : this.reading,
      definitionTags: data.definitionTags.present
          ? data.definitionTags.value
          : this.definitionTags,
      rules: data.rules.present ? data.rules.value : this.rules,
      score: data.score.present ? data.score.value : this.score,
      glossary: data.glossary.present ? data.glossary.value : this.glossary,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      termTags: data.termTags.present ? data.termTags.value : this.termTags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Term(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('definitionTags: $definitionTags, ')
          ..write('rules: $rules, ')
          ..write('score: $score, ')
          ..write('glossary: $glossary, ')
          ..write('sequence: $sequence, ')
          ..write('termTags: $termTags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictId,
    expression,
    reading,
    definitionTags,
    rules,
    score,
    glossary,
    sequence,
    termTags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Term &&
          other.id == this.id &&
          other.dictId == this.dictId &&
          other.expression == this.expression &&
          other.reading == this.reading &&
          other.definitionTags == this.definitionTags &&
          other.rules == this.rules &&
          other.score == this.score &&
          other.glossary == this.glossary &&
          other.sequence == this.sequence &&
          other.termTags == this.termTags);
}

class TermsCompanion extends UpdateCompanion<Term> {
  final Value<int> id;
  final Value<int> dictId;
  final Value<String> expression;
  final Value<String> reading;
  final Value<String> definitionTags;
  final Value<String> rules;
  final Value<int> score;
  final Value<String> glossary;
  final Value<int?> sequence;
  final Value<String> termTags;
  const TermsCompanion({
    this.id = const Value.absent(),
    this.dictId = const Value.absent(),
    this.expression = const Value.absent(),
    this.reading = const Value.absent(),
    this.definitionTags = const Value.absent(),
    this.rules = const Value.absent(),
    this.score = const Value.absent(),
    this.glossary = const Value.absent(),
    this.sequence = const Value.absent(),
    this.termTags = const Value.absent(),
  });
  TermsCompanion.insert({
    this.id = const Value.absent(),
    required int dictId,
    required String expression,
    required String reading,
    required String definitionTags,
    required String rules,
    required int score,
    required String glossary,
    this.sequence = const Value.absent(),
    required String termTags,
  }) : dictId = Value(dictId),
       expression = Value(expression),
       reading = Value(reading),
       definitionTags = Value(definitionTags),
       rules = Value(rules),
       score = Value(score),
       glossary = Value(glossary),
       termTags = Value(termTags);
  static Insertable<Term> custom({
    Expression<int>? id,
    Expression<int>? dictId,
    Expression<String>? expression,
    Expression<String>? reading,
    Expression<String>? definitionTags,
    Expression<String>? rules,
    Expression<int>? score,
    Expression<String>? glossary,
    Expression<int>? sequence,
    Expression<String>? termTags,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictId != null) 'dict_id': dictId,
      if (expression != null) 'expression': expression,
      if (reading != null) 'reading': reading,
      if (definitionTags != null) 'definition_tags': definitionTags,
      if (rules != null) 'rules': rules,
      if (score != null) 'score': score,
      if (glossary != null) 'glossary': glossary,
      if (sequence != null) 'sequence': sequence,
      if (termTags != null) 'term_tags': termTags,
    });
  }

  TermsCompanion copyWith({
    Value<int>? id,
    Value<int>? dictId,
    Value<String>? expression,
    Value<String>? reading,
    Value<String>? definitionTags,
    Value<String>? rules,
    Value<int>? score,
    Value<String>? glossary,
    Value<int?>? sequence,
    Value<String>? termTags,
  }) {
    return TermsCompanion(
      id: id ?? this.id,
      dictId: dictId ?? this.dictId,
      expression: expression ?? this.expression,
      reading: reading ?? this.reading,
      definitionTags: definitionTags ?? this.definitionTags,
      rules: rules ?? this.rules,
      score: score ?? this.score,
      glossary: glossary ?? this.glossary,
      sequence: sequence ?? this.sequence,
      termTags: termTags ?? this.termTags,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictId.present) {
      map['dict_id'] = Variable<int>(dictId.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (definitionTags.present) {
      map['definition_tags'] = Variable<String>(definitionTags.value);
    }
    if (rules.present) {
      map['rules'] = Variable<String>(rules.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (glossary.present) {
      map['glossary'] = Variable<String>(glossary.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (termTags.present) {
      map['term_tags'] = Variable<String>(termTags.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermsCompanion(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('definitionTags: $definitionTags, ')
          ..write('rules: $rules, ')
          ..write('score: $score, ')
          ..write('glossary: $glossary, ')
          ..write('sequence: $sequence, ')
          ..write('termTags: $termTags')
          ..write(')'))
        .toString();
  }
}

class $TermMetaTable extends TermMeta
    with TableInfo<$TermMetaTable, TermMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TermMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictIdMeta = const VerificationMeta('dictId');
  @override
  late final GeneratedColumn<int> dictId = GeneratedColumn<int>(
    'dict_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expressionMeta = const VerificationMeta(
    'expression',
  );
  @override
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dictId, expression, mode, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'term_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<TermMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dict_id')) {
      context.handle(
        _dictIdMeta,
        dictId.isAcceptableOrUnknown(data['dict_id']!, _dictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dictIdMeta);
    }
    if (data.containsKey('expression')) {
      context.handle(
        _expressionMeta,
        expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta),
      );
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TermMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TermMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dict_id'],
      )!,
      expression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $TermMetaTable createAlias(String alias) {
    return $TermMetaTable(attachedDatabase, alias);
  }
}

class TermMetaData extends DataClass implements Insertable<TermMetaData> {
  final int id;
  final int dictId;
  final String expression;
  final String mode;
  final String data;
  const TermMetaData({
    required this.id,
    required this.dictId,
    required this.expression,
    required this.mode,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dict_id'] = Variable<int>(dictId);
    map['expression'] = Variable<String>(expression);
    map['mode'] = Variable<String>(mode);
    map['data'] = Variable<String>(data);
    return map;
  }

  TermMetaCompanion toCompanion(bool nullToAbsent) {
    return TermMetaCompanion(
      id: Value(id),
      dictId: Value(dictId),
      expression: Value(expression),
      mode: Value(mode),
      data: Value(data),
    );
  }

  factory TermMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TermMetaData(
      id: serializer.fromJson<int>(json['id']),
      dictId: serializer.fromJson<int>(json['dictId']),
      expression: serializer.fromJson<String>(json['expression']),
      mode: serializer.fromJson<String>(json['mode']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictId': serializer.toJson<int>(dictId),
      'expression': serializer.toJson<String>(expression),
      'mode': serializer.toJson<String>(mode),
      'data': serializer.toJson<String>(data),
    };
  }

  TermMetaData copyWith({
    int? id,
    int? dictId,
    String? expression,
    String? mode,
    String? data,
  }) => TermMetaData(
    id: id ?? this.id,
    dictId: dictId ?? this.dictId,
    expression: expression ?? this.expression,
    mode: mode ?? this.mode,
    data: data ?? this.data,
  );
  TermMetaData copyWithCompanion(TermMetaCompanion data) {
    return TermMetaData(
      id: data.id.present ? data.id.value : this.id,
      dictId: data.dictId.present ? data.dictId.value : this.dictId,
      expression: data.expression.present
          ? data.expression.value
          : this.expression,
      mode: data.mode.present ? data.mode.value : this.mode,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TermMetaData(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('expression: $expression, ')
          ..write('mode: $mode, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dictId, expression, mode, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TermMetaData &&
          other.id == this.id &&
          other.dictId == this.dictId &&
          other.expression == this.expression &&
          other.mode == this.mode &&
          other.data == this.data);
}

class TermMetaCompanion extends UpdateCompanion<TermMetaData> {
  final Value<int> id;
  final Value<int> dictId;
  final Value<String> expression;
  final Value<String> mode;
  final Value<String> data;
  const TermMetaCompanion({
    this.id = const Value.absent(),
    this.dictId = const Value.absent(),
    this.expression = const Value.absent(),
    this.mode = const Value.absent(),
    this.data = const Value.absent(),
  });
  TermMetaCompanion.insert({
    this.id = const Value.absent(),
    required int dictId,
    required String expression,
    required String mode,
    required String data,
  }) : dictId = Value(dictId),
       expression = Value(expression),
       mode = Value(mode),
       data = Value(data);
  static Insertable<TermMetaData> custom({
    Expression<int>? id,
    Expression<int>? dictId,
    Expression<String>? expression,
    Expression<String>? mode,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictId != null) 'dict_id': dictId,
      if (expression != null) 'expression': expression,
      if (mode != null) 'mode': mode,
      if (data != null) 'data': data,
    });
  }

  TermMetaCompanion copyWith({
    Value<int>? id,
    Value<int>? dictId,
    Value<String>? expression,
    Value<String>? mode,
    Value<String>? data,
  }) {
    return TermMetaCompanion(
      id: id ?? this.id,
      dictId: dictId ?? this.dictId,
      expression: expression ?? this.expression,
      mode: mode ?? this.mode,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictId.present) {
      map['dict_id'] = Variable<int>(dictId.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TermMetaCompanion(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('expression: $expression, ')
          ..write('mode: $mode, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $KanjiTable extends Kanji with TableInfo<$KanjiTable, KanjiData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictIdMeta = const VerificationMeta('dictId');
  @override
  late final GeneratedColumn<int> dictId = GeneratedColumn<int>(
    'dict_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onyomiMeta = const VerificationMeta('onyomi');
  @override
  late final GeneratedColumn<String> onyomi = GeneratedColumn<String>(
    'onyomi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kunyomiMeta = const VerificationMeta(
    'kunyomi',
  );
  @override
  late final GeneratedColumn<String> kunyomi = GeneratedColumn<String>(
    'kunyomi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningsMeta = const VerificationMeta(
    'meanings',
  );
  @override
  late final GeneratedColumn<String> meanings = GeneratedColumn<String>(
    'meanings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statsMeta = const VerificationMeta('stats');
  @override
  late final GeneratedColumn<String> stats = GeneratedColumn<String>(
    'stats',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictId,
    character,
    onyomi,
    kunyomi,
    tags,
    meanings,
    stats,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji';
  @override
  VerificationContext validateIntegrity(
    Insertable<KanjiData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dict_id')) {
      context.handle(
        _dictIdMeta,
        dictId.isAcceptableOrUnknown(data['dict_id']!, _dictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dictIdMeta);
    }
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('onyomi')) {
      context.handle(
        _onyomiMeta,
        onyomi.isAcceptableOrUnknown(data['onyomi']!, _onyomiMeta),
      );
    } else if (isInserting) {
      context.missing(_onyomiMeta);
    }
    if (data.containsKey('kunyomi')) {
      context.handle(
        _kunyomiMeta,
        kunyomi.isAcceptableOrUnknown(data['kunyomi']!, _kunyomiMeta),
      );
    } else if (isInserting) {
      context.missing(_kunyomiMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('meanings')) {
      context.handle(
        _meaningsMeta,
        meanings.isAcceptableOrUnknown(data['meanings']!, _meaningsMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningsMeta);
    }
    if (data.containsKey('stats')) {
      context.handle(
        _statsMeta,
        stats.isAcceptableOrUnknown(data['stats']!, _statsMeta),
      );
    } else if (isInserting) {
      context.missing(_statsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KanjiData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dict_id'],
      )!,
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      onyomi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}onyomi'],
      )!,
      kunyomi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kunyomi'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      meanings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meanings'],
      )!,
      stats: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stats'],
      )!,
    );
  }

  @override
  $KanjiTable createAlias(String alias) {
    return $KanjiTable(attachedDatabase, alias);
  }
}

class KanjiData extends DataClass implements Insertable<KanjiData> {
  final int id;
  final int dictId;
  final String character;
  final String onyomi;
  final String kunyomi;
  final String tags;
  final String meanings;
  final String stats;
  const KanjiData({
    required this.id,
    required this.dictId,
    required this.character,
    required this.onyomi,
    required this.kunyomi,
    required this.tags,
    required this.meanings,
    required this.stats,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dict_id'] = Variable<int>(dictId);
    map['character'] = Variable<String>(character);
    map['onyomi'] = Variable<String>(onyomi);
    map['kunyomi'] = Variable<String>(kunyomi);
    map['tags'] = Variable<String>(tags);
    map['meanings'] = Variable<String>(meanings);
    map['stats'] = Variable<String>(stats);
    return map;
  }

  KanjiCompanion toCompanion(bool nullToAbsent) {
    return KanjiCompanion(
      id: Value(id),
      dictId: Value(dictId),
      character: Value(character),
      onyomi: Value(onyomi),
      kunyomi: Value(kunyomi),
      tags: Value(tags),
      meanings: Value(meanings),
      stats: Value(stats),
    );
  }

  factory KanjiData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiData(
      id: serializer.fromJson<int>(json['id']),
      dictId: serializer.fromJson<int>(json['dictId']),
      character: serializer.fromJson<String>(json['character']),
      onyomi: serializer.fromJson<String>(json['onyomi']),
      kunyomi: serializer.fromJson<String>(json['kunyomi']),
      tags: serializer.fromJson<String>(json['tags']),
      meanings: serializer.fromJson<String>(json['meanings']),
      stats: serializer.fromJson<String>(json['stats']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictId': serializer.toJson<int>(dictId),
      'character': serializer.toJson<String>(character),
      'onyomi': serializer.toJson<String>(onyomi),
      'kunyomi': serializer.toJson<String>(kunyomi),
      'tags': serializer.toJson<String>(tags),
      'meanings': serializer.toJson<String>(meanings),
      'stats': serializer.toJson<String>(stats),
    };
  }

  KanjiData copyWith({
    int? id,
    int? dictId,
    String? character,
    String? onyomi,
    String? kunyomi,
    String? tags,
    String? meanings,
    String? stats,
  }) => KanjiData(
    id: id ?? this.id,
    dictId: dictId ?? this.dictId,
    character: character ?? this.character,
    onyomi: onyomi ?? this.onyomi,
    kunyomi: kunyomi ?? this.kunyomi,
    tags: tags ?? this.tags,
    meanings: meanings ?? this.meanings,
    stats: stats ?? this.stats,
  );
  KanjiData copyWithCompanion(KanjiCompanion data) {
    return KanjiData(
      id: data.id.present ? data.id.value : this.id,
      dictId: data.dictId.present ? data.dictId.value : this.dictId,
      character: data.character.present ? data.character.value : this.character,
      onyomi: data.onyomi.present ? data.onyomi.value : this.onyomi,
      kunyomi: data.kunyomi.present ? data.kunyomi.value : this.kunyomi,
      tags: data.tags.present ? data.tags.value : this.tags,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      stats: data.stats.present ? data.stats.value : this.stats,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiData(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('character: $character, ')
          ..write('onyomi: $onyomi, ')
          ..write('kunyomi: $kunyomi, ')
          ..write('tags: $tags, ')
          ..write('meanings: $meanings, ')
          ..write('stats: $stats')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictId,
    character,
    onyomi,
    kunyomi,
    tags,
    meanings,
    stats,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiData &&
          other.id == this.id &&
          other.dictId == this.dictId &&
          other.character == this.character &&
          other.onyomi == this.onyomi &&
          other.kunyomi == this.kunyomi &&
          other.tags == this.tags &&
          other.meanings == this.meanings &&
          other.stats == this.stats);
}

class KanjiCompanion extends UpdateCompanion<KanjiData> {
  final Value<int> id;
  final Value<int> dictId;
  final Value<String> character;
  final Value<String> onyomi;
  final Value<String> kunyomi;
  final Value<String> tags;
  final Value<String> meanings;
  final Value<String> stats;
  const KanjiCompanion({
    this.id = const Value.absent(),
    this.dictId = const Value.absent(),
    this.character = const Value.absent(),
    this.onyomi = const Value.absent(),
    this.kunyomi = const Value.absent(),
    this.tags = const Value.absent(),
    this.meanings = const Value.absent(),
    this.stats = const Value.absent(),
  });
  KanjiCompanion.insert({
    this.id = const Value.absent(),
    required int dictId,
    required String character,
    required String onyomi,
    required String kunyomi,
    required String tags,
    required String meanings,
    required String stats,
  }) : dictId = Value(dictId),
       character = Value(character),
       onyomi = Value(onyomi),
       kunyomi = Value(kunyomi),
       tags = Value(tags),
       meanings = Value(meanings),
       stats = Value(stats);
  static Insertable<KanjiData> custom({
    Expression<int>? id,
    Expression<int>? dictId,
    Expression<String>? character,
    Expression<String>? onyomi,
    Expression<String>? kunyomi,
    Expression<String>? tags,
    Expression<String>? meanings,
    Expression<String>? stats,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictId != null) 'dict_id': dictId,
      if (character != null) 'character': character,
      if (onyomi != null) 'onyomi': onyomi,
      if (kunyomi != null) 'kunyomi': kunyomi,
      if (tags != null) 'tags': tags,
      if (meanings != null) 'meanings': meanings,
      if (stats != null) 'stats': stats,
    });
  }

  KanjiCompanion copyWith({
    Value<int>? id,
    Value<int>? dictId,
    Value<String>? character,
    Value<String>? onyomi,
    Value<String>? kunyomi,
    Value<String>? tags,
    Value<String>? meanings,
    Value<String>? stats,
  }) {
    return KanjiCompanion(
      id: id ?? this.id,
      dictId: dictId ?? this.dictId,
      character: character ?? this.character,
      onyomi: onyomi ?? this.onyomi,
      kunyomi: kunyomi ?? this.kunyomi,
      tags: tags ?? this.tags,
      meanings: meanings ?? this.meanings,
      stats: stats ?? this.stats,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictId.present) {
      map['dict_id'] = Variable<int>(dictId.value);
    }
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (onyomi.present) {
      map['onyomi'] = Variable<String>(onyomi.value);
    }
    if (kunyomi.present) {
      map['kunyomi'] = Variable<String>(kunyomi.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(meanings.value);
    }
    if (stats.present) {
      map['stats'] = Variable<String>(stats.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiCompanion(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('character: $character, ')
          ..write('onyomi: $onyomi, ')
          ..write('kunyomi: $kunyomi, ')
          ..write('tags: $tags, ')
          ..write('meanings: $meanings, ')
          ..write('stats: $stats')
          ..write(')'))
        .toString();
  }
}

class $KanjiMetaTable extends KanjiMeta
    with TableInfo<$KanjiMetaTable, KanjiMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictIdMeta = const VerificationMeta('dictId');
  @override
  late final GeneratedColumn<int> dictId = GeneratedColumn<int>(
    'dict_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterMeta = const VerificationMeta(
    'character',
  );
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
    'character',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dictId, character, mode, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<KanjiMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dict_id')) {
      context.handle(
        _dictIdMeta,
        dictId.isAcceptableOrUnknown(data['dict_id']!, _dictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dictIdMeta);
    }
    if (data.containsKey('character')) {
      context.handle(
        _characterMeta,
        character.isAcceptableOrUnknown(data['character']!, _characterMeta),
      );
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KanjiMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dict_id'],
      )!,
      character: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $KanjiMetaTable createAlias(String alias) {
    return $KanjiMetaTable(attachedDatabase, alias);
  }
}

class KanjiMetaData extends DataClass implements Insertable<KanjiMetaData> {
  final int id;
  final int dictId;
  final String character;
  final String mode;
  final String data;
  const KanjiMetaData({
    required this.id,
    required this.dictId,
    required this.character,
    required this.mode,
    required this.data,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dict_id'] = Variable<int>(dictId);
    map['character'] = Variable<String>(character);
    map['mode'] = Variable<String>(mode);
    map['data'] = Variable<String>(data);
    return map;
  }

  KanjiMetaCompanion toCompanion(bool nullToAbsent) {
    return KanjiMetaCompanion(
      id: Value(id),
      dictId: Value(dictId),
      character: Value(character),
      mode: Value(mode),
      data: Value(data),
    );
  }

  factory KanjiMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiMetaData(
      id: serializer.fromJson<int>(json['id']),
      dictId: serializer.fromJson<int>(json['dictId']),
      character: serializer.fromJson<String>(json['character']),
      mode: serializer.fromJson<String>(json['mode']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictId': serializer.toJson<int>(dictId),
      'character': serializer.toJson<String>(character),
      'mode': serializer.toJson<String>(mode),
      'data': serializer.toJson<String>(data),
    };
  }

  KanjiMetaData copyWith({
    int? id,
    int? dictId,
    String? character,
    String? mode,
    String? data,
  }) => KanjiMetaData(
    id: id ?? this.id,
    dictId: dictId ?? this.dictId,
    character: character ?? this.character,
    mode: mode ?? this.mode,
    data: data ?? this.data,
  );
  KanjiMetaData copyWithCompanion(KanjiMetaCompanion data) {
    return KanjiMetaData(
      id: data.id.present ? data.id.value : this.id,
      dictId: data.dictId.present ? data.dictId.value : this.dictId,
      character: data.character.present ? data.character.value : this.character,
      mode: data.mode.present ? data.mode.value : this.mode,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiMetaData(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('character: $character, ')
          ..write('mode: $mode, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dictId, character, mode, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiMetaData &&
          other.id == this.id &&
          other.dictId == this.dictId &&
          other.character == this.character &&
          other.mode == this.mode &&
          other.data == this.data);
}

class KanjiMetaCompanion extends UpdateCompanion<KanjiMetaData> {
  final Value<int> id;
  final Value<int> dictId;
  final Value<String> character;
  final Value<String> mode;
  final Value<String> data;
  const KanjiMetaCompanion({
    this.id = const Value.absent(),
    this.dictId = const Value.absent(),
    this.character = const Value.absent(),
    this.mode = const Value.absent(),
    this.data = const Value.absent(),
  });
  KanjiMetaCompanion.insert({
    this.id = const Value.absent(),
    required int dictId,
    required String character,
    required String mode,
    required String data,
  }) : dictId = Value(dictId),
       character = Value(character),
       mode = Value(mode),
       data = Value(data);
  static Insertable<KanjiMetaData> custom({
    Expression<int>? id,
    Expression<int>? dictId,
    Expression<String>? character,
    Expression<String>? mode,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictId != null) 'dict_id': dictId,
      if (character != null) 'character': character,
      if (mode != null) 'mode': mode,
      if (data != null) 'data': data,
    });
  }

  KanjiMetaCompanion copyWith({
    Value<int>? id,
    Value<int>? dictId,
    Value<String>? character,
    Value<String>? mode,
    Value<String>? data,
  }) {
    return KanjiMetaCompanion(
      id: id ?? this.id,
      dictId: dictId ?? this.dictId,
      character: character ?? this.character,
      mode: mode ?? this.mode,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictId.present) {
      map['dict_id'] = Variable<int>(dictId.value);
    }
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiMetaCompanion(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('character: $character, ')
          ..write('mode: $mode, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictIdMeta = const VerificationMeta('dictId');
  @override
  late final GeneratedColumn<int> dictId = GeneratedColumn<int>(
    'dict_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictId,
    name,
    category,
    sortOrder,
    notes,
    score,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dict_id')) {
      context.handle(
        _dictIdMeta,
        dictId.isAcceptableOrUnknown(data['dict_id']!, _dictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dictIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dict_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final int dictId;
  final String name;
  final String category;
  final int sortOrder;
  final String notes;
  final int score;
  const Tag({
    required this.id,
    required this.dictId,
    required this.name,
    required this.category,
    required this.sortOrder,
    required this.notes,
    required this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dict_id'] = Variable<int>(dictId);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['sort_order'] = Variable<int>(sortOrder);
    map['notes'] = Variable<String>(notes);
    map['score'] = Variable<int>(score);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      dictId: Value(dictId),
      name: Value(name),
      category: Value(category),
      sortOrder: Value(sortOrder),
      notes: Value(notes),
      score: Value(score),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      dictId: serializer.fromJson<int>(json['dictId']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      notes: serializer.fromJson<String>(json['notes']),
      score: serializer.fromJson<int>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictId': serializer.toJson<int>(dictId),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'notes': serializer.toJson<String>(notes),
      'score': serializer.toJson<int>(score),
    };
  }

  Tag copyWith({
    int? id,
    int? dictId,
    String? name,
    String? category,
    int? sortOrder,
    String? notes,
    int? score,
  }) => Tag(
    id: id ?? this.id,
    dictId: dictId ?? this.dictId,
    name: name ?? this.name,
    category: category ?? this.category,
    sortOrder: sortOrder ?? this.sortOrder,
    notes: notes ?? this.notes,
    score: score ?? this.score,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      dictId: data.dictId.present ? data.dictId.value : this.dictId,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      notes: data.notes.present ? data.notes.value : this.notes,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notes: $notes, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dictId, name, category, sortOrder, notes, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.dictId == this.dictId &&
          other.name == this.name &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder &&
          other.notes == this.notes &&
          other.score == this.score);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<int> dictId;
  final Value<String> name;
  final Value<String> category;
  final Value<int> sortOrder;
  final Value<String> notes;
  final Value<int> score;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.dictId = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.notes = const Value.absent(),
    this.score = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required int dictId,
    required String name,
    required String category,
    required int sortOrder,
    required String notes,
    required int score,
  }) : dictId = Value(dictId),
       name = Value(name),
       category = Value(category),
       sortOrder = Value(sortOrder),
       notes = Value(notes),
       score = Value(score);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<int>? dictId,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? sortOrder,
    Expression<String>? notes,
    Expression<int>? score,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictId != null) 'dict_id': dictId,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (notes != null) 'notes': notes,
      if (score != null) 'score': score,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<int>? dictId,
    Value<String>? name,
    Value<String>? category,
    Value<int>? sortOrder,
    Value<String>? notes,
    Value<int>? score,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      dictId: dictId ?? this.dictId,
      name: name ?? this.name,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      score: score ?? this.score,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictId.present) {
      map['dict_id'] = Variable<int>(dictId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('dictId: $dictId, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('notes: $notes, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $DictionariesTable dictionaries = $DictionariesTable(this);
  late final $TermsTable terms = $TermsTable(this);
  late final $TermMetaTable termMeta = $TermMetaTable(this);
  late final $KanjiTable kanji = $KanjiTable(this);
  late final $KanjiMetaTable kanjiMeta = $KanjiMetaTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final Index dictTitleRev = Index(
    'dict_title_rev',
    'CREATE UNIQUE INDEX dict_title_rev ON dictionaries (title, revision)',
  );
  late final Index termsExpr = Index(
    'terms_expr',
    'CREATE INDEX terms_expr ON terms (expression)',
  );
  late final Index termsReading = Index(
    'terms_reading',
    'CREATE INDEX terms_reading ON terms (reading)',
  );
  late final Index termsDict = Index(
    'terms_dict',
    'CREATE INDEX terms_dict ON terms (dict_id)',
  );
  late final Index termMetaExpr = Index(
    'term_meta_expr',
    'CREATE INDEX term_meta_expr ON term_meta (expression)',
  );
  late final Index termMetaDict = Index(
    'term_meta_dict',
    'CREATE INDEX term_meta_dict ON term_meta (dict_id)',
  );
  late final Index kanjiChar = Index(
    'kanji_char',
    'CREATE INDEX kanji_char ON kanji (character)',
  );
  late final Index kanjiDict = Index(
    'kanji_dict',
    'CREATE INDEX kanji_dict ON kanji (dict_id)',
  );
  late final Index kanjiMetaChar = Index(
    'kanji_meta_char',
    'CREATE INDEX kanji_meta_char ON kanji_meta (character)',
  );
  late final Index kanjiMetaDict = Index(
    'kanji_meta_dict',
    'CREATE INDEX kanji_meta_dict ON kanji_meta (dict_id)',
  );
  late final Index tagsDict = Index(
    'tags_dict',
    'CREATE INDEX tags_dict ON tags (dict_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dictionaries,
    terms,
    termMeta,
    kanji,
    kanjiMeta,
    tags,
    dictTitleRev,
    termsExpr,
    termsReading,
    termsDict,
    termMetaExpr,
    termMetaDict,
    kanjiChar,
    kanjiDict,
    kanjiMetaChar,
    kanjiMetaDict,
    tagsDict,
  ];
}

typedef $$DictionariesTableCreateCompanionBuilder =
    DictionariesCompanion Function({
      Value<int> id,
      required String title,
      required String revision,
      required int format,
      Value<String?> author,
      Value<String?> attribution,
      Value<String?> description,
      Value<String?> sourceLanguage,
      Value<bool> isUpdatable,
      Value<String?> indexUrl,
      Value<String?> downloadUrl,
      Value<String> stylesCss,
      Value<bool> enabled,
      Value<int> priority,
      Value<DateTime?> importedAt,
    });
typedef $$DictionariesTableUpdateCompanionBuilder =
    DictionariesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> revision,
      Value<int> format,
      Value<String?> author,
      Value<String?> attribution,
      Value<String?> description,
      Value<String?> sourceLanguage,
      Value<bool> isUpdatable,
      Value<String?> indexUrl,
      Value<String?> downloadUrl,
      Value<String> stylesCss,
      Value<bool> enabled,
      Value<int> priority,
      Value<DateTime?> importedAt,
    });

class $$DictionariesTableFilterComposer
    extends Composer<_$AppDb, $DictionariesTable> {
  $$DictionariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUpdatable => $composableBuilder(
    column: $table.isUpdatable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indexUrl => $composableBuilder(
    column: $table.indexUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stylesCss => $composableBuilder(
    column: $table.stylesCss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionariesTableOrderingComposer
    extends Composer<_$AppDb, $DictionariesTable> {
  $$DictionariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUpdatable => $composableBuilder(
    column: $table.isUpdatable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indexUrl => $composableBuilder(
    column: $table.indexUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stylesCss => $composableBuilder(
    column: $table.stylesCss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionariesTableAnnotationComposer
    extends Composer<_$AppDb, $DictionariesTable> {
  $$DictionariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUpdatable => $composableBuilder(
    column: $table.isUpdatable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get indexUrl =>
      $composableBuilder(column: $table.indexUrl, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stylesCss =>
      $composableBuilder(column: $table.stylesCss, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$DictionariesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $DictionariesTable,
          Dictionary,
          $$DictionariesTableFilterComposer,
          $$DictionariesTableOrderingComposer,
          $$DictionariesTableAnnotationComposer,
          $$DictionariesTableCreateCompanionBuilder,
          $$DictionariesTableUpdateCompanionBuilder,
          (Dictionary, BaseReferences<_$AppDb, $DictionariesTable, Dictionary>),
          Dictionary,
          PrefetchHooks Function()
        > {
  $$DictionariesTableTableManager(_$AppDb db, $DictionariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> revision = const Value.absent(),
                Value<int> format = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> attribution = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> sourceLanguage = const Value.absent(),
                Value<bool> isUpdatable = const Value.absent(),
                Value<String?> indexUrl = const Value.absent(),
                Value<String?> downloadUrl = const Value.absent(),
                Value<String> stylesCss = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> importedAt = const Value.absent(),
              }) => DictionariesCompanion(
                id: id,
                title: title,
                revision: revision,
                format: format,
                author: author,
                attribution: attribution,
                description: description,
                sourceLanguage: sourceLanguage,
                isUpdatable: isUpdatable,
                indexUrl: indexUrl,
                downloadUrl: downloadUrl,
                stylesCss: stylesCss,
                enabled: enabled,
                priority: priority,
                importedAt: importedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String revision,
                required int format,
                Value<String?> author = const Value.absent(),
                Value<String?> attribution = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> sourceLanguage = const Value.absent(),
                Value<bool> isUpdatable = const Value.absent(),
                Value<String?> indexUrl = const Value.absent(),
                Value<String?> downloadUrl = const Value.absent(),
                Value<String> stylesCss = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> importedAt = const Value.absent(),
              }) => DictionariesCompanion.insert(
                id: id,
                title: title,
                revision: revision,
                format: format,
                author: author,
                attribution: attribution,
                description: description,
                sourceLanguage: sourceLanguage,
                isUpdatable: isUpdatable,
                indexUrl: indexUrl,
                downloadUrl: downloadUrl,
                stylesCss: stylesCss,
                enabled: enabled,
                priority: priority,
                importedAt: importedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DictionariesTable, Dictionary>(table),
                  BaseReferences<_$AppDb, $DictionariesTable, Dictionary>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $DictionariesTable,
      Dictionary,
      $$DictionariesTableFilterComposer,
      $$DictionariesTableOrderingComposer,
      $$DictionariesTableAnnotationComposer,
      $$DictionariesTableCreateCompanionBuilder,
      $$DictionariesTableUpdateCompanionBuilder,
      (Dictionary, BaseReferences<_$AppDb, $DictionariesTable, Dictionary>),
      Dictionary,
      PrefetchHooks Function()
    >;
typedef $$TermsTableCreateCompanionBuilder = TermsCompanion Function({
  Value<int> id,
  required int dictId,
  required String expression,
  required String reading,
  required String definitionTags,
  required String rules,
  required int score,
  required String glossary,
  Value<int?> sequence,
  required String termTags,
});
typedef $$TermsTableUpdateCompanionBuilder = TermsCompanion Function({
  Value<int> id,
  Value<int> dictId,
  Value<String> expression,
  Value<String> reading,
  Value<String> definitionTags,
  Value<String> rules,
  Value<int> score,
  Value<String> glossary,
  Value<int?> sequence,
  Value<String> termTags,
});

class $$TermsTableFilterComposer extends Composer<_$AppDb, $TermsTable> {
  $$TermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionTags => $composableBuilder(
    column: $table.definitionTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glossary => $composableBuilder(
    column: $table.glossary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termTags => $composableBuilder(
    column: $table.termTags,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TermsTableOrderingComposer extends Composer<_$AppDb, $TermsTable> {
  $$TermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionTags => $composableBuilder(
    column: $table.definitionTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rules => $composableBuilder(
    column: $table.rules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glossary => $composableBuilder(
    column: $table.glossary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termTags => $composableBuilder(
    column: $table.termTags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TermsTableAnnotationComposer extends Composer<_$AppDb, $TermsTable> {
  $$TermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictId =>
      $composableBuilder(column: $table.dictId, builder: (column) => column);

  GeneratedColumn<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get definitionTags => $composableBuilder(
    column: $table.definitionTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rules =>
      $composableBuilder(column: $table.rules, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get glossary =>
      $composableBuilder(column: $table.glossary, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get termTags =>
      $composableBuilder(column: $table.termTags, builder: (column) => column);
}

class $$TermsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $TermsTable,
          Term,
          $$TermsTableFilterComposer,
          $$TermsTableOrderingComposer,
          $$TermsTableAnnotationComposer,
          $$TermsTableCreateCompanionBuilder,
          $$TermsTableUpdateCompanionBuilder,
          (Term, BaseReferences<_$AppDb, $TermsTable, Term>),
          Term,
          PrefetchHooks Function()
        > {
  $$TermsTableTableManager(_$AppDb db, $TermsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictId = const Value.absent(),
                Value<String> expression = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> definitionTags = const Value.absent(),
                Value<String> rules = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String> glossary = const Value.absent(),
                Value<int?> sequence = const Value.absent(),
                Value<String> termTags = const Value.absent(),
              }) => TermsCompanion(
                id: id,
                dictId: dictId,
                expression: expression,
                reading: reading,
                definitionTags: definitionTags,
                rules: rules,
                score: score,
                glossary: glossary,
                sequence: sequence,
                termTags: termTags,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictId,
                required String expression,
                required String reading,
                required String definitionTags,
                required String rules,
                required int score,
                required String glossary,
                Value<int?> sequence = const Value.absent(),
                required String termTags,
              }) => TermsCompanion.insert(
                id: id,
                dictId: dictId,
                expression: expression,
                reading: reading,
                definitionTags: definitionTags,
                rules: rules,
                score: score,
                glossary: glossary,
                sequence: sequence,
                termTags: termTags,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TermsTable, Term>(table),
                  BaseReferences<_$AppDb, $TermsTable, Term>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TermsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $TermsTable,
      Term,
      $$TermsTableFilterComposer,
      $$TermsTableOrderingComposer,
      $$TermsTableAnnotationComposer,
      $$TermsTableCreateCompanionBuilder,
      $$TermsTableUpdateCompanionBuilder,
      (Term, BaseReferences<_$AppDb, $TermsTable, Term>),
      Term,
      PrefetchHooks Function()
    >;
typedef $$TermMetaTableCreateCompanionBuilder = TermMetaCompanion Function({
  Value<int> id,
  required int dictId,
  required String expression,
  required String mode,
  required String data,
});
typedef $$TermMetaTableUpdateCompanionBuilder = TermMetaCompanion Function({
  Value<int> id,
  Value<int> dictId,
  Value<String> expression,
  Value<String> mode,
  Value<String> data,
});

class $$TermMetaTableFilterComposer extends Composer<_$AppDb, $TermMetaTable> {
  $$TermMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TermMetaTableOrderingComposer
    extends Composer<_$AppDb, $TermMetaTable> {
  $$TermMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TermMetaTableAnnotationComposer
    extends Composer<_$AppDb, $TermMetaTable> {
  $$TermMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictId =>
      $composableBuilder(column: $table.dictId, builder: (column) => column);

  GeneratedColumn<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$TermMetaTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $TermMetaTable,
          TermMetaData,
          $$TermMetaTableFilterComposer,
          $$TermMetaTableOrderingComposer,
          $$TermMetaTableAnnotationComposer,
          $$TermMetaTableCreateCompanionBuilder,
          $$TermMetaTableUpdateCompanionBuilder,
          (TermMetaData, BaseReferences<_$AppDb, $TermMetaTable, TermMetaData>),
          TermMetaData,
          PrefetchHooks Function()
        > {
  $$TermMetaTableTableManager(_$AppDb db, $TermMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TermMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TermMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TermMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictId = const Value.absent(),
                Value<String> expression = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> data = const Value.absent(),
              }) => TermMetaCompanion(
                id: id,
                dictId: dictId,
                expression: expression,
                mode: mode,
                data: data,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictId,
                required String expression,
                required String mode,
                required String data,
              }) => TermMetaCompanion.insert(
                id: id,
                dictId: dictId,
                expression: expression,
                mode: mode,
                data: data,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TermMetaTable, TermMetaData>(table),
                  BaseReferences<_$AppDb, $TermMetaTable, TermMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TermMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $TermMetaTable,
      TermMetaData,
      $$TermMetaTableFilterComposer,
      $$TermMetaTableOrderingComposer,
      $$TermMetaTableAnnotationComposer,
      $$TermMetaTableCreateCompanionBuilder,
      $$TermMetaTableUpdateCompanionBuilder,
      (TermMetaData, BaseReferences<_$AppDb, $TermMetaTable, TermMetaData>),
      TermMetaData,
      PrefetchHooks Function()
    >;
typedef $$KanjiTableCreateCompanionBuilder = KanjiCompanion Function({
  Value<int> id,
  required int dictId,
  required String character,
  required String onyomi,
  required String kunyomi,
  required String tags,
  required String meanings,
  required String stats,
});
typedef $$KanjiTableUpdateCompanionBuilder = KanjiCompanion Function({
  Value<int> id,
  Value<int> dictId,
  Value<String> character,
  Value<String> onyomi,
  Value<String> kunyomi,
  Value<String> tags,
  Value<String> meanings,
  Value<String> stats,
});

class $$KanjiTableFilterComposer extends Composer<_$AppDb, $KanjiTable> {
  $$KanjiTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get onyomi => $composableBuilder(
    column: $table.onyomi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kunyomi => $composableBuilder(
    column: $table.kunyomi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stats => $composableBuilder(
    column: $table.stats,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KanjiTableOrderingComposer extends Composer<_$AppDb, $KanjiTable> {
  $$KanjiTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get onyomi => $composableBuilder(
    column: $table.onyomi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kunyomi => $composableBuilder(
    column: $table.kunyomi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stats => $composableBuilder(
    column: $table.stats,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KanjiTableAnnotationComposer extends Composer<_$AppDb, $KanjiTable> {
  $$KanjiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictId =>
      $composableBuilder(column: $table.dictId, builder: (column) => column);

  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get onyomi =>
      $composableBuilder(column: $table.onyomi, builder: (column) => column);

  GeneratedColumn<String> get kunyomi =>
      $composableBuilder(column: $table.kunyomi, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumn<String> get stats =>
      $composableBuilder(column: $table.stats, builder: (column) => column);
}

class $$KanjiTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $KanjiTable,
          KanjiData,
          $$KanjiTableFilterComposer,
          $$KanjiTableOrderingComposer,
          $$KanjiTableAnnotationComposer,
          $$KanjiTableCreateCompanionBuilder,
          $$KanjiTableUpdateCompanionBuilder,
          (KanjiData, BaseReferences<_$AppDb, $KanjiTable, KanjiData>),
          KanjiData,
          PrefetchHooks Function()
        > {
  $$KanjiTableTableManager(_$AppDb db, $KanjiTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictId = const Value.absent(),
                Value<String> character = const Value.absent(),
                Value<String> onyomi = const Value.absent(),
                Value<String> kunyomi = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> meanings = const Value.absent(),
                Value<String> stats = const Value.absent(),
              }) => KanjiCompanion(
                id: id,
                dictId: dictId,
                character: character,
                onyomi: onyomi,
                kunyomi: kunyomi,
                tags: tags,
                meanings: meanings,
                stats: stats,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictId,
                required String character,
                required String onyomi,
                required String kunyomi,
                required String tags,
                required String meanings,
                required String stats,
              }) => KanjiCompanion.insert(
                id: id,
                dictId: dictId,
                character: character,
                onyomi: onyomi,
                kunyomi: kunyomi,
                tags: tags,
                meanings: meanings,
                stats: stats,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KanjiTable, KanjiData>(table),
                  BaseReferences<_$AppDb, $KanjiTable, KanjiData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KanjiTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $KanjiTable,
      KanjiData,
      $$KanjiTableFilterComposer,
      $$KanjiTableOrderingComposer,
      $$KanjiTableAnnotationComposer,
      $$KanjiTableCreateCompanionBuilder,
      $$KanjiTableUpdateCompanionBuilder,
      (KanjiData, BaseReferences<_$AppDb, $KanjiTable, KanjiData>),
      KanjiData,
      PrefetchHooks Function()
    >;
typedef $$KanjiMetaTableCreateCompanionBuilder = KanjiMetaCompanion Function({
  Value<int> id,
  required int dictId,
  required String character,
  required String mode,
  required String data,
});
typedef $$KanjiMetaTableUpdateCompanionBuilder = KanjiMetaCompanion Function({
  Value<int> id,
  Value<int> dictId,
  Value<String> character,
  Value<String> mode,
  Value<String> data,
});

class $$KanjiMetaTableFilterComposer
    extends Composer<_$AppDb, $KanjiMetaTable> {
  $$KanjiMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KanjiMetaTableOrderingComposer
    extends Composer<_$AppDb, $KanjiMetaTable> {
  $$KanjiMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KanjiMetaTableAnnotationComposer
    extends Composer<_$AppDb, $KanjiMetaTable> {
  $$KanjiMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictId =>
      $composableBuilder(column: $table.dictId, builder: (column) => column);

  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$KanjiMetaTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $KanjiMetaTable,
          KanjiMetaData,
          $$KanjiMetaTableFilterComposer,
          $$KanjiMetaTableOrderingComposer,
          $$KanjiMetaTableAnnotationComposer,
          $$KanjiMetaTableCreateCompanionBuilder,
          $$KanjiMetaTableUpdateCompanionBuilder,
          (
            KanjiMetaData,
            BaseReferences<_$AppDb, $KanjiMetaTable, KanjiMetaData>,
          ),
          KanjiMetaData,
          PrefetchHooks Function()
        > {
  $$KanjiMetaTableTableManager(_$AppDb db, $KanjiMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictId = const Value.absent(),
                Value<String> character = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> data = const Value.absent(),
              }) => KanjiMetaCompanion(
                id: id,
                dictId: dictId,
                character: character,
                mode: mode,
                data: data,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictId,
                required String character,
                required String mode,
                required String data,
              }) => KanjiMetaCompanion.insert(
                id: id,
                dictId: dictId,
                character: character,
                mode: mode,
                data: data,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KanjiMetaTable, KanjiMetaData>(table),
                  BaseReferences<_$AppDb, $KanjiMetaTable, KanjiMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KanjiMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $KanjiMetaTable,
      KanjiMetaData,
      $$KanjiMetaTableFilterComposer,
      $$KanjiMetaTableOrderingComposer,
      $$KanjiMetaTableAnnotationComposer,
      $$KanjiMetaTableCreateCompanionBuilder,
      $$KanjiMetaTableUpdateCompanionBuilder,
      (KanjiMetaData, BaseReferences<_$AppDb, $KanjiMetaTable, KanjiMetaData>),
      KanjiMetaData,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required int dictId,
  required String name,
  required String category,
  required int sortOrder,
  required String notes,
  required int score,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<int> dictId,
  Value<String> name,
  Value<String> category,
  Value<int> sortOrder,
  Value<String> notes,
  Value<int> score,
});

class $$TagsTableFilterComposer extends Composer<_$AppDb, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDb, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictId => $composableBuilder(
    column: $table.dictId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer extends Composer<_$AppDb, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictId =>
      $composableBuilder(column: $table.dictId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDb, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDb db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> score = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                dictId: dictId,
                name: name,
                category: category,
                sortOrder: sortOrder,
                notes: notes,
                score: score,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictId,
                required String name,
                required String category,
                required int sortOrder,
                required String notes,
                required int score,
              }) => TagsCompanion.insert(
                id: id,
                dictId: dictId,
                name: name,
                category: category,
                sortOrder: sortOrder,
                notes: notes,
                score: score,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  BaseReferences<_$AppDb, $TagsTable, Tag>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDb, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$DictionariesTableTableManager get dictionaries =>
      $$DictionariesTableTableManager(_db, _db.dictionaries);
  $$TermsTableTableManager get terms =>
      $$TermsTableTableManager(_db, _db.terms);
  $$TermMetaTableTableManager get termMeta =>
      $$TermMetaTableTableManager(_db, _db.termMeta);
  $$KanjiTableTableManager get kanji =>
      $$KanjiTableTableManager(_db, _db.kanji);
  $$KanjiMetaTableTableManager get kanjiMeta =>
      $$KanjiMetaTableTableManager(_db, _db.kanjiMeta);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
}
