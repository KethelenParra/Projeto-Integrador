import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'data_manager.dart';
import 'data_definition.dart';

class DataSeeder {
  final DataManager manager;

  DataSeeder(this.manager);

  /// Só insere se o banco estiver vazio
  Future<void> seedIfNeeded() async {
    final all = await manager.getAllInsetos();
    if (all.isNotEmpty) return;

    final jsonStr = await rootBundle.loadString('lib/assets/data/insects.json');
    final List lista = json.decode(jsonStr);

    for (final item in lista.cast<Map<String, dynamic>>()) {
      final companion = InsetoCompanion.insert(
        nome: item['nome'] as String,
        familia: item['familia'] as String,
        especie: item['especie'] as String,
        descricao: item['descricao'] as String,
        videoPath: item['videoPath'] as String,
      );
      await manager.insertInseto(companion);

      final jsonStr =
          await rootBundle.loadString('lib/assets/data/insects.json');
      print(
          'JSON carregado: ${jsonStr.substring(0, 50)}...'); // imprime os primeiros 50 caracteres
    }
  }
}
