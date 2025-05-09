// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database_connection.dart';
import 'data/data_definition.dart';   // gerado pelo Drift
import 'data/data_manager.dart';
import 'data/data_seeder.dart';
import 'app/vision_app_3d.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Abre conexão SQLite
  final executor = await openConnection();
  // 2) Instancia Database e DataManager
  final db = Database(executor);
  final manager = DataManager(db);
  // 3) Popula o banco se vazio
  await DataSeeder(manager).seedIfNeeded();

  // 4) Inicia o app fornecendo o DataManager
  runApp(
    Provider<DataManager>(
      create: (_) => manager,
      dispose: (_, m) => m.close(),
      child: const VisionApp3D(),
    ),
  );
}
