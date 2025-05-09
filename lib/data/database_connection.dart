// lib/data/database_connection.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Abre (ou cria) o arquivo SQLite em documents.
Future<QueryExecutor> openConnection() async {
  final docs = await getApplicationDocumentsDirectory();
  final file = File(p.join(docs.path, 'vision_app.sqlite'));
  return NativeDatabase(file);
}
