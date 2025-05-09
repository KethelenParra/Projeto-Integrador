// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_definition.dart';

// ignore_for_file: type=lint
class $InsetoTable extends Inseto with TableInfo<$InsetoTable, InsetoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsetoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _familiaMeta =
      const VerificationMeta('familia');
  @override
  late final GeneratedColumn<String> familia = GeneratedColumn<String>(
      'familia', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _especieMeta =
      const VerificationMeta('especie');
  @override
  late final GeneratedColumn<String> especie = GeneratedColumn<String>(
      'especie', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao =
      GeneratedColumn<String>('descricao', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _videoPathMeta =
      const VerificationMeta('videoPath');
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
      'video_path', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, nome, familia, especie, descricao, videoPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inseto';
  @override
  VerificationContext validateIntegrity(Insertable<InsetoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('familia')) {
      context.handle(_familiaMeta,
          familia.isAcceptableOrUnknown(data['familia']!, _familiaMeta));
    } else if (isInserting) {
      context.missing(_familiaMeta);
    }
    if (data.containsKey('especie')) {
      context.handle(_especieMeta,
          especie.isAcceptableOrUnknown(data['especie']!, _especieMeta));
    } else if (isInserting) {
      context.missing(_especieMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('video_path')) {
      context.handle(_videoPathMeta,
          videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta));
    } else if (isInserting) {
      context.missing(_videoPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InsetoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InsetoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      familia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}familia'])!,
      especie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}especie'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao'])!,
      videoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_path'])!,
    );
  }

  @override
  $InsetoTable createAlias(String alias) {
    return $InsetoTable(attachedDatabase, alias);
  }
}

class InsetoData extends DataClass implements Insertable<InsetoData> {
  final int id;
  final String nome;
  final String familia;
  final String especie;
  final String descricao;
  final String videoPath;
  const InsetoData(
      {required this.id,
      required this.nome,
      required this.familia,
      required this.especie,
      required this.descricao,
      required this.videoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['familia'] = Variable<String>(familia);
    map['especie'] = Variable<String>(especie);
    map['descricao'] = Variable<String>(descricao);
    map['video_path'] = Variable<String>(videoPath);
    return map;
  }

  InsetoCompanion toCompanion(bool nullToAbsent) {
    return InsetoCompanion(
      id: Value(id),
      nome: Value(nome),
      familia: Value(familia),
      especie: Value(especie),
      descricao: Value(descricao),
      videoPath: Value(videoPath),
    );
  }

  factory InsetoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InsetoData(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      familia: serializer.fromJson<String>(json['familia']),
      especie: serializer.fromJson<String>(json['especie']),
      descricao: serializer.fromJson<String>(json['descricao']),
      videoPath: serializer.fromJson<String>(json['videoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'familia': serializer.toJson<String>(familia),
      'especie': serializer.toJson<String>(especie),
      'descricao': serializer.toJson<String>(descricao),
      'videoPath': serializer.toJson<String>(videoPath),
    };
  }

  InsetoData copyWith(
          {int? id,
          String? nome,
          String? familia,
          String? especie,
          String? descricao,
          String? videoPath}) =>
      InsetoData(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        familia: familia ?? this.familia,
        especie: especie ?? this.especie,
        descricao: descricao ?? this.descricao,
        videoPath: videoPath ?? this.videoPath,
      );
  InsetoData copyWithCompanion(InsetoCompanion data) {
    return InsetoData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      familia: data.familia.present ? data.familia.value : this.familia,
      especie: data.especie.present ? data.especie.value : this.especie,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InsetoData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('familia: $familia, ')
          ..write('especie: $especie, ')
          ..write('descricao: $descricao, ')
          ..write('videoPath: $videoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, familia, especie, descricao, videoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InsetoData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.familia == this.familia &&
          other.especie == this.especie &&
          other.descricao == this.descricao &&
          other.videoPath == this.videoPath);
}

class InsetoCompanion extends UpdateCompanion<InsetoData> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> familia;
  final Value<String> especie;
  final Value<String> descricao;
  final Value<String> videoPath;
  const InsetoCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.familia = const Value.absent(),
    this.especie = const Value.absent(),
    this.descricao = const Value.absent(),
    this.videoPath = const Value.absent(),
  });
  InsetoCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required String familia,
    required String especie,
    required String descricao,
    required String videoPath,
  })  : nome = Value(nome),
        familia = Value(familia),
        especie = Value(especie),
        descricao = Value(descricao),
        videoPath = Value(videoPath);
  static Insertable<InsetoData> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? familia,
    Expression<String>? especie,
    Expression<String>? descricao,
    Expression<String>? videoPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (familia != null) 'familia': familia,
      if (especie != null) 'especie': especie,
      if (descricao != null) 'descricao': descricao,
      if (videoPath != null) 'video_path': videoPath,
    });
  }

  InsetoCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String>? familia,
      Value<String>? especie,
      Value<String>? descricao,
      Value<String>? videoPath}) {
    return InsetoCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      familia: familia ?? this.familia,
      especie: especie ?? this.especie,
      descricao: descricao ?? this.descricao,
      videoPath: videoPath ?? this.videoPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (familia.present) {
      map['familia'] = Variable<String>(familia.value);
    }
    if (especie.present) {
      map['especie'] = Variable<String>(especie.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsetoCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('familia: $familia, ')
          ..write('especie: $especie, ')
          ..write('descricao: $descricao, ')
          ..write('videoPath: $videoPath')
          ..write(')'))
        .toString();
  }
}

