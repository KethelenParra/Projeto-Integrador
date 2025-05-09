import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../data/data_manager.dart';
import '../data/data_definition.dart';
import 'insect_details_screen.dart';
import 'home_page.dart';

class InsectListScreen extends StatefulWidget {
  const InsectListScreen({Key? key}) : super(key: key);

  @override
  _InsectListScreenState createState() => _InsectListScreenState();
}

class _InsectListScreenState extends State<InsectListScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakInstruction();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(
      "Escolha um inseto da lista para ver mais informações sobre ele.",
    );
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<DataManager>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text('Lista de Insetos', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate();
            _flutterTts.stop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: StreamBuilder<List<InsetoData>>(
        stream: manager.watchAllInsetos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final insetos = snapshot.data ?? [];
          if (insetos.isEmpty) {
            return const Center(child: Text('Nenhum inseto encontrado.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: insetos.length,
            itemBuilder: (ctx, i) {
              final inseto = insetos[i];
              return Card(
                color: Colors.white,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(inseto.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(inseto.familia),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () {
                    _vibrate();
                    _flutterTts.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InsectDetailsScreen(inseto: inseto),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
