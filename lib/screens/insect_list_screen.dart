import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart'; // Import para vibração personalizada
import 'package:vision_app_3d/screens/quiz_screen.dart';
import 'insect_details_screen.dart';
import 'home_page.dart';
import 'quiz_screen.dart';
import 'insect.dart'; // Importa os dados dos insetos

class InsectListScreen extends StatefulWidget {
  const InsectListScreen({super.key});

  @override
  State<InsectListScreen> createState() => _InsectListScreenState();
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
      "Escolha um inseto da lista para ver mais informações sobre ele. Fale o nome do inseto desejado para abrir a tela de detalhes. Insetos disponiveis: Escorpião. Borboleta. Barbeiro. Abelha. Aranha.",
    );
  }

  // Função para acionar a vibração personalizada
  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200); // Vibração de 200ms
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text(
          'Lista de Insetos',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate(); // Vibração ao clicar no botão de voltar
            _flutterTts.stop(); // Para o TTS ao sair
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Texto de instrução
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Escolha um inseto da lista abaixo para ver mais informações.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: insectData.length,
              itemBuilder: (context, index) {
                final insect = insectData.values.elementAt(index);
                return Card(
                  color: Colors.white,
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      insect.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onTap: () {
                      _vibrate(); // Vibração ao escolher um inseto
                      _flutterTts.stop(); // Para o TTS ao mudar de tela
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InsectDetailsScreen(insect: insect),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}