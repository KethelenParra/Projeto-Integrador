// data_definition.dart

import 'package:drift/drift.dart';

part 'data_definition.g.dart';

class Inseto extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text().withLength(min: 1, max: 50)();
  TextColumn get familia => text().withLength(min: 1, max: 50)();
  TextColumn get especie => text().withLength(min: 1, max: 50)();
  TextColumn get descricao => text().withLength(min: 1)();
  TextColumn get videoPath => text().withLength(min: 1, max: 255)();
}

abstract class InsetoView extends View {
  Inseto get inseto;

  @override
  Query as() => select([
        inseto.id,
        inseto.nome,
        inseto.familia,
        inseto.especie,
        inseto.descricao,
        inseto.videoPath, // novo campo
      ]).from(inseto);
}

@DriftDatabase(tables: [Inseto], views: [InsetoView])
class Database extends _$Database {
  Database(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            // adiciona a coluna videoPath na tabela inseto
            await m.addColumn(inseto, inseto.videoPath);
            // recria a view, se você estiver usando
            await m.createView(insetoView);
          }
        },
      );
}
