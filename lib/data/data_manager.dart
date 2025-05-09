// data_manager.dart

import 'package:drift/drift.dart';
import 'data_definition.dart';

class DataManager {
  final Database _db;
  DataManager(this._db);

  /// Insere um novo inseto (use InsetoCompanion.insert(...))
  Future<int> insertInseto(Insertable<InsetoData> inseto) {
    return _db.into(_db.inseto).insert(inseto);
  }

  /// Retorna todos os insetos
  Future<List<InsetoData>> getAllInsetos() {
    return _db.select(_db.inseto).get();
  }

  /// Stream que emite sempre que a tabela inseto mudar
  Stream<List<InsetoData>> watchAllInsetos() {
    return _db.select(_db.inseto).watch();
  }

  /// Busca um inseto pelo [id], ou null se não existir
  Future<InsetoData?> getInsetoById(int id) {
    return (_db.select(_db.inseto)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Atualiza um inseto (precisa conter o id no companion)
  Future<bool> updateInseto(Insertable<InsetoData> inseto) {
    return _db.update(_db.inseto).replace(inseto);
  }

  /// Deleta um inseto pelo [id]
  Future<int> deleteInseto(int id) {
    return (_db.delete(_db.inseto)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Fecha o banco (opcional)
  Future<void> close() => _db.close();
}
