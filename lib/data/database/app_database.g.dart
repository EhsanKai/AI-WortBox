// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DecksTable extends Decks with TableInfo<$DecksTable, DeckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceLanguageMeta = const VerificationMeta(
    'sourceLanguage',
  );
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
    'source_language',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionLanguageMeta =
      const VerificationMeta('definitionLanguage');
  @override
  late final GeneratedColumn<String> definitionLanguage =
      GeneratedColumn<String>(
        'definition_language',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 2,
          maxTextLength: 16,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dailyNewCardLimitMeta = const VerificationMeta(
    'dailyNewCardLimit',
  );
  @override
  late final GeneratedColumn<int> dailyNewCardLimit = GeneratedColumn<int>(
    'daily_new_card_limit',
    aliasedName,
    false,
    check: () => ComparableExpr(dailyNewCardLimit).isBetweenValues(0, 1000),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceLanguage,
    definitionLanguage,
    dailyNewCardLimit,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_language')) {
      context.handle(
        _sourceLanguageMeta,
        sourceLanguage.isAcceptableOrUnknown(
          data['source_language']!,
          _sourceLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceLanguageMeta);
    }
    if (data.containsKey('definition_language')) {
      context.handle(
        _definitionLanguageMeta,
        definitionLanguage.isAcceptableOrUnknown(
          data['definition_language']!,
          _definitionLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionLanguageMeta);
    }
    if (data.containsKey('daily_new_card_limit')) {
      context.handle(
        _dailyNewCardLimitMeta,
        dailyNewCardLimit.isAcceptableOrUnknown(
          data['daily_new_card_limit']!,
          _dailyNewCardLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyNewCardLimitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      )!,
      definitionLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_language'],
      )!,
      dailyNewCardLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_new_card_limit'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class DeckRow extends DataClass implements Insertable<DeckRow> {
  final String id;
  final String name;
  final String sourceLanguage;
  final String definitionLanguage;
  final int dailyNewCardLimit;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DeckRow({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.definitionLanguage,
    required this.dailyNewCardLimit,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['source_language'] = Variable<String>(sourceLanguage);
    map['definition_language'] = Variable<String>(definitionLanguage);
    map['daily_new_card_limit'] = Variable<int>(dailyNewCardLimit);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      sourceLanguage: Value(sourceLanguage),
      definitionLanguage: Value(definitionLanguage),
      dailyNewCardLimit: Value(dailyNewCardLimit),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      definitionLanguage: serializer.fromJson<String>(
        json['definitionLanguage'],
      ),
      dailyNewCardLimit: serializer.fromJson<int>(json['dailyNewCardLimit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'definitionLanguage': serializer.toJson<String>(definitionLanguage),
      'dailyNewCardLimit': serializer.toJson<int>(dailyNewCardLimit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeckRow copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? definitionLanguage,
    int? dailyNewCardLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DeckRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    definitionLanguage: definitionLanguage ?? this.definitionLanguage,
    dailyNewCardLimit: dailyNewCardLimit ?? this.dailyNewCardLimit,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeckRow copyWithCompanion(DecksCompanion data) {
    return DeckRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      definitionLanguage: data.definitionLanguage.present
          ? data.definitionLanguage.value
          : this.definitionLanguage,
      dailyNewCardLimit: data.dailyNewCardLimit.present
          ? data.dailyNewCardLimit.value
          : this.dailyNewCardLimit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('definitionLanguage: $definitionLanguage, ')
          ..write('dailyNewCardLimit: $dailyNewCardLimit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    sourceLanguage,
    definitionLanguage,
    dailyNewCardLimit,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceLanguage == this.sourceLanguage &&
          other.definitionLanguage == this.definitionLanguage &&
          other.dailyNewCardLimit == this.dailyNewCardLimit &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DecksCompanion extends UpdateCompanion<DeckRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> sourceLanguage;
  final Value<String> definitionLanguage;
  final Value<int> dailyNewCardLimit;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.definitionLanguage = const Value.absent(),
    this.dailyNewCardLimit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksCompanion.insert({
    required String id,
    required String name,
    required String sourceLanguage,
    required String definitionLanguage,
    required int dailyNewCardLimit,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sourceLanguage = Value(sourceLanguage),
       definitionLanguage = Value(definitionLanguage),
       dailyNewCardLimit = Value(dailyNewCardLimit),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DeckRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sourceLanguage,
    Expression<String>? definitionLanguage,
    Expression<int>? dailyNewCardLimit,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (definitionLanguage != null) 'definition_language': definitionLanguage,
      if (dailyNewCardLimit != null) 'daily_new_card_limit': dailyNewCardLimit,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? sourceLanguage,
    Value<String>? definitionLanguage,
    Value<int>? dailyNewCardLimit,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      definitionLanguage: definitionLanguage ?? this.definitionLanguage,
      dailyNewCardLimit: dailyNewCardLimit ?? this.dailyNewCardLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (definitionLanguage.present) {
      map['definition_language'] = Variable<String>(definitionLanguage.value);
    }
    if (dailyNewCardLimit.present) {
      map['daily_new_card_limit'] = Variable<int>(dailyNewCardLimit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('definitionLanguage: $definitionLanguage, ')
          ..write('dailyNewCardLimit: $dailyNewCardLimit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabularyEntriesTable extends VocabularyEntries
    with TableInfo<$VocabularyEntriesTable, VocabularyEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalMeta = const VerificationMeta(
    'original',
  );
  @override
  late final GeneratedColumn<String> original = GeneratedColumn<String>(
    'original',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedMeta = const VerificationMeta(
    'normalized',
  );
  @override
  late final GeneratedColumn<String> normalized = GeneratedColumn<String>(
    'normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lemmaMeta = const VerificationMeta('lemma');
  @override
  late final GeneratedColumn<String> lemma = GeneratedColumn<String>(
    'lemma',
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
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionLanguageMeta =
      const VerificationMeta('definitionLanguage');
  @override
  late final GeneratedColumn<String> definitionLanguage =
      GeneratedColumn<String>(
        'definition_language',
        aliasedName,
        false,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 2,
          maxTextLength: 16,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleSentenceMeta = const VerificationMeta(
    'exampleSentence',
  );
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
    'example_sentence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleTranslationMeta =
      const VerificationMeta('exampleTranslation');
  @override
  late final GeneratedColumn<String> exampleTranslation =
      GeneratedColumn<String>(
        'example_translation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _grammarInfoMeta = const VerificationMeta(
    'grammarInfo',
  );
  @override
  late final GeneratedColumn<String> grammarInfo = GeneratedColumn<String>(
    'grammar_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceContextMeta = const VerificationMeta(
    'sourceContext',
  );
  @override
  late final GeneratedColumn<String> sourceContext = GeneratedColumn<String>(
    'source_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VocabularySourceType, String>
  sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VocabularySourceType>(
        $VocabularyEntriesTable.$convertersourceType,
      );
  @override
  late final GeneratedColumnWithTypeConverter<EnrichmentStatus, String>
  enrichmentStatus =
      GeneratedColumn<String>(
        'enrichment_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<EnrichmentStatus>(
        $VocabularyEntriesTable.$converterenrichmentStatus,
      );
  static const VerificationMeta _enrichmentMetadataMeta =
      const VerificationMeta('enrichmentMetadata');
  @override
  late final GeneratedColumn<String> enrichmentMetadata =
      GeneratedColumn<String>(
        'enrichment_metadata',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _userEditedAtMeta = const VerificationMeta(
    'userEditedAt',
  );
  @override
  late final GeneratedColumn<DateTime> userEditedAt = GeneratedColumn<DateTime>(
    'user_edited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markedDifficultAtMeta = const VerificationMeta(
    'markedDifficultAt',
  );
  @override
  late final GeneratedColumn<DateTime> markedDifficultAt =
      GeneratedColumn<DateTime>(
        'marked_difficult_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _searchKeyMeta = const VerificationMeta(
    'searchKey',
  );
  @override
  late final GeneratedColumn<String> searchKey = GeneratedColumn<String>(
    'search_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    original,
    normalized,
    lemma,
    sourceLanguage,
    definitionLanguage,
    partOfSpeech,
    exampleSentence,
    exampleTranslation,
    grammarInfo,
    notes,
    sourceContext,
    sourceType,
    enrichmentStatus,
    enrichmentMetadata,
    userEditedAt,
    createdAt,
    updatedAt,
    markedDifficultAt,
    searchKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('original')) {
      context.handle(
        _originalMeta,
        original.isAcceptableOrUnknown(data['original']!, _originalMeta),
      );
    } else if (isInserting) {
      context.missing(_originalMeta);
    }
    if (data.containsKey('normalized')) {
      context.handle(
        _normalizedMeta,
        normalized.isAcceptableOrUnknown(data['normalized']!, _normalizedMeta),
      );
    } else if (isInserting) {
      context.missing(_normalizedMeta);
    }
    if (data.containsKey('lemma')) {
      context.handle(
        _lemmaMeta,
        lemma.isAcceptableOrUnknown(data['lemma']!, _lemmaMeta),
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
    } else if (isInserting) {
      context.missing(_sourceLanguageMeta);
    }
    if (data.containsKey('definition_language')) {
      context.handle(
        _definitionLanguageMeta,
        definitionLanguage.isAcceptableOrUnknown(
          data['definition_language']!,
          _definitionLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionLanguageMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
        _exampleSentenceMeta,
        exampleSentence.isAcceptableOrUnknown(
          data['example_sentence']!,
          _exampleSentenceMeta,
        ),
      );
    }
    if (data.containsKey('example_translation')) {
      context.handle(
        _exampleTranslationMeta,
        exampleTranslation.isAcceptableOrUnknown(
          data['example_translation']!,
          _exampleTranslationMeta,
        ),
      );
    }
    if (data.containsKey('grammar_info')) {
      context.handle(
        _grammarInfoMeta,
        grammarInfo.isAcceptableOrUnknown(
          data['grammar_info']!,
          _grammarInfoMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source_context')) {
      context.handle(
        _sourceContextMeta,
        sourceContext.isAcceptableOrUnknown(
          data['source_context']!,
          _sourceContextMeta,
        ),
      );
    }
    if (data.containsKey('enrichment_metadata')) {
      context.handle(
        _enrichmentMetadataMeta,
        enrichmentMetadata.isAcceptableOrUnknown(
          data['enrichment_metadata']!,
          _enrichmentMetadataMeta,
        ),
      );
    }
    if (data.containsKey('user_edited_at')) {
      context.handle(
        _userEditedAtMeta,
        userEditedAt.isAcceptableOrUnknown(
          data['user_edited_at']!,
          _userEditedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('marked_difficult_at')) {
      context.handle(
        _markedDifficultAtMeta,
        markedDifficultAt.isAcceptableOrUnknown(
          data['marked_difficult_at']!,
          _markedDifficultAtMeta,
        ),
      );
    }
    if (data.containsKey('search_key')) {
      context.handle(
        _searchKeyMeta,
        searchKey.isAcceptableOrUnknown(data['search_key']!, _searchKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      original: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original'],
      )!,
      normalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized'],
      )!,
      lemma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lemma'],
      ),
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      )!,
      definitionLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_language'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      exampleSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence'],
      ),
      exampleTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_translation'],
      ),
      grammarInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grammar_info'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sourceContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_context'],
      ),
      sourceType: $VocabularyEntriesTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      enrichmentStatus: $VocabularyEntriesTable.$converterenrichmentStatus
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}enrichment_status'],
            )!,
          ),
      enrichmentMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enrichment_metadata'],
      ),
      userEditedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}user_edited_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      markedDifficultAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}marked_difficult_at'],
      ),
      searchKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_key'],
      )!,
    );
  }

  @override
  $VocabularyEntriesTable createAlias(String alias) {
    return $VocabularyEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<VocabularySourceType, String, String>
  $convertersourceType = const EnumNameConverter<VocabularySourceType>(
    VocabularySourceType.values,
  );
  static JsonTypeConverter2<EnrichmentStatus, String, String>
  $converterenrichmentStatus = const EnumNameConverter<EnrichmentStatus>(
    EnrichmentStatus.values,
  );
}

class VocabularyEntryRow extends DataClass
    implements Insertable<VocabularyEntryRow> {
  final String id;
  final String deckId;
  final String original;
  final String normalized;
  final String? lemma;
  final String sourceLanguage;
  final String definitionLanguage;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? grammarInfo;
  final String? notes;
  final String? sourceContext;
  final VocabularySourceType sourceType;
  final EnrichmentStatus enrichmentStatus;

  /// JSON-encoded `EnrichmentMetadata`.
  final String? enrichmentMetadata;
  final DateTime? userEditedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// UTC time the user marked the word as difficult; null when not marked
  /// (schema v2). A manual mark only: nothing sets it automatically.
  final DateTime? markedDifficultAt;

  /// Comparison keys of the word, base form and meanings, one per line, for
  /// search (schema v2). Derived from the content and rewritten by the
  /// repository on every content change; never shown.
  final String searchKey;
  const VocabularyEntryRow({
    required this.id,
    required this.deckId,
    required this.original,
    required this.normalized,
    this.lemma,
    required this.sourceLanguage,
    required this.definitionLanguage,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleTranslation,
    this.grammarInfo,
    this.notes,
    this.sourceContext,
    required this.sourceType,
    required this.enrichmentStatus,
    this.enrichmentMetadata,
    this.userEditedAt,
    required this.createdAt,
    required this.updatedAt,
    this.markedDifficultAt,
    required this.searchKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['original'] = Variable<String>(original);
    map['normalized'] = Variable<String>(normalized);
    if (!nullToAbsent || lemma != null) {
      map['lemma'] = Variable<String>(lemma);
    }
    map['source_language'] = Variable<String>(sourceLanguage);
    map['definition_language'] = Variable<String>(definitionLanguage);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    if (!nullToAbsent || exampleSentence != null) {
      map['example_sentence'] = Variable<String>(exampleSentence);
    }
    if (!nullToAbsent || exampleTranslation != null) {
      map['example_translation'] = Variable<String>(exampleTranslation);
    }
    if (!nullToAbsent || grammarInfo != null) {
      map['grammar_info'] = Variable<String>(grammarInfo);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || sourceContext != null) {
      map['source_context'] = Variable<String>(sourceContext);
    }
    {
      map['source_type'] = Variable<String>(
        $VocabularyEntriesTable.$convertersourceType.toSql(sourceType),
      );
    }
    {
      map['enrichment_status'] = Variable<String>(
        $VocabularyEntriesTable.$converterenrichmentStatus.toSql(
          enrichmentStatus,
        ),
      );
    }
    if (!nullToAbsent || enrichmentMetadata != null) {
      map['enrichment_metadata'] = Variable<String>(enrichmentMetadata);
    }
    if (!nullToAbsent || userEditedAt != null) {
      map['user_edited_at'] = Variable<DateTime>(userEditedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || markedDifficultAt != null) {
      map['marked_difficult_at'] = Variable<DateTime>(markedDifficultAt);
    }
    map['search_key'] = Variable<String>(searchKey);
    return map;
  }

  VocabularyEntriesCompanion toCompanion(bool nullToAbsent) {
    return VocabularyEntriesCompanion(
      id: Value(id),
      deckId: Value(deckId),
      original: Value(original),
      normalized: Value(normalized),
      lemma: lemma == null && nullToAbsent
          ? const Value.absent()
          : Value(lemma),
      sourceLanguage: Value(sourceLanguage),
      definitionLanguage: Value(definitionLanguage),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      exampleSentence: exampleSentence == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleSentence),
      exampleTranslation: exampleTranslation == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleTranslation),
      grammarInfo: grammarInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(grammarInfo),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sourceContext: sourceContext == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceContext),
      sourceType: Value(sourceType),
      enrichmentStatus: Value(enrichmentStatus),
      enrichmentMetadata: enrichmentMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(enrichmentMetadata),
      userEditedAt: userEditedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(userEditedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      markedDifficultAt: markedDifficultAt == null && nullToAbsent
          ? const Value.absent()
          : Value(markedDifficultAt),
      searchKey: Value(searchKey),
    );
  }

  factory VocabularyEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyEntryRow(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      original: serializer.fromJson<String>(json['original']),
      normalized: serializer.fromJson<String>(json['normalized']),
      lemma: serializer.fromJson<String?>(json['lemma']),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      definitionLanguage: serializer.fromJson<String>(
        json['definitionLanguage'],
      ),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      exampleSentence: serializer.fromJson<String?>(json['exampleSentence']),
      exampleTranslation: serializer.fromJson<String?>(
        json['exampleTranslation'],
      ),
      grammarInfo: serializer.fromJson<String?>(json['grammarInfo']),
      notes: serializer.fromJson<String?>(json['notes']),
      sourceContext: serializer.fromJson<String?>(json['sourceContext']),
      sourceType: $VocabularyEntriesTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      enrichmentStatus: $VocabularyEntriesTable.$converterenrichmentStatus
          .fromJson(serializer.fromJson<String>(json['enrichmentStatus'])),
      enrichmentMetadata: serializer.fromJson<String?>(
        json['enrichmentMetadata'],
      ),
      userEditedAt: serializer.fromJson<DateTime?>(json['userEditedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      markedDifficultAt: serializer.fromJson<DateTime?>(
        json['markedDifficultAt'],
      ),
      searchKey: serializer.fromJson<String>(json['searchKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'original': serializer.toJson<String>(original),
      'normalized': serializer.toJson<String>(normalized),
      'lemma': serializer.toJson<String?>(lemma),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'definitionLanguage': serializer.toJson<String>(definitionLanguage),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'exampleSentence': serializer.toJson<String?>(exampleSentence),
      'exampleTranslation': serializer.toJson<String?>(exampleTranslation),
      'grammarInfo': serializer.toJson<String?>(grammarInfo),
      'notes': serializer.toJson<String?>(notes),
      'sourceContext': serializer.toJson<String?>(sourceContext),
      'sourceType': serializer.toJson<String>(
        $VocabularyEntriesTable.$convertersourceType.toJson(sourceType),
      ),
      'enrichmentStatus': serializer.toJson<String>(
        $VocabularyEntriesTable.$converterenrichmentStatus.toJson(
          enrichmentStatus,
        ),
      ),
      'enrichmentMetadata': serializer.toJson<String?>(enrichmentMetadata),
      'userEditedAt': serializer.toJson<DateTime?>(userEditedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'markedDifficultAt': serializer.toJson<DateTime?>(markedDifficultAt),
      'searchKey': serializer.toJson<String>(searchKey),
    };
  }

  VocabularyEntryRow copyWith({
    String? id,
    String? deckId,
    String? original,
    String? normalized,
    Value<String?> lemma = const Value.absent(),
    String? sourceLanguage,
    String? definitionLanguage,
    Value<String?> partOfSpeech = const Value.absent(),
    Value<String?> exampleSentence = const Value.absent(),
    Value<String?> exampleTranslation = const Value.absent(),
    Value<String?> grammarInfo = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> sourceContext = const Value.absent(),
    VocabularySourceType? sourceType,
    EnrichmentStatus? enrichmentStatus,
    Value<String?> enrichmentMetadata = const Value.absent(),
    Value<DateTime?> userEditedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> markedDifficultAt = const Value.absent(),
    String? searchKey,
  }) => VocabularyEntryRow(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    original: original ?? this.original,
    normalized: normalized ?? this.normalized,
    lemma: lemma.present ? lemma.value : this.lemma,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    definitionLanguage: definitionLanguage ?? this.definitionLanguage,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    exampleSentence: exampleSentence.present
        ? exampleSentence.value
        : this.exampleSentence,
    exampleTranslation: exampleTranslation.present
        ? exampleTranslation.value
        : this.exampleTranslation,
    grammarInfo: grammarInfo.present ? grammarInfo.value : this.grammarInfo,
    notes: notes.present ? notes.value : this.notes,
    sourceContext: sourceContext.present
        ? sourceContext.value
        : this.sourceContext,
    sourceType: sourceType ?? this.sourceType,
    enrichmentStatus: enrichmentStatus ?? this.enrichmentStatus,
    enrichmentMetadata: enrichmentMetadata.present
        ? enrichmentMetadata.value
        : this.enrichmentMetadata,
    userEditedAt: userEditedAt.present ? userEditedAt.value : this.userEditedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    markedDifficultAt: markedDifficultAt.present
        ? markedDifficultAt.value
        : this.markedDifficultAt,
    searchKey: searchKey ?? this.searchKey,
  );
  VocabularyEntryRow copyWithCompanion(VocabularyEntriesCompanion data) {
    return VocabularyEntryRow(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      original: data.original.present ? data.original.value : this.original,
      normalized: data.normalized.present
          ? data.normalized.value
          : this.normalized,
      lemma: data.lemma.present ? data.lemma.value : this.lemma,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      definitionLanguage: data.definitionLanguage.present
          ? data.definitionLanguage.value
          : this.definitionLanguage,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      exampleTranslation: data.exampleTranslation.present
          ? data.exampleTranslation.value
          : this.exampleTranslation,
      grammarInfo: data.grammarInfo.present
          ? data.grammarInfo.value
          : this.grammarInfo,
      notes: data.notes.present ? data.notes.value : this.notes,
      sourceContext: data.sourceContext.present
          ? data.sourceContext.value
          : this.sourceContext,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      enrichmentStatus: data.enrichmentStatus.present
          ? data.enrichmentStatus.value
          : this.enrichmentStatus,
      enrichmentMetadata: data.enrichmentMetadata.present
          ? data.enrichmentMetadata.value
          : this.enrichmentMetadata,
      userEditedAt: data.userEditedAt.present
          ? data.userEditedAt.value
          : this.userEditedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      markedDifficultAt: data.markedDifficultAt.present
          ? data.markedDifficultAt.value
          : this.markedDifficultAt,
      searchKey: data.searchKey.present ? data.searchKey.value : this.searchKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntryRow(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('original: $original, ')
          ..write('normalized: $normalized, ')
          ..write('lemma: $lemma, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('definitionLanguage: $definitionLanguage, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('exampleTranslation: $exampleTranslation, ')
          ..write('grammarInfo: $grammarInfo, ')
          ..write('notes: $notes, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('sourceType: $sourceType, ')
          ..write('enrichmentStatus: $enrichmentStatus, ')
          ..write('enrichmentMetadata: $enrichmentMetadata, ')
          ..write('userEditedAt: $userEditedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('markedDifficultAt: $markedDifficultAt, ')
          ..write('searchKey: $searchKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    deckId,
    original,
    normalized,
    lemma,
    sourceLanguage,
    definitionLanguage,
    partOfSpeech,
    exampleSentence,
    exampleTranslation,
    grammarInfo,
    notes,
    sourceContext,
    sourceType,
    enrichmentStatus,
    enrichmentMetadata,
    userEditedAt,
    createdAt,
    updatedAt,
    markedDifficultAt,
    searchKey,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyEntryRow &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.original == this.original &&
          other.normalized == this.normalized &&
          other.lemma == this.lemma &&
          other.sourceLanguage == this.sourceLanguage &&
          other.definitionLanguage == this.definitionLanguage &&
          other.partOfSpeech == this.partOfSpeech &&
          other.exampleSentence == this.exampleSentence &&
          other.exampleTranslation == this.exampleTranslation &&
          other.grammarInfo == this.grammarInfo &&
          other.notes == this.notes &&
          other.sourceContext == this.sourceContext &&
          other.sourceType == this.sourceType &&
          other.enrichmentStatus == this.enrichmentStatus &&
          other.enrichmentMetadata == this.enrichmentMetadata &&
          other.userEditedAt == this.userEditedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.markedDifficultAt == this.markedDifficultAt &&
          other.searchKey == this.searchKey);
}

class VocabularyEntriesCompanion extends UpdateCompanion<VocabularyEntryRow> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> original;
  final Value<String> normalized;
  final Value<String?> lemma;
  final Value<String> sourceLanguage;
  final Value<String> definitionLanguage;
  final Value<String?> partOfSpeech;
  final Value<String?> exampleSentence;
  final Value<String?> exampleTranslation;
  final Value<String?> grammarInfo;
  final Value<String?> notes;
  final Value<String?> sourceContext;
  final Value<VocabularySourceType> sourceType;
  final Value<EnrichmentStatus> enrichmentStatus;
  final Value<String?> enrichmentMetadata;
  final Value<DateTime?> userEditedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> markedDifficultAt;
  final Value<String> searchKey;
  final Value<int> rowid;
  const VocabularyEntriesCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.original = const Value.absent(),
    this.normalized = const Value.absent(),
    this.lemma = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.definitionLanguage = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.exampleTranslation = const Value.absent(),
    this.grammarInfo = const Value.absent(),
    this.notes = const Value.absent(),
    this.sourceContext = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.enrichmentStatus = const Value.absent(),
    this.enrichmentMetadata = const Value.absent(),
    this.userEditedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.markedDifficultAt = const Value.absent(),
    this.searchKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyEntriesCompanion.insert({
    required String id,
    required String deckId,
    required String original,
    required String normalized,
    this.lemma = const Value.absent(),
    required String sourceLanguage,
    required String definitionLanguage,
    this.partOfSpeech = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.exampleTranslation = const Value.absent(),
    this.grammarInfo = const Value.absent(),
    this.notes = const Value.absent(),
    this.sourceContext = const Value.absent(),
    required VocabularySourceType sourceType,
    required EnrichmentStatus enrichmentStatus,
    this.enrichmentMetadata = const Value.absent(),
    this.userEditedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.markedDifficultAt = const Value.absent(),
    this.searchKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       original = Value(original),
       normalized = Value(normalized),
       sourceLanguage = Value(sourceLanguage),
       definitionLanguage = Value(definitionLanguage),
       sourceType = Value(sourceType),
       enrichmentStatus = Value(enrichmentStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VocabularyEntryRow> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? original,
    Expression<String>? normalized,
    Expression<String>? lemma,
    Expression<String>? sourceLanguage,
    Expression<String>? definitionLanguage,
    Expression<String>? partOfSpeech,
    Expression<String>? exampleSentence,
    Expression<String>? exampleTranslation,
    Expression<String>? grammarInfo,
    Expression<String>? notes,
    Expression<String>? sourceContext,
    Expression<String>? sourceType,
    Expression<String>? enrichmentStatus,
    Expression<String>? enrichmentMetadata,
    Expression<DateTime>? userEditedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? markedDifficultAt,
    Expression<String>? searchKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (original != null) 'original': original,
      if (normalized != null) 'normalized': normalized,
      if (lemma != null) 'lemma': lemma,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (definitionLanguage != null) 'definition_language': definitionLanguage,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (exampleTranslation != null) 'example_translation': exampleTranslation,
      if (grammarInfo != null) 'grammar_info': grammarInfo,
      if (notes != null) 'notes': notes,
      if (sourceContext != null) 'source_context': sourceContext,
      if (sourceType != null) 'source_type': sourceType,
      if (enrichmentStatus != null) 'enrichment_status': enrichmentStatus,
      if (enrichmentMetadata != null) 'enrichment_metadata': enrichmentMetadata,
      if (userEditedAt != null) 'user_edited_at': userEditedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (markedDifficultAt != null) 'marked_difficult_at': markedDifficultAt,
      if (searchKey != null) 'search_key': searchKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? original,
    Value<String>? normalized,
    Value<String?>? lemma,
    Value<String>? sourceLanguage,
    Value<String>? definitionLanguage,
    Value<String?>? partOfSpeech,
    Value<String?>? exampleSentence,
    Value<String?>? exampleTranslation,
    Value<String?>? grammarInfo,
    Value<String?>? notes,
    Value<String?>? sourceContext,
    Value<VocabularySourceType>? sourceType,
    Value<EnrichmentStatus>? enrichmentStatus,
    Value<String?>? enrichmentMetadata,
    Value<DateTime?>? userEditedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? markedDifficultAt,
    Value<String>? searchKey,
    Value<int>? rowid,
  }) {
    return VocabularyEntriesCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      original: original ?? this.original,
      normalized: normalized ?? this.normalized,
      lemma: lemma ?? this.lemma,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      definitionLanguage: definitionLanguage ?? this.definitionLanguage,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      grammarInfo: grammarInfo ?? this.grammarInfo,
      notes: notes ?? this.notes,
      sourceContext: sourceContext ?? this.sourceContext,
      sourceType: sourceType ?? this.sourceType,
      enrichmentStatus: enrichmentStatus ?? this.enrichmentStatus,
      enrichmentMetadata: enrichmentMetadata ?? this.enrichmentMetadata,
      userEditedAt: userEditedAt ?? this.userEditedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      markedDifficultAt: markedDifficultAt ?? this.markedDifficultAt,
      searchKey: searchKey ?? this.searchKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (original.present) {
      map['original'] = Variable<String>(original.value);
    }
    if (normalized.present) {
      map['normalized'] = Variable<String>(normalized.value);
    }
    if (lemma.present) {
      map['lemma'] = Variable<String>(lemma.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (definitionLanguage.present) {
      map['definition_language'] = Variable<String>(definitionLanguage.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (exampleTranslation.present) {
      map['example_translation'] = Variable<String>(exampleTranslation.value);
    }
    if (grammarInfo.present) {
      map['grammar_info'] = Variable<String>(grammarInfo.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sourceContext.present) {
      map['source_context'] = Variable<String>(sourceContext.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $VocabularyEntriesTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (enrichmentStatus.present) {
      map['enrichment_status'] = Variable<String>(
        $VocabularyEntriesTable.$converterenrichmentStatus.toSql(
          enrichmentStatus.value,
        ),
      );
    }
    if (enrichmentMetadata.present) {
      map['enrichment_metadata'] = Variable<String>(enrichmentMetadata.value);
    }
    if (userEditedAt.present) {
      map['user_edited_at'] = Variable<DateTime>(userEditedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (markedDifficultAt.present) {
      map['marked_difficult_at'] = Variable<DateTime>(markedDifficultAt.value);
    }
    if (searchKey.present) {
      map['search_key'] = Variable<String>(searchKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('original: $original, ')
          ..write('normalized: $normalized, ')
          ..write('lemma: $lemma, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('definitionLanguage: $definitionLanguage, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('exampleTranslation: $exampleTranslation, ')
          ..write('grammarInfo: $grammarInfo, ')
          ..write('notes: $notes, ')
          ..write('sourceContext: $sourceContext, ')
          ..write('sourceType: $sourceType, ')
          ..write('enrichmentStatus: $enrichmentStatus, ')
          ..write('enrichmentMetadata: $enrichmentMetadata, ')
          ..write('userEditedAt: $userEditedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('markedDifficultAt: $markedDifficultAt, ')
          ..write('searchKey: $searchKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabularyMeaningsTable extends VocabularyMeanings
    with TableInfo<$VocabularyMeaningsTable, VocabularyMeaningRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyMeaningsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vocabulary_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    position,
    meaning,
    explanation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_meanings';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyMeaningRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entryId, position},
  ];
  @override
  VocabularyMeaningRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyMeaningRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
    );
  }

  @override
  $VocabularyMeaningsTable createAlias(String alias) {
    return $VocabularyMeaningsTable(attachedDatabase, alias);
  }
}

class VocabularyMeaningRow extends DataClass
    implements Insertable<VocabularyMeaningRow> {
  final String id;
  final String entryId;
  final int position;
  final String meaning;
  final String? explanation;
  const VocabularyMeaningRow({
    required this.id,
    required this.entryId,
    required this.position,
    required this.meaning,
    this.explanation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['position'] = Variable<int>(position);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    return map;
  }

  VocabularyMeaningsCompanion toCompanion(bool nullToAbsent) {
    return VocabularyMeaningsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      position: Value(position),
      meaning: Value(meaning),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
    );
  }

  factory VocabularyMeaningRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyMeaningRow(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      position: serializer.fromJson<int>(json['position']),
      meaning: serializer.fromJson<String>(json['meaning']),
      explanation: serializer.fromJson<String?>(json['explanation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'position': serializer.toJson<int>(position),
      'meaning': serializer.toJson<String>(meaning),
      'explanation': serializer.toJson<String?>(explanation),
    };
  }

  VocabularyMeaningRow copyWith({
    String? id,
    String? entryId,
    int? position,
    String? meaning,
    Value<String?> explanation = const Value.absent(),
  }) => VocabularyMeaningRow(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    position: position ?? this.position,
    meaning: meaning ?? this.meaning,
    explanation: explanation.present ? explanation.value : this.explanation,
  );
  VocabularyMeaningRow copyWithCompanion(VocabularyMeaningsCompanion data) {
    return VocabularyMeaningRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      position: data.position.present ? data.position.value : this.position,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyMeaningRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('position: $position, ')
          ..write('meaning: $meaning, ')
          ..write('explanation: $explanation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, position, meaning, explanation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyMeaningRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.position == this.position &&
          other.meaning == this.meaning &&
          other.explanation == this.explanation);
}

class VocabularyMeaningsCompanion
    extends UpdateCompanion<VocabularyMeaningRow> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> position;
  final Value<String> meaning;
  final Value<String?> explanation;
  final Value<int> rowid;
  const VocabularyMeaningsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.position = const Value.absent(),
    this.meaning = const Value.absent(),
    this.explanation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyMeaningsCompanion.insert({
    required String id,
    required String entryId,
    required int position,
    required String meaning,
    this.explanation = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       position = Value(position),
       meaning = Value(meaning);
  static Insertable<VocabularyMeaningRow> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<int>? position,
    Expression<String>? meaning,
    Expression<String>? explanation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (position != null) 'position': position,
      if (meaning != null) 'meaning': meaning,
      if (explanation != null) 'explanation': explanation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyMeaningsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<int>? position,
    Value<String>? meaning,
    Value<String?>? explanation,
    Value<int>? rowid,
  }) {
    return VocabularyMeaningsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      position: position ?? this.position,
      meaning: meaning ?? this.meaning,
      explanation: explanation ?? this.explanation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyMeaningsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('position: $position, ')
          ..write('meaning: $meaning, ')
          ..write('explanation: $explanation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlashcardsTable extends Flashcards
    with TableInfo<$FlashcardsTable, FlashcardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vocabulary_entries (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardDirection, String> direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CardDirection>($FlashcardsTable.$converterdirection);
  @override
  late final GeneratedColumnWithTypeConverter<CardState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CardState>($FlashcardsTable.$converterstate);
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapseCountMeta = const VerificationMeta(
    'lapseCount',
  );
  @override
  late final GeneratedColumn<int> lapseCount = GeneratedColumn<int>(
    'lapse_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _schedulerVersionMeta = const VerificationMeta(
    'schedulerVersion',
  );
  @override
  late final GeneratedColumn<String> schedulerVersion = GeneratedColumn<String>(
    'scheduler_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    direction,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReviewedAt,
    reviewCount,
    lapseCount,
    schedulerVersion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcards';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    } else if (isInserting) {
      context.missing(_dueMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('lapse_count')) {
      context.handle(
        _lapseCountMeta,
        lapseCount.isAcceptableOrUnknown(data['lapse_count']!, _lapseCountMeta),
      );
    }
    if (data.containsKey('scheduler_version')) {
      context.handle(
        _schedulerVersionMeta,
        schedulerVersion.isAcceptableOrUnknown(
          data['scheduler_version']!,
          _schedulerVersionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entryId, direction},
  ];
  @override
  FlashcardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      direction: $FlashcardsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      state: $FlashcardsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      lapseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapse_count'],
      )!,
      schedulerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduler_version'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FlashcardsTable createAlias(String alias) {
    return $FlashcardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CardDirection, String, String> $converterdirection =
      const EnumNameConverter<CardDirection>(CardDirection.values);
  static JsonTypeConverter2<CardState, String, String> $converterstate =
      const EnumNameConverter<CardState>(CardState.values);
}

class FlashcardRow extends DataClass implements Insertable<FlashcardRow> {
  final String id;
  final String entryId;
  final CardDirection direction;
  final CardState state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final int lapseCount;
  final String? schedulerVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FlashcardRow({
    required this.id,
    required this.entryId,
    required this.direction,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReviewedAt,
    required this.reviewCount,
    required this.lapseCount,
    this.schedulerVersion,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    {
      map['direction'] = Variable<String>(
        $FlashcardsTable.$converterdirection.toSql(direction),
      );
    }
    {
      map['state'] = Variable<String>(
        $FlashcardsTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<DateTime>(due);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['review_count'] = Variable<int>(reviewCount);
    map['lapse_count'] = Variable<int>(lapseCount);
    if (!nullToAbsent || schedulerVersion != null) {
      map['scheduler_version'] = Variable<String>(schedulerVersion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FlashcardsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      direction: Value(direction),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      reviewCount: Value(reviewCount),
      lapseCount: Value(lapseCount),
      schedulerVersion: schedulerVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(schedulerVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FlashcardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardRow(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      direction: $FlashcardsTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      state: $FlashcardsTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      lapseCount: serializer.fromJson<int>(json['lapseCount']),
      schedulerVersion: serializer.fromJson<String?>(json['schedulerVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'direction': serializer.toJson<String>(
        $FlashcardsTable.$converterdirection.toJson(direction),
      ),
      'state': serializer.toJson<String>(
        $FlashcardsTable.$converterstate.toJson(state),
      ),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<DateTime>(due),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'lapseCount': serializer.toJson<int>(lapseCount),
      'schedulerVersion': serializer.toJson<String?>(schedulerVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FlashcardRow copyWith({
    String? id,
    String? entryId,
    CardDirection? direction,
    CardState? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    DateTime? due,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    int? reviewCount,
    int? lapseCount,
    Value<String?> schedulerVersion = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FlashcardRow(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    direction: direction ?? this.direction,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    due: due ?? this.due,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    reviewCount: reviewCount ?? this.reviewCount,
    lapseCount: lapseCount ?? this.lapseCount,
    schedulerVersion: schedulerVersion.present
        ? schedulerVersion.value
        : this.schedulerVersion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FlashcardRow copyWithCompanion(FlashcardsCompanion data) {
    return FlashcardRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      direction: data.direction.present ? data.direction.value : this.direction,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      lapseCount: data.lapseCount.present
          ? data.lapseCount.value
          : this.lapseCount,
      schedulerVersion: data.schedulerVersion.present
          ? data.schedulerVersion.value
          : this.schedulerVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('direction: $direction, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('schedulerVersion: $schedulerVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    direction,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReviewedAt,
    reviewCount,
    lapseCount,
    schedulerVersion,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.direction == this.direction &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.reviewCount == this.reviewCount &&
          other.lapseCount == this.lapseCount &&
          other.schedulerVersion == this.schedulerVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FlashcardsCompanion extends UpdateCompanion<FlashcardRow> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<CardDirection> direction;
  final Value<CardState> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<DateTime> due;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> reviewCount;
  final Value<int> lapseCount;
  final Value<String?> schedulerVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FlashcardsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.direction = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.schedulerVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardsCompanion.insert({
    required String id,
    required String entryId,
    required CardDirection direction,
    required CardState state,
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    required DateTime due,
    this.lastReviewedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lapseCount = const Value.absent(),
    this.schedulerVersion = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       direction = Value(direction),
       state = Value(state),
       due = Value(due),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FlashcardRow> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? direction,
    Expression<String>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? reviewCount,
    Expression<int>? lapseCount,
    Expression<String>? schedulerVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (direction != null) 'direction': direction,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (reviewCount != null) 'review_count': reviewCount,
      if (lapseCount != null) 'lapse_count': lapseCount,
      if (schedulerVersion != null) 'scheduler_version': schedulerVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<CardDirection>? direction,
    Value<CardState>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<DateTime>? due,
    Value<DateTime?>? lastReviewedAt,
    Value<int>? reviewCount,
    Value<int>? lapseCount,
    Value<String?>? schedulerVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FlashcardsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      direction: direction ?? this.direction,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      schedulerVersion: schedulerVersion ?? this.schedulerVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $FlashcardsTable.$converterdirection.toSql(direction.value),
      );
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $FlashcardsTable.$converterstate.toSql(state.value),
      );
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (lapseCount.present) {
      map['lapse_count'] = Variable<int>(lapseCount.value);
    }
    if (schedulerVersion.present) {
      map['scheduler_version'] = Variable<String>(schedulerVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('direction: $direction, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lapseCount: $lapseCount, ')
          ..write('schedulerVersion: $schedulerVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameKey,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;

  /// As entered (whitespace cleaned).
  final String name;

  /// Case-insensitive key; two tags cannot differ only in case or spacing.
  final String nameKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TagRow({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['name_key'] = Variable<String>(nameKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      nameKey: Value(nameKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'nameKey': serializer.toJson<String>(nameKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TagRow copyWith({
    String? id,
    String? name,
    String? nameKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    nameKey: nameKey ?? this.nameKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, nameKey, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameKey == this.nameKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> nameKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required String nameKey,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       nameKey = Value(nameKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? nameKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameKey != null) 'name_key': nameKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? nameKey,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryTagsTable extends EntryTags
    with TableInfo<$EntryTagsTable, EntryTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vocabulary_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, tagId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, tagId};
  @override
  EntryTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryTagRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntryTagsTable createAlias(String alias) {
    return $EntryTagsTable(attachedDatabase, alias);
  }
}

class EntryTagRow extends DataClass implements Insertable<EntryTagRow> {
  final String entryId;
  final String tagId;
  final DateTime createdAt;
  const EntryTagRow({
    required this.entryId,
    required this.tagId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['tag_id'] = Variable<String>(tagId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntryTagsCompanion toCompanion(bool nullToAbsent) {
    return EntryTagsCompanion(
      entryId: Value(entryId),
      tagId: Value(tagId),
      createdAt: Value(createdAt),
    );
  }

  factory EntryTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryTagRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'tagId': serializer.toJson<String>(tagId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EntryTagRow copyWith({String? entryId, String? tagId, DateTime? createdAt}) =>
      EntryTagRow(
        entryId: entryId ?? this.entryId,
        tagId: tagId ?? this.tagId,
        createdAt: createdAt ?? this.createdAt,
      );
  EntryTagRow copyWithCompanion(EntryTagsCompanion data) {
    return EntryTagRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryTagRow(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, tagId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryTagRow &&
          other.entryId == this.entryId &&
          other.tagId == this.tagId &&
          other.createdAt == this.createdAt);
}

class EntryTagsCompanion extends UpdateCompanion<EntryTagRow> {
  final Value<String> entryId;
  final Value<String> tagId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EntryTagsCompanion({
    this.entryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryTagsCompanion.insert({
    required String entryId,
    required String tagId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       tagId = Value(tagId),
       createdAt = Value(createdAt);
  static Insertable<EntryTagRow> custom({
    Expression<String>? entryId,
    Expression<String>? tagId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryTagsCompanion copyWith({
    Value<String>? entryId,
    Value<String>? tagId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EntryTagsCompanion(
      entryId: entryId ?? this.entryId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryTagsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewEventsTable extends ReviewEvents
    with TableInfo<$ReviewEventsTable, ReviewEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vocabulary_entries (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardDirection, String> direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CardDirection>($ReviewEventsTable.$converterdirection);
  @override
  late final GeneratedColumnWithTypeConverter<ReviewOutcome, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReviewOutcome>($ReviewEventsTable.$converteroutcome);
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDayMeta = const VerificationMeta(
    'localDay',
  );
  @override
  late final GeneratedColumn<String> localDay = GeneratedColumn<String>(
    'local_day',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    sessionId,
    direction,
    outcome,
    reviewedAt,
    localDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('local_day')) {
      context.handle(
        _localDayMeta,
        localDay.isAcceptableOrUnknown(data['local_day']!, _localDayMeta),
      );
    } else if (isInserting) {
      context.missing(_localDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      direction: $ReviewEventsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      outcome: $ReviewEventsTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      localDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_day'],
      )!,
    );
  }

  @override
  $ReviewEventsTable createAlias(String alias) {
    return $ReviewEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CardDirection, String, String> $converterdirection =
      const EnumNameConverter<CardDirection>(CardDirection.values);
  static JsonTypeConverter2<ReviewOutcome, String, String> $converteroutcome =
      const EnumNameConverter<ReviewOutcome>(ReviewOutcome.values);
}

class ReviewEventRow extends DataClass implements Insertable<ReviewEventRow> {
  final String id;
  final String? entryId;
  final String sessionId;
  final CardDirection direction;
  final ReviewOutcome outcome;
  final DateTime reviewedAt;

  /// `YYYY-MM-DD`, the device's local day at recording time.
  final String localDay;
  const ReviewEventRow({
    required this.id,
    this.entryId,
    required this.sessionId,
    required this.direction,
    required this.outcome,
    required this.reviewedAt,
    required this.localDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<String>(entryId);
    }
    map['session_id'] = Variable<String>(sessionId);
    {
      map['direction'] = Variable<String>(
        $ReviewEventsTable.$converterdirection.toSql(direction),
      );
    }
    {
      map['outcome'] = Variable<String>(
        $ReviewEventsTable.$converteroutcome.toSql(outcome),
      );
    }
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['local_day'] = Variable<String>(localDay);
    return map;
  }

  ReviewEventsCompanion toCompanion(bool nullToAbsent) {
    return ReviewEventsCompanion(
      id: Value(id),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
      sessionId: Value(sessionId),
      direction: Value(direction),
      outcome: Value(outcome),
      reviewedAt: Value(reviewedAt),
      localDay: Value(localDay),
    );
  }

  factory ReviewEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEventRow(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String?>(json['entryId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      direction: $ReviewEventsTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      outcome: $ReviewEventsTable.$converteroutcome.fromJson(
        serializer.fromJson<String>(json['outcome']),
      ),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      localDay: serializer.fromJson<String>(json['localDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String?>(entryId),
      'sessionId': serializer.toJson<String>(sessionId),
      'direction': serializer.toJson<String>(
        $ReviewEventsTable.$converterdirection.toJson(direction),
      ),
      'outcome': serializer.toJson<String>(
        $ReviewEventsTable.$converteroutcome.toJson(outcome),
      ),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'localDay': serializer.toJson<String>(localDay),
    };
  }

  ReviewEventRow copyWith({
    String? id,
    Value<String?> entryId = const Value.absent(),
    String? sessionId,
    CardDirection? direction,
    ReviewOutcome? outcome,
    DateTime? reviewedAt,
    String? localDay,
  }) => ReviewEventRow(
    id: id ?? this.id,
    entryId: entryId.present ? entryId.value : this.entryId,
    sessionId: sessionId ?? this.sessionId,
    direction: direction ?? this.direction,
    outcome: outcome ?? this.outcome,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    localDay: localDay ?? this.localDay,
  );
  ReviewEventRow copyWithCompanion(ReviewEventsCompanion data) {
    return ReviewEventRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      direction: data.direction.present ? data.direction.value : this.direction,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      localDay: data.localDay.present ? data.localDay.value : this.localDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('sessionId: $sessionId, ')
          ..write('direction: $direction, ')
          ..write('outcome: $outcome, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('localDay: $localDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    sessionId,
    direction,
    outcome,
    reviewedAt,
    localDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEventRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.sessionId == this.sessionId &&
          other.direction == this.direction &&
          other.outcome == this.outcome &&
          other.reviewedAt == this.reviewedAt &&
          other.localDay == this.localDay);
}

class ReviewEventsCompanion extends UpdateCompanion<ReviewEventRow> {
  final Value<String> id;
  final Value<String?> entryId;
  final Value<String> sessionId;
  final Value<CardDirection> direction;
  final Value<ReviewOutcome> outcome;
  final Value<DateTime> reviewedAt;
  final Value<String> localDay;
  final Value<int> rowid;
  const ReviewEventsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.direction = const Value.absent(),
    this.outcome = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.localDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewEventsCompanion.insert({
    required String id,
    this.entryId = const Value.absent(),
    required String sessionId,
    required CardDirection direction,
    required ReviewOutcome outcome,
    required DateTime reviewedAt,
    required String localDay,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       direction = Value(direction),
       outcome = Value(outcome),
       reviewedAt = Value(reviewedAt),
       localDay = Value(localDay);
  static Insertable<ReviewEventRow> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? sessionId,
    Expression<String>? direction,
    Expression<String>? outcome,
    Expression<DateTime>? reviewedAt,
    Expression<String>? localDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (sessionId != null) 'session_id': sessionId,
      if (direction != null) 'direction': direction,
      if (outcome != null) 'outcome': outcome,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (localDay != null) 'local_day': localDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewEventsCompanion copyWith({
    Value<String>? id,
    Value<String?>? entryId,
    Value<String>? sessionId,
    Value<CardDirection>? direction,
    Value<ReviewOutcome>? outcome,
    Value<DateTime>? reviewedAt,
    Value<String>? localDay,
    Value<int>? rowid,
  }) {
    return ReviewEventsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      sessionId: sessionId ?? this.sessionId,
      direction: direction ?? this.direction,
      outcome: outcome ?? this.outcome,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      localDay: localDay ?? this.localDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $ReviewEventsTable.$converterdirection.toSql(direction.value),
      );
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $ReviewEventsTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (localDay.present) {
      map['local_day'] = Variable<String>(localDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('sessionId: $sessionId, ')
          ..write('direction: $direction, ')
          ..write('outcome: $outcome, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('localDay: $localDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SentencePracticeEventsTable extends SentencePracticeEvents
    with TableInfo<$SentencePracticeEventsTable, SentencePracticeEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentencePracticeEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vocabulary_entries (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SentencePracticeDirection, String>
  direction =
      GeneratedColumn<String>(
        'direction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SentencePracticeDirection>(
        $SentencePracticeEventsTable.$converterdirection,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SentenceLevel, String> level =
      GeneratedColumn<String>(
        'level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SentenceLevel>(
        $SentencePracticeEventsTable.$converterlevel,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SentencePracticeOutcome, String>
  outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SentencePracticeOutcome>(
        $SentencePracticeEventsTable.$converteroutcome,
      );
  static const VerificationMeta _practicedAtMeta = const VerificationMeta(
    'practicedAt',
  );
  @override
  late final GeneratedColumn<DateTime> practicedAt = GeneratedColumn<DateTime>(
    'practiced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    direction,
    level,
    outcome,
    practicedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentence_practice_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SentencePracticeEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('practiced_at')) {
      context.handle(
        _practicedAtMeta,
        practicedAt.isAcceptableOrUnknown(
          data['practiced_at']!,
          _practicedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_practicedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SentencePracticeEventRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentencePracticeEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      direction: $SentencePracticeEventsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      level: $SentencePracticeEventsTable.$converterlevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}level'],
        )!,
      ),
      outcome: $SentencePracticeEventsTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      practicedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}practiced_at'],
      )!,
    );
  }

  @override
  $SentencePracticeEventsTable createAlias(String alias) {
    return $SentencePracticeEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SentencePracticeDirection, String, String>
  $converterdirection = const EnumNameConverter<SentencePracticeDirection>(
    SentencePracticeDirection.values,
  );
  static JsonTypeConverter2<SentenceLevel, String, String> $converterlevel =
      const EnumNameConverter<SentenceLevel>(SentenceLevel.values);
  static JsonTypeConverter2<SentencePracticeOutcome, String, String>
  $converteroutcome = const EnumNameConverter<SentencePracticeOutcome>(
    SentencePracticeOutcome.values,
  );
}

class SentencePracticeEventRow extends DataClass
    implements Insertable<SentencePracticeEventRow> {
  final String id;
  final String entryId;
  final SentencePracticeDirection direction;
  final SentenceLevel level;
  final SentencePracticeOutcome outcome;
  final DateTime practicedAt;
  const SentencePracticeEventRow({
    required this.id,
    required this.entryId,
    required this.direction,
    required this.level,
    required this.outcome,
    required this.practicedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    {
      map['direction'] = Variable<String>(
        $SentencePracticeEventsTable.$converterdirection.toSql(direction),
      );
    }
    {
      map['level'] = Variable<String>(
        $SentencePracticeEventsTable.$converterlevel.toSql(level),
      );
    }
    {
      map['outcome'] = Variable<String>(
        $SentencePracticeEventsTable.$converteroutcome.toSql(outcome),
      );
    }
    map['practiced_at'] = Variable<DateTime>(practicedAt);
    return map;
  }

  SentencePracticeEventsCompanion toCompanion(bool nullToAbsent) {
    return SentencePracticeEventsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      direction: Value(direction),
      level: Value(level),
      outcome: Value(outcome),
      practicedAt: Value(practicedAt),
    );
  }

  factory SentencePracticeEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SentencePracticeEventRow(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      direction: $SentencePracticeEventsTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      level: $SentencePracticeEventsTable.$converterlevel.fromJson(
        serializer.fromJson<String>(json['level']),
      ),
      outcome: $SentencePracticeEventsTable.$converteroutcome.fromJson(
        serializer.fromJson<String>(json['outcome']),
      ),
      practicedAt: serializer.fromJson<DateTime>(json['practicedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'direction': serializer.toJson<String>(
        $SentencePracticeEventsTable.$converterdirection.toJson(direction),
      ),
      'level': serializer.toJson<String>(
        $SentencePracticeEventsTable.$converterlevel.toJson(level),
      ),
      'outcome': serializer.toJson<String>(
        $SentencePracticeEventsTable.$converteroutcome.toJson(outcome),
      ),
      'practicedAt': serializer.toJson<DateTime>(practicedAt),
    };
  }

  SentencePracticeEventRow copyWith({
    String? id,
    String? entryId,
    SentencePracticeDirection? direction,
    SentenceLevel? level,
    SentencePracticeOutcome? outcome,
    DateTime? practicedAt,
  }) => SentencePracticeEventRow(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    direction: direction ?? this.direction,
    level: level ?? this.level,
    outcome: outcome ?? this.outcome,
    practicedAt: practicedAt ?? this.practicedAt,
  );
  SentencePracticeEventRow copyWithCompanion(
    SentencePracticeEventsCompanion data,
  ) {
    return SentencePracticeEventRow(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      direction: data.direction.present ? data.direction.value : this.direction,
      level: data.level.present ? data.level.value : this.level,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      practicedAt: data.practicedAt.present
          ? data.practicedAt.value
          : this.practicedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SentencePracticeEventRow(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('direction: $direction, ')
          ..write('level: $level, ')
          ..write('outcome: $outcome, ')
          ..write('practicedAt: $practicedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entryId, direction, level, outcome, practicedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SentencePracticeEventRow &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.direction == this.direction &&
          other.level == this.level &&
          other.outcome == this.outcome &&
          other.practicedAt == this.practicedAt);
}

class SentencePracticeEventsCompanion
    extends UpdateCompanion<SentencePracticeEventRow> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<SentencePracticeDirection> direction;
  final Value<SentenceLevel> level;
  final Value<SentencePracticeOutcome> outcome;
  final Value<DateTime> practicedAt;
  final Value<int> rowid;
  const SentencePracticeEventsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.direction = const Value.absent(),
    this.level = const Value.absent(),
    this.outcome = const Value.absent(),
    this.practicedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SentencePracticeEventsCompanion.insert({
    required String id,
    required String entryId,
    required SentencePracticeDirection direction,
    required SentenceLevel level,
    required SentencePracticeOutcome outcome,
    required DateTime practicedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       direction = Value(direction),
       level = Value(level),
       outcome = Value(outcome),
       practicedAt = Value(practicedAt);
  static Insertable<SentencePracticeEventRow> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? direction,
    Expression<String>? level,
    Expression<String>? outcome,
    Expression<DateTime>? practicedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (direction != null) 'direction': direction,
      if (level != null) 'level': level,
      if (outcome != null) 'outcome': outcome,
      if (practicedAt != null) 'practiced_at': practicedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SentencePracticeEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<SentencePracticeDirection>? direction,
    Value<SentenceLevel>? level,
    Value<SentencePracticeOutcome>? outcome,
    Value<DateTime>? practicedAt,
    Value<int>? rowid,
  }) {
    return SentencePracticeEventsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      direction: direction ?? this.direction,
      level: level ?? this.level,
      outcome: outcome ?? this.outcome,
      practicedAt: practicedAt ?? this.practicedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $SentencePracticeEventsTable.$converterdirection.toSql(direction.value),
      );
    }
    if (level.present) {
      map['level'] = Variable<String>(
        $SentencePracticeEventsTable.$converterlevel.toSql(level.value),
      );
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $SentencePracticeEventsTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (practicedAt.present) {
      map['practiced_at'] = Variable<DateTime>(practicedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentencePracticeEventsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('direction: $direction, ')
          ..write('level: $level, ')
          ..write('outcome: $outcome, ')
          ..write('practicedAt: $practicedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $VocabularyEntriesTable vocabularyEntries =
      $VocabularyEntriesTable(this);
  late final $VocabularyMeaningsTable vocabularyMeanings =
      $VocabularyMeaningsTable(this);
  late final $FlashcardsTable flashcards = $FlashcardsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $EntryTagsTable entryTags = $EntryTagsTable(this);
  late final $ReviewEventsTable reviewEvents = $ReviewEventsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SentencePracticeEventsTable sentencePracticeEvents =
      $SentencePracticeEventsTable(this);
  late final Index idxEntriesDeckNormalized = Index(
    'idx_entries_deck_normalized',
    'CREATE INDEX idx_entries_deck_normalized ON vocabulary_entries (deck_id, normalized)',
  );
  late final Index idxFlashcardsDue = Index(
    'idx_flashcards_due',
    'CREATE INDEX idx_flashcards_due ON flashcards (due)',
  );
  late final Index idxEntryTagsTag = Index(
    'idx_entry_tags_tag',
    'CREATE INDEX idx_entry_tags_tag ON entry_tags (tag_id)',
  );
  late final Index idxReviewEventsDay = Index(
    'idx_review_events_day',
    'CREATE INDEX idx_review_events_day ON review_events (local_day)',
  );
  late final Index idxSentencePracticeEntry = Index(
    'idx_sentence_practice_entry',
    'CREATE INDEX idx_sentence_practice_entry ON sentence_practice_events (entry_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    decks,
    vocabularyEntries,
    vocabularyMeanings,
    flashcards,
    tags,
    entryTags,
    reviewEvents,
    appSettings,
    sentencePracticeEvents,
    idxEntriesDeckNormalized,
    idxFlashcardsDue,
    idxEntryTagsTag,
    idxReviewEventsDay,
    idxSentencePracticeEntry,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'decks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vocabulary_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vocabulary_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vocabulary_meanings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vocabulary_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('flashcards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vocabulary_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entry_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vocabulary_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_events', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'vocabulary_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('sentence_practice_events', kind: UpdateKind.delete),
      ],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$DecksTableCreateCompanionBuilder = DecksCompanion Function({
  required String id,
  required String name,
  required String sourceLanguage,
  required String definitionLanguage,
  required int dailyNewCardLimit,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DecksTableUpdateCompanionBuilder = DecksCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> sourceLanguage,
  Value<String> definitionLanguage,
  Value<int> dailyNewCardLimit,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, DeckRow> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VocabularyEntriesTable, List<VocabularyEntryRow>>
  _vocabularyEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vocabularyEntries,
        aliasName: 'decks__id__vocabulary_entries__deck_id',
      );

  $$VocabularyEntriesTableProcessedTableManager get vocabularyEntriesRefs {
    final manager = $$VocabularyEntriesTableTableManager(
      $_db,
      $_db.vocabularyEntries,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _vocabularyEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionLanguage => $composableBuilder(
    column: $table.definitionLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyNewCardLimit => $composableBuilder(
    column: $table.dailyNewCardLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> vocabularyEntriesRefs(
    Expression<bool> Function($$VocabularyEntriesTableFilterComposer f) f,
  ) {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionLanguage => $composableBuilder(
    column: $table.definitionLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyNewCardLimit => $composableBuilder(
    column: $table.dailyNewCardLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionLanguage => $composableBuilder(
    column: $table.definitionLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyNewCardLimit => $composableBuilder(
    column: $table.dailyNewCardLimit,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> vocabularyEntriesRefs<T extends Object>(
    Expression<T> Function($$VocabularyEntriesTableAnnotationComposer a) f,
  ) {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vocabularyEntries,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          DeckRow,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (DeckRow, $$DecksTableReferences),
          DeckRow,
          PrefetchHooks Function({bool vocabularyEntriesRefs})
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourceLanguage = const Value.absent(),
                Value<String> definitionLanguage = const Value.absent(),
                Value<int> dailyNewCardLimit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                sourceLanguage: sourceLanguage,
                definitionLanguage: definitionLanguage,
                dailyNewCardLimit: dailyNewCardLimit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String sourceLanguage,
                required String definitionLanguage,
                required int dailyNewCardLimit,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                sourceLanguage: sourceLanguage,
                definitionLanguage: definitionLanguage,
                dailyNewCardLimit: dailyNewCardLimit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DecksTable, DeckRow>(table),
                  $$DecksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({vocabularyEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vocabularyEntriesRefs) db.vocabularyEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vocabularyEntriesRefs)
                    await $_getPrefetchedData<
                      DeckRow,
                      $DecksTable,
                      VocabularyEntryRow
                    >(
                      currentTable: table,
                      referencedTable: $$DecksTableReferences
                          ._vocabularyEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$DecksTableReferences(
                        db,
                        table,
                        p0,
                      ).vocabularyEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deckId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      DeckRow,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (DeckRow, $$DecksTableReferences),
      DeckRow,
      PrefetchHooks Function({bool vocabularyEntriesRefs})
    >;
typedef $$VocabularyEntriesTableCreateCompanionBuilder =
    VocabularyEntriesCompanion Function({
      required String id,
      required String deckId,
      required String original,
      required String normalized,
      Value<String?> lemma,
      required String sourceLanguage,
      required String definitionLanguage,
      Value<String?> partOfSpeech,
      Value<String?> exampleSentence,
      Value<String?> exampleTranslation,
      Value<String?> grammarInfo,
      Value<String?> notes,
      Value<String?> sourceContext,
      required VocabularySourceType sourceType,
      required EnrichmentStatus enrichmentStatus,
      Value<String?> enrichmentMetadata,
      Value<DateTime?> userEditedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> markedDifficultAt,
      Value<String> searchKey,
      Value<int> rowid,
    });
typedef $$VocabularyEntriesTableUpdateCompanionBuilder =
    VocabularyEntriesCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> original,
      Value<String> normalized,
      Value<String?> lemma,
      Value<String> sourceLanguage,
      Value<String> definitionLanguage,
      Value<String?> partOfSpeech,
      Value<String?> exampleSentence,
      Value<String?> exampleTranslation,
      Value<String?> grammarInfo,
      Value<String?> notes,
      Value<String?> sourceContext,
      Value<VocabularySourceType> sourceType,
      Value<EnrichmentStatus> enrichmentStatus,
      Value<String?> enrichmentMetadata,
      Value<DateTime?> userEditedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> markedDifficultAt,
      Value<String> searchKey,
      Value<int> rowid,
    });

final class $$VocabularyEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VocabularyEntriesTable,
          VocabularyEntryRow
        > {
  $$VocabularyEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DecksTable _deckIdTable(_$AppDatabase db) =>
      db.decks.createAlias('vocabulary_entries__deck_id__decks__id');

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $VocabularyMeaningsTable,
    List<VocabularyMeaningRow>
  >
  _vocabularyMeaningsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vocabularyMeanings,
        aliasName: 'vocabulary_entries__id__vocabulary_meanings__entry_id',
      );

  $$VocabularyMeaningsTableProcessedTableManager get vocabularyMeaningsRefs {
    final manager = $$VocabularyMeaningsTableTableManager(
      $_db,
      $_db.vocabularyMeanings,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _vocabularyMeaningsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlashcardsTable, List<FlashcardRow>>
  _flashcardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flashcards,
    aliasName: 'vocabulary_entries__id__flashcards__entry_id',
  );

  $$FlashcardsTableProcessedTableManager get flashcardsRefs {
    final manager = $$FlashcardsTableTableManager(
      $_db,
      $_db.flashcards,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_flashcardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntryTagsTable, List<EntryTagRow>>
  _entryTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryTags,
    aliasName: 'vocabulary_entries__id__entry_tags__entry_id',
  );

  $$EntryTagsTableProcessedTableManager get entryTagsRefs {
    final manager = $$EntryTagsTableTableManager(
      $_db,
      $_db.entryTags,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewEventsTable, List<ReviewEventRow>>
  _reviewEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewEvents,
    aliasName: 'vocabulary_entries__id__review_events__entry_id',
  );

  $$ReviewEventsTableProcessedTableManager get reviewEventsRefs {
    final manager = $$ReviewEventsTableTableManager(
      $_db,
      $_db.reviewEvents,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $SentencePracticeEventsTable,
    List<SentencePracticeEventRow>
  >
  _sentencePracticeEventsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sentencePracticeEvents,
        aliasName: 'vocabulary_entries__id__sentence_practice_events__entry_id',
      );

  $$SentencePracticeEventsTableProcessedTableManager
  get sentencePracticeEventsRefs {
    final manager = $$SentencePracticeEventsTableTableManager(
      $_db,
      $_db.sentencePracticeEvents,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sentencePracticeEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VocabularyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionLanguage => $composableBuilder(
    column: $table.definitionLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleTranslation => $composableBuilder(
    column: $table.exampleTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grammarInfo => $composableBuilder(
    column: $table.grammarInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    VocabularySourceType,
    VocabularySourceType,
    String
  >
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<EnrichmentStatus, EnrichmentStatus, String>
  get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get enrichmentMetadata => $composableBuilder(
    column: $table.enrichmentMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get userEditedAt => $composableBuilder(
    column: $table.userEditedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get markedDifficultAt => $composableBuilder(
    column: $table.markedDifficultAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchKey => $composableBuilder(
    column: $table.searchKey,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> vocabularyMeaningsRefs(
    Expression<bool> Function($$VocabularyMeaningsTableFilterComposer f) f,
  ) {
    final $$VocabularyMeaningsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vocabularyMeanings,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyMeaningsTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyMeanings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> flashcardsRefs(
    Expression<bool> Function($$FlashcardsTableFilterComposer f) f,
  ) {
    final $$FlashcardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableFilterComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entryTagsRefs(
    Expression<bool> Function($$EntryTagsTableFilterComposer f) f,
  ) {
    final $$EntryTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableFilterComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewEventsRefs(
    Expression<bool> Function($$ReviewEventsTableFilterComposer f) f,
  ) {
    final $$ReviewEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewEvents,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewEventsTableFilterComposer(
            $db: $db,
            $table: $db.reviewEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sentencePracticeEventsRefs(
    Expression<bool> Function($$SentencePracticeEventsTableFilterComposer f) f,
  ) {
    final $$SentencePracticeEventsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sentencePracticeEvents,
          getReferencedColumn: (t) => t.entryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SentencePracticeEventsTableFilterComposer(
                $db: $db,
                $table: $db.sentencePracticeEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VocabularyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get original => $composableBuilder(
    column: $table.original,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lemma => $composableBuilder(
    column: $table.lemma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionLanguage => $composableBuilder(
    column: $table.definitionLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleTranslation => $composableBuilder(
    column: $table.exampleTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grammarInfo => $composableBuilder(
    column: $table.grammarInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enrichmentMetadata => $composableBuilder(
    column: $table.enrichmentMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get userEditedAt => $composableBuilder(
    column: $table.userEditedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get markedDifficultAt => $composableBuilder(
    column: $table.markedDifficultAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchKey => $composableBuilder(
    column: $table.searchKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabularyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get original =>
      $composableBuilder(column: $table.original, builder: (column) => column);

  GeneratedColumn<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lemma =>
      $composableBuilder(column: $table.lemma, builder: (column) => column);

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionLanguage => $composableBuilder(
    column: $table.definitionLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleTranslation => $composableBuilder(
    column: $table.exampleTranslation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grammarInfo => $composableBuilder(
    column: $table.grammarInfo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get sourceContext => $composableBuilder(
    column: $table.sourceContext,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<VocabularySourceType, String>
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EnrichmentStatus, String>
  get enrichmentStatus => $composableBuilder(
    column: $table.enrichmentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get enrichmentMetadata => $composableBuilder(
    column: $table.enrichmentMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get userEditedAt => $composableBuilder(
    column: $table.userEditedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get markedDifficultAt => $composableBuilder(
    column: $table.markedDifficultAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchKey =>
      $composableBuilder(column: $table.searchKey, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> vocabularyMeaningsRefs<T extends Object>(
    Expression<T> Function($$VocabularyMeaningsTableAnnotationComposer a) f,
  ) {
    final $$VocabularyMeaningsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.vocabularyMeanings,
          getReferencedColumn: (t) => t.entryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyMeaningsTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyMeanings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> flashcardsRefs<T extends Object>(
    Expression<T> Function($$FlashcardsTableAnnotationComposer a) f,
  ) {
    final $$FlashcardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entryTagsRefs<T extends Object>(
    Expression<T> Function($$EntryTagsTableAnnotationComposer a) f,
  ) {
    final $$EntryTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewEventsRefs<T extends Object>(
    Expression<T> Function($$ReviewEventsTableAnnotationComposer a) f,
  ) {
    final $$ReviewEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewEvents,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sentencePracticeEventsRefs<T extends Object>(
    Expression<T> Function($$SentencePracticeEventsTableAnnotationComposer a) f,
  ) {
    final $$SentencePracticeEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sentencePracticeEvents,
          getReferencedColumn: (t) => t.entryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SentencePracticeEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.sentencePracticeEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VocabularyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyEntriesTable,
          VocabularyEntryRow,
          $$VocabularyEntriesTableFilterComposer,
          $$VocabularyEntriesTableOrderingComposer,
          $$VocabularyEntriesTableAnnotationComposer,
          $$VocabularyEntriesTableCreateCompanionBuilder,
          $$VocabularyEntriesTableUpdateCompanionBuilder,
          (VocabularyEntryRow, $$VocabularyEntriesTableReferences),
          VocabularyEntryRow,
          PrefetchHooks Function({
            bool deckId,
            bool vocabularyMeaningsRefs,
            bool flashcardsRefs,
            bool entryTagsRefs,
            bool reviewEventsRefs,
            bool sentencePracticeEventsRefs,
          })
        > {
  $$VocabularyEntriesTableTableManager(
    _$AppDatabase db,
    $VocabularyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> original = const Value.absent(),
                Value<String> normalized = const Value.absent(),
                Value<String?> lemma = const Value.absent(),
                Value<String> sourceLanguage = const Value.absent(),
                Value<String> definitionLanguage = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<String?> exampleTranslation = const Value.absent(),
                Value<String?> grammarInfo = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                Value<VocabularySourceType> sourceType = const Value.absent(),
                Value<EnrichmentStatus> enrichmentStatus = const Value.absent(),
                Value<String?> enrichmentMetadata = const Value.absent(),
                Value<DateTime?> userEditedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> markedDifficultAt = const Value.absent(),
                Value<String> searchKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyEntriesCompanion(
                id: id,
                deckId: deckId,
                original: original,
                normalized: normalized,
                lemma: lemma,
                sourceLanguage: sourceLanguage,
                definitionLanguage: definitionLanguage,
                partOfSpeech: partOfSpeech,
                exampleSentence: exampleSentence,
                exampleTranslation: exampleTranslation,
                grammarInfo: grammarInfo,
                notes: notes,
                sourceContext: sourceContext,
                sourceType: sourceType,
                enrichmentStatus: enrichmentStatus,
                enrichmentMetadata: enrichmentMetadata,
                userEditedAt: userEditedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                markedDifficultAt: markedDifficultAt,
                searchKey: searchKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String original,
                required String normalized,
                Value<String?> lemma = const Value.absent(),
                required String sourceLanguage,
                required String definitionLanguage,
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<String?> exampleTranslation = const Value.absent(),
                Value<String?> grammarInfo = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> sourceContext = const Value.absent(),
                required VocabularySourceType sourceType,
                required EnrichmentStatus enrichmentStatus,
                Value<String?> enrichmentMetadata = const Value.absent(),
                Value<DateTime?> userEditedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> markedDifficultAt = const Value.absent(),
                Value<String> searchKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyEntriesCompanion.insert(
                id: id,
                deckId: deckId,
                original: original,
                normalized: normalized,
                lemma: lemma,
                sourceLanguage: sourceLanguage,
                definitionLanguage: definitionLanguage,
                partOfSpeech: partOfSpeech,
                exampleSentence: exampleSentence,
                exampleTranslation: exampleTranslation,
                grammarInfo: grammarInfo,
                notes: notes,
                sourceContext: sourceContext,
                sourceType: sourceType,
                enrichmentStatus: enrichmentStatus,
                enrichmentMetadata: enrichmentMetadata,
                userEditedAt: userEditedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                markedDifficultAt: markedDifficultAt,
                searchKey: searchKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VocabularyEntriesTable, VocabularyEntryRow>(
                    table,
                  ),
                  $$VocabularyEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                deckId = false,
                vocabularyMeaningsRefs = false,
                flashcardsRefs = false,
                entryTagsRefs = false,
                reviewEventsRefs = false,
                sentencePracticeEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (vocabularyMeaningsRefs) db.vocabularyMeanings,
                    if (flashcardsRefs) db.flashcards,
                    if (entryTagsRefs) db.entryTags,
                    if (reviewEventsRefs) db.reviewEvents,
                    if (sentencePracticeEventsRefs) db.sentencePracticeEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (deckId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.deckId,
                            referencedTable: $$VocabularyEntriesTableReferences
                                ._deckIdTable(db),
                            referencedColumn: $$VocabularyEntriesTableReferences
                                ._deckIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (vocabularyMeaningsRefs)
                        await $_getPrefetchedData<
                          VocabularyEntryRow,
                          $VocabularyEntriesTable,
                          VocabularyMeaningRow
                        >(
                          currentTable: table,
                          referencedTable: $$VocabularyEntriesTableReferences
                              ._vocabularyMeaningsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).vocabularyMeaningsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (flashcardsRefs)
                        await $_getPrefetchedData<
                          VocabularyEntryRow,
                          $VocabularyEntriesTable,
                          FlashcardRow
                        >(
                          currentTable: table,
                          referencedTable: $$VocabularyEntriesTableReferences
                              ._flashcardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).flashcardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (entryTagsRefs)
                        await $_getPrefetchedData<
                          VocabularyEntryRow,
                          $VocabularyEntriesTable,
                          EntryTagRow
                        >(
                          currentTable: table,
                          referencedTable: $$VocabularyEntriesTableReferences
                              ._entryTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).entryTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewEventsRefs)
                        await $_getPrefetchedData<
                          VocabularyEntryRow,
                          $VocabularyEntriesTable,
                          ReviewEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$VocabularyEntriesTableReferences
                              ._reviewEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sentencePracticeEventsRefs)
                        await $_getPrefetchedData<
                          VocabularyEntryRow,
                          $VocabularyEntriesTable,
                          SentencePracticeEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$VocabularyEntriesTableReferences
                              ._sentencePracticeEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VocabularyEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).sentencePracticeEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VocabularyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyEntriesTable,
      VocabularyEntryRow,
      $$VocabularyEntriesTableFilterComposer,
      $$VocabularyEntriesTableOrderingComposer,
      $$VocabularyEntriesTableAnnotationComposer,
      $$VocabularyEntriesTableCreateCompanionBuilder,
      $$VocabularyEntriesTableUpdateCompanionBuilder,
      (VocabularyEntryRow, $$VocabularyEntriesTableReferences),
      VocabularyEntryRow,
      PrefetchHooks Function({
        bool deckId,
        bool vocabularyMeaningsRefs,
        bool flashcardsRefs,
        bool entryTagsRefs,
        bool reviewEventsRefs,
        bool sentencePracticeEventsRefs,
      })
    >;
typedef $$VocabularyMeaningsTableCreateCompanionBuilder =
    VocabularyMeaningsCompanion Function({
      required String id,
      required String entryId,
      required int position,
      required String meaning,
      Value<String?> explanation,
      Value<int> rowid,
    });
typedef $$VocabularyMeaningsTableUpdateCompanionBuilder =
    VocabularyMeaningsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<int> position,
      Value<String> meaning,
      Value<String?> explanation,
      Value<int> rowid,
    });

final class $$VocabularyMeaningsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VocabularyMeaningsTable,
          VocabularyMeaningRow
        > {
  $$VocabularyMeaningsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VocabularyEntriesTable _entryIdTable(_$AppDatabase db) => db
      .vocabularyEntries
      .createAlias('vocabulary_meanings__entry_id__vocabulary_entries__id');

  $$VocabularyEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$VocabularyEntriesTableTableManager(
      $_db,
      $_db.vocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VocabularyMeaningsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyMeaningsTable> {
  $$VocabularyMeaningsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabularyEntriesTableFilterComposer get entryId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabularyMeaningsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyMeaningsTable> {
  $$VocabularyMeaningsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabularyEntriesTableOrderingComposer get entryId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabularyMeaningsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyMeaningsTable> {
  $$VocabularyMeaningsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  $$VocabularyEntriesTableAnnotationComposer get entryId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.entryId,
          referencedTable: $db.vocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$VocabularyMeaningsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyMeaningsTable,
          VocabularyMeaningRow,
          $$VocabularyMeaningsTableFilterComposer,
          $$VocabularyMeaningsTableOrderingComposer,
          $$VocabularyMeaningsTableAnnotationComposer,
          $$VocabularyMeaningsTableCreateCompanionBuilder,
          $$VocabularyMeaningsTableUpdateCompanionBuilder,
          (VocabularyMeaningRow, $$VocabularyMeaningsTableReferences),
          VocabularyMeaningRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$VocabularyMeaningsTableTableManager(
    _$AppDatabase db,
    $VocabularyMeaningsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyMeaningsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyMeaningsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyMeaningsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyMeaningsCompanion(
                id: id,
                entryId: entryId,
                position: position,
                meaning: meaning,
                explanation: explanation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required int position,
                required String meaning,
                Value<String?> explanation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyMeaningsCompanion.insert(
                id: id,
                entryId: entryId,
                position: position,
                meaning: meaning,
                explanation: explanation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VocabularyMeaningsTable, VocabularyMeaningRow>(
                    table,
                  ),
                  $$VocabularyMeaningsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$VocabularyMeaningsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$VocabularyMeaningsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VocabularyMeaningsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyMeaningsTable,
      VocabularyMeaningRow,
      $$VocabularyMeaningsTableFilterComposer,
      $$VocabularyMeaningsTableOrderingComposer,
      $$VocabularyMeaningsTableAnnotationComposer,
      $$VocabularyMeaningsTableCreateCompanionBuilder,
      $$VocabularyMeaningsTableUpdateCompanionBuilder,
      (VocabularyMeaningRow, $$VocabularyMeaningsTableReferences),
      VocabularyMeaningRow,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$FlashcardsTableCreateCompanionBuilder = FlashcardsCompanion Function({
  required String id,
  required String entryId,
  required CardDirection direction,
  required CardState state,
  Value<int?> step,
  Value<double?> stability,
  Value<double?> difficulty,
  required DateTime due,
  Value<DateTime?> lastReviewedAt,
  Value<int> reviewCount,
  Value<int> lapseCount,
  Value<String?> schedulerVersion,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FlashcardsTableUpdateCompanionBuilder = FlashcardsCompanion Function({
  Value<String> id,
  Value<String> entryId,
  Value<CardDirection> direction,
  Value<CardState> state,
  Value<int?> step,
  Value<double?> stability,
  Value<double?> difficulty,
  Value<DateTime> due,
  Value<DateTime?> lastReviewedAt,
  Value<int> reviewCount,
  Value<int> lapseCount,
  Value<String?> schedulerVersion,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$FlashcardsTableReferences
    extends BaseReferences<_$AppDatabase, $FlashcardsTable, FlashcardRow> {
  $$FlashcardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VocabularyEntriesTable _entryIdTable(_$AppDatabase db) => db
      .vocabularyEntries
      .createAlias('flashcards__entry_id__vocabulary_entries__id');

  $$VocabularyEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$VocabularyEntriesTableTableManager(
      $_db,
      $_db.vocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardDirection, CardDirection, String>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CardState, CardState, String> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schedulerVersion => $composableBuilder(
    column: $table.schedulerVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabularyEntriesTableFilterComposer get entryId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schedulerVersion => $composableBuilder(
    column: $table.schedulerVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabularyEntriesTableOrderingComposer get entryId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapseCount => $composableBuilder(
    column: $table.lapseCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get schedulerVersion => $composableBuilder(
    column: $table.schedulerVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VocabularyEntriesTableAnnotationComposer get entryId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.entryId,
          referencedTable: $db.vocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FlashcardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardsTable,
          FlashcardRow,
          $$FlashcardsTableFilterComposer,
          $$FlashcardsTableOrderingComposer,
          $$FlashcardsTableAnnotationComposer,
          $$FlashcardsTableCreateCompanionBuilder,
          $$FlashcardsTableUpdateCompanionBuilder,
          (FlashcardRow, $$FlashcardsTableReferences),
          FlashcardRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$FlashcardsTableTableManager(_$AppDatabase db, $FlashcardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<CardDirection> direction = const Value.absent(),
                Value<CardState> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<String?> schedulerVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion(
                id: id,
                entryId: entryId,
                direction: direction,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReviewedAt: lastReviewedAt,
                reviewCount: reviewCount,
                lapseCount: lapseCount,
                schedulerVersion: schedulerVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required CardDirection direction,
                required CardState state,
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                required DateTime due,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> lapseCount = const Value.absent(),
                Value<String?> schedulerVersion = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion.insert(
                id: id,
                entryId: entryId,
                direction: direction,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReviewedAt: lastReviewedAt,
                reviewCount: reviewCount,
                lapseCount: lapseCount,
                schedulerVersion: schedulerVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlashcardsTable, FlashcardRow>(table),
                  $$FlashcardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$FlashcardsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$FlashcardsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FlashcardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardsTable,
      FlashcardRow,
      $$FlashcardsTableFilterComposer,
      $$FlashcardsTableOrderingComposer,
      $$FlashcardsTableAnnotationComposer,
      $$FlashcardsTableCreateCompanionBuilder,
      $$FlashcardsTableUpdateCompanionBuilder,
      (FlashcardRow, $$FlashcardsTableReferences),
      FlashcardRow,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  required String nameKey,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> nameKey,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntryTagsTable, List<EntryTagRow>>
  _entryTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryTags,
    aliasName: 'tags__id__entry_tags__tag_id',
  );

  $$EntryTagsTableProcessedTableManager get entryTagsRefs {
    final manager = $$EntryTagsTableTableManager(
      $_db,
      $_db.entryTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entryTagsRefs(
    Expression<bool> Function($$EntryTagsTableFilterComposer f) f,
  ) {
    final $$EntryTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableFilterComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> entryTagsRefs<T extends Object>(
    Expression<T> Function($$EntryTagsTableAnnotationComposer a) f,
  ) {
    final $$EntryTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.entryTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool entryTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
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
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                nameKey: nameKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String nameKey,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                nameKey: nameKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, TagRow>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entryTagsRefs) db.entryTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entryTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, EntryTagRow>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._entryTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).entryTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool entryTagsRefs})
    >;
typedef $$EntryTagsTableCreateCompanionBuilder = EntryTagsCompanion Function({
  required String entryId,
  required String tagId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$EntryTagsTableUpdateCompanionBuilder = EntryTagsCompanion Function({
  Value<String> entryId,
  Value<String> tagId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$EntryTagsTableReferences
    extends BaseReferences<_$AppDatabase, $EntryTagsTable, EntryTagRow> {
  $$EntryTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VocabularyEntriesTable _entryIdTable(_$AppDatabase db) => db
      .vocabularyEntries
      .createAlias('entry_tags__entry_id__vocabulary_entries__id');

  $$VocabularyEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$VocabularyEntriesTableTableManager(
      $_db,
      $_db.vocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('entry_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntryTagsTableFilterComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabularyEntriesTableFilterComposer get entryId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabularyEntriesTableOrderingComposer get entryId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VocabularyEntriesTableAnnotationComposer get entryId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.entryId,
          referencedTable: $db.vocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryTagsTable,
          EntryTagRow,
          $$EntryTagsTableFilterComposer,
          $$EntryTagsTableOrderingComposer,
          $$EntryTagsTableAnnotationComposer,
          $$EntryTagsTableCreateCompanionBuilder,
          $$EntryTagsTableUpdateCompanionBuilder,
          (EntryTagRow, $$EntryTagsTableReferences),
          EntryTagRow,
          PrefetchHooks Function({bool entryId, bool tagId})
        > {
  $$EntryTagsTableTableManager(_$AppDatabase db, $EntryTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion(
                entryId: entryId,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String tagId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion.insert(
                entryId: entryId,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntryTagsTable, EntryTagRow>(table),
                  $$EntryTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$EntryTagsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$EntryTagsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$EntryTagsTableReferences._tagIdTable(
                          db,
                        ),
                        referencedColumn: $$EntryTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntryTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryTagsTable,
      EntryTagRow,
      $$EntryTagsTableFilterComposer,
      $$EntryTagsTableOrderingComposer,
      $$EntryTagsTableAnnotationComposer,
      $$EntryTagsTableCreateCompanionBuilder,
      $$EntryTagsTableUpdateCompanionBuilder,
      (EntryTagRow, $$EntryTagsTableReferences),
      EntryTagRow,
      PrefetchHooks Function({bool entryId, bool tagId})
    >;
typedef $$ReviewEventsTableCreateCompanionBuilder =
    ReviewEventsCompanion Function({
      required String id,
      Value<String?> entryId,
      required String sessionId,
      required CardDirection direction,
      required ReviewOutcome outcome,
      required DateTime reviewedAt,
      required String localDay,
      Value<int> rowid,
    });
typedef $$ReviewEventsTableUpdateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<String> id,
      Value<String?> entryId,
      Value<String> sessionId,
      Value<CardDirection> direction,
      Value<ReviewOutcome> outcome,
      Value<DateTime> reviewedAt,
      Value<String> localDay,
      Value<int> rowid,
    });

final class $$ReviewEventsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEventRow> {
  $$ReviewEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VocabularyEntriesTable _entryIdTable(_$AppDatabase db) => db
      .vocabularyEntries
      .createAlias('review_events__entry_id__vocabulary_entries__id');

  $$VocabularyEntriesTableProcessedTableManager? get entryId {
    final $_column = $_itemColumn<String>('entry_id');
    if ($_column == null) return null;
    final manager = $$VocabularyEntriesTableTableManager(
      $_db,
      $_db.vocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CardDirection, CardDirection, String>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ReviewOutcome, ReviewOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabularyEntriesTableFilterComposer get entryId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDay => $composableBuilder(
    column: $table.localDay,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabularyEntriesTableOrderingComposer get entryId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CardDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReviewOutcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localDay =>
      $composableBuilder(column: $table.localDay, builder: (column) => column);

  $$VocabularyEntriesTableAnnotationComposer get entryId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.entryId,
          referencedTable: $db.vocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ReviewEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewEventsTable,
          ReviewEventRow,
          $$ReviewEventsTableFilterComposer,
          $$ReviewEventsTableOrderingComposer,
          $$ReviewEventsTableAnnotationComposer,
          $$ReviewEventsTableCreateCompanionBuilder,
          $$ReviewEventsTableUpdateCompanionBuilder,
          (ReviewEventRow, $$ReviewEventsTableReferences),
          ReviewEventRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$ReviewEventsTableTableManager(_$AppDatabase db, $ReviewEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> entryId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<CardDirection> direction = const Value.absent(),
                Value<ReviewOutcome> outcome = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String> localDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewEventsCompanion(
                id: id,
                entryId: entryId,
                sessionId: sessionId,
                direction: direction,
                outcome: outcome,
                reviewedAt: reviewedAt,
                localDay: localDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> entryId = const Value.absent(),
                required String sessionId,
                required CardDirection direction,
                required ReviewOutcome outcome,
                required DateTime reviewedAt,
                required String localDay,
                Value<int> rowid = const Value.absent(),
              }) => ReviewEventsCompanion.insert(
                id: id,
                entryId: entryId,
                sessionId: sessionId,
                direction: direction,
                outcome: outcome,
                reviewedAt: reviewedAt,
                localDay: localDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewEventsTable, ReviewEventRow>(table),
                  $$ReviewEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$ReviewEventsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$ReviewEventsTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewEventsTable,
      ReviewEventRow,
      $$ReviewEventsTableFilterComposer,
      $$ReviewEventsTableOrderingComposer,
      $$ReviewEventsTableAnnotationComposer,
      $$ReviewEventsTableCreateCompanionBuilder,
      $$ReviewEventsTableUpdateCompanionBuilder,
      (ReviewEventRow, $$ReviewEventsTableReferences),
      ReviewEventRow,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$SentencePracticeEventsTableCreateCompanionBuilder =
    SentencePracticeEventsCompanion Function({
      required String id,
      required String entryId,
      required SentencePracticeDirection direction,
      required SentenceLevel level,
      required SentencePracticeOutcome outcome,
      required DateTime practicedAt,
      Value<int> rowid,
    });
typedef $$SentencePracticeEventsTableUpdateCompanionBuilder =
    SentencePracticeEventsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<SentencePracticeDirection> direction,
      Value<SentenceLevel> level,
      Value<SentencePracticeOutcome> outcome,
      Value<DateTime> practicedAt,
      Value<int> rowid,
    });

final class $$SentencePracticeEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SentencePracticeEventsTable,
          SentencePracticeEventRow
        > {
  $$SentencePracticeEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VocabularyEntriesTable _entryIdTable(_$AppDatabase db) =>
      db.vocabularyEntries.createAlias(
        'sentence_practice_events__entry_id__vocabulary_entries__id',
      );

  $$VocabularyEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$VocabularyEntriesTableTableManager(
      $_db,
      $_db.vocabularyEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SentencePracticeEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SentencePracticeEventsTable> {
  $$SentencePracticeEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    SentencePracticeDirection,
    SentencePracticeDirection,
    String
  >
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SentenceLevel, SentenceLevel, String>
  get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    SentencePracticeOutcome,
    SentencePracticeOutcome,
    String
  >
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get practicedAt => $composableBuilder(
    column: $table.practicedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VocabularyEntriesTableFilterComposer get entryId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencePracticeEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SentencePracticeEventsTable> {
  $$SentencePracticeEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get practicedAt => $composableBuilder(
    column: $table.practicedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VocabularyEntriesTableOrderingComposer get entryId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.vocabularyEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabularyEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.vocabularyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SentencePracticeEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentencePracticeEventsTable> {
  $$SentencePracticeEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SentencePracticeDirection, String>
  get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SentenceLevel, String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SentencePracticeOutcome, String>
  get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get practicedAt => $composableBuilder(
    column: $table.practicedAt,
    builder: (column) => column,
  );

  $$VocabularyEntriesTableAnnotationComposer get entryId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.entryId,
          referencedTable: $db.vocabularyEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VocabularyEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vocabularyEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$SentencePracticeEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentencePracticeEventsTable,
          SentencePracticeEventRow,
          $$SentencePracticeEventsTableFilterComposer,
          $$SentencePracticeEventsTableOrderingComposer,
          $$SentencePracticeEventsTableAnnotationComposer,
          $$SentencePracticeEventsTableCreateCompanionBuilder,
          $$SentencePracticeEventsTableUpdateCompanionBuilder,
          (SentencePracticeEventRow, $$SentencePracticeEventsTableReferences),
          SentencePracticeEventRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$SentencePracticeEventsTableTableManager(
    _$AppDatabase db,
    $SentencePracticeEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentencePracticeEventsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SentencePracticeEventsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SentencePracticeEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<SentencePracticeDirection> direction =
                    const Value.absent(),
                Value<SentenceLevel> level = const Value.absent(),
                Value<SentencePracticeOutcome> outcome = const Value.absent(),
                Value<DateTime> practicedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SentencePracticeEventsCompanion(
                id: id,
                entryId: entryId,
                direction: direction,
                level: level,
                outcome: outcome,
                practicedAt: practicedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required SentencePracticeDirection direction,
                required SentenceLevel level,
                required SentencePracticeOutcome outcome,
                required DateTime practicedAt,
                Value<int> rowid = const Value.absent(),
              }) => SentencePracticeEventsCompanion.insert(
                id: id,
                entryId: entryId,
                direction: direction,
                level: level,
                outcome: outcome,
                practicedAt: practicedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SentencePracticeEventsTable,
                    SentencePracticeEventRow
                  >(table),
                  $$SentencePracticeEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$SentencePracticeEventsTableReferences
                            ._entryIdTable(db),
                        referencedColumn:
                            $$SentencePracticeEventsTableReferences
                                ._entryIdTable(db)
                                .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SentencePracticeEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentencePracticeEventsTable,
      SentencePracticeEventRow,
      $$SentencePracticeEventsTableFilterComposer,
      $$SentencePracticeEventsTableOrderingComposer,
      $$SentencePracticeEventsTableAnnotationComposer,
      $$SentencePracticeEventsTableCreateCompanionBuilder,
      $$SentencePracticeEventsTableUpdateCompanionBuilder,
      (SentencePracticeEventRow, $$SentencePracticeEventsTableReferences),
      SentencePracticeEventRow,
      PrefetchHooks Function({bool entryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$VocabularyEntriesTableTableManager get vocabularyEntries =>
      $$VocabularyEntriesTableTableManager(_db, _db.vocabularyEntries);
  $$VocabularyMeaningsTableTableManager get vocabularyMeanings =>
      $$VocabularyMeaningsTableTableManager(_db, _db.vocabularyMeanings);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db, _db.flashcards);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db, _db.entryTags);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db, _db.reviewEvents);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SentencePracticeEventsTableTableManager get sentencePracticeEvents =>
      $$SentencePracticeEventsTableTableManager(
        _db,
        _db.sentencePracticeEvents,
      );
}