class InsetoViewData extends DataClass {
  final int id;
  final String nome;
  final String familia;
  final String especie;
  final String descricao;
  final String videoPath;
  const InsetoViewData(
      {required this.id,
      required this.nome,
      required this.familia,
      required this.especie,
      required this.descricao,
      required this.videoPath});
  factory InsetoViewData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InsetoViewData(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      familia: serializer.fromJson<String>(json['familia']),
      especie: serializer.fromJson<String>(json['especie']),
      descricao: serializer.fromJson<String>(json['descricao']),
      videoPath: serializer.fromJson<String>(json['videoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'familia': serializer.toJson<String>(familia),
      'especie': serializer.toJson<String>(especie),
      'descricao': serializer.toJson<String>(descricao),
      'videoPath': serializer.toJson<String>(videoPath),
    };
  }

  InsetoViewData copyWith(
          {int? id,
          String? nome,
          String? familia,
          String? especie,
          String? descricao,
          String? videoPath}) =>
      InsetoViewData(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        familia: familia ?? this.familia,
        especie: especie ?? this.especie,
        descricao: descricao ?? this.descricao,
        videoPath: videoPath ?? this.videoPath,
      );
  @override
  String toString() {
    return (StringBuffer('InsetoViewData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('familia: $familia, ')
          ..write('especie: $especie, ')
          ..write('descricao: $descricao, ')
          ..write('videoPath: $videoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, familia, especie, descricao, videoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InsetoViewData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.familia == this.familia &&
          other.especie == this.especie &&
          other.descricao == this.descricao &&
          other.videoPath == this.videoPath);
}

class $InsetoViewView extends ViewInfo<$InsetoViewView, InsetoViewData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$Database attachedDatabase;
  $InsetoViewView(this.attachedDatabase, [this._alias]);
  $InsetoTable get inseto => attachedDatabase.inseto.createAlias('t0');
  @override
  List<GeneratedColumn> get $columns =>
      [id, nome, familia, especie, descricao, videoPath];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'inseto_view';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $InsetoViewView get asDslTable => this;
  @override
  InsetoViewData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InsetoViewData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      familia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}familia'])!,
      especie: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}especie'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao'])!,
      videoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_path'])!,
    );
  }

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      generatedAs: GeneratedAs(inseto.id, false), type: DriftSqlType.int);
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      generatedAs: GeneratedAs(inseto.nome, false), type: DriftSqlType.string);
  late final GeneratedColumn<String> familia = GeneratedColumn<String>(
      'familia', aliasedName, false,
      generatedAs: GeneratedAs(inseto.familia, false),
      type: DriftSqlType.string);
  late final GeneratedColumn<String> especie = GeneratedColumn<String>(
      'especie', aliasedName, false,
      generatedAs: GeneratedAs(inseto.especie, false),
      type: DriftSqlType.string);
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, false,
      generatedAs: GeneratedAs(inseto.descricao, false),
      type: DriftSqlType.string);
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
      'video_path', aliasedName, false,
      generatedAs: GeneratedAs(inseto.videoPath, false),
      type: DriftSqlType.string);
  @override
  $InsetoViewView createAlias(String alias) {
    return $InsetoViewView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(inseto)..addColumns($columns));
  @override
  Set<String> get readTables => const {'inseto'};
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $InsetoTable inseto = $InsetoTable(this);
  late final $InsetoViewView insetoView = $InsetoViewView(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [inseto, insetoView];
}

typedef $$InsetoTableCreateCompanionBuilder = InsetoCompanion Function({
  Value<int> id,
  required String nome,
  required String familia,
  required String especie,
  required String descricao,
  required String videoPath,
});
typedef $$InsetoTableUpdateCompanionBuilder = InsetoCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<String> familia,
  Value<String> especie,
  Value<String> descricao,
  Value<String> videoPath,
});

class $$InsetoTableFilterComposer extends Composer<_$Database, $InsetoTable> {
  $$InsetoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get familia => $composableBuilder(
      column: $table.familia, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get especie => $composableBuilder(
      column: $table.especie, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoPath => $composableBuilder(
      column: $table.videoPath, builder: (column) => ColumnFilters(column));
}

class $$InsetoTableOrderingComposer extends Composer<_$Database, $InsetoTable> {
  $$InsetoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get familia => $composableBuilder(
      column: $table.familia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get especie => $composableBuilder(
      column: $table.especie, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoPath => $composableBuilder(
      column: $table.videoPath, builder: (column) => ColumnOrderings(column));
}

class $$InsetoTableAnnotationComposer
    extends Composer<_$Database, $InsetoTable> {
  $$InsetoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get familia =>
      $composableBuilder(column: $table.familia, builder: (column) => column);

  GeneratedColumn<String> get especie =>
      $composableBuilder(column: $table.especie, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);
}

class $$InsetoTableTableManager extends RootTableManager<
    _$Database,
    $InsetoTable,
    InsetoData,
    $$InsetoTableFilterComposer,
    $$InsetoTableOrderingComposer,
    $$InsetoTableAnnotationComposer,
    $$InsetoTableCreateCompanionBuilder,
    $$InsetoTableUpdateCompanionBuilder,
    (InsetoData, BaseReferences<_$Database, $InsetoTable, InsetoData>),
    InsetoData,
    PrefetchHooks Function()> {
  $$InsetoTableTableManager(_$Database db, $InsetoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InsetoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InsetoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InsetoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> familia = const Value.absent(),
            Value<String> especie = const Value.absent(),
            Value<String> descricao = const Value.absent(),
            Value<String> videoPath = const Value.absent(),
          }) =>
              InsetoCompanion(
            id: id,
            nome: nome,
            familia: familia,
            especie: especie,
            descricao: descricao,
            videoPath: videoPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            required String familia,
            required String especie,
            required String descricao,
            required String videoPath,
          }) =>
              InsetoCompanion.insert(
            id: id,
            nome: nome,
            familia: familia,
            especie: especie,
            descricao: descricao,
            videoPath: videoPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InsetoTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $InsetoTable,
    InsetoData,
    $$InsetoTableFilterComposer,
    $$InsetoTableOrderingComposer,
    $$InsetoTableAnnotationComposer,
    $$InsetoTableCreateCompanionBuilder,
    $$InsetoTableUpdateCompanionBuilder,
    (InsetoData, BaseReferences<_$Database, $InsetoTable, InsetoData>),
    InsetoData,
    PrefetchHooks Function()>;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$InsetoTableTableManager get inseto =>
      $$InsetoTableTableManager(_db, _db.inseto);
}
