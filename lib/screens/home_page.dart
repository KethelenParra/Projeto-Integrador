import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../screens/qr_view_exemple.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();

    // Lê o texto ao iniciar o app
    _speakFallbackText();
    _initSpeech();
  }

  Future<void> _speakFallbackText() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(
        "Bem-vindo ao Vision App. "
            "Obrigado por utilizar o "
            "Vision "
            "App, um aplicativo dedicado a promover o aprendizado sobre o "
            "mundo dos insetos de forma inclusiva. Toque ou diga 'Iniciar' "
            "para explorar e descobrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante. Para começar, toque no botão Iniciar na parte inferior da tela.");
  }

  Future<void> _initSpeech() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => print("Erro: $error"),
    );

    /*
    * Verifica se o reconhecimento de voz está disponível
    * */
    if (available) {
      _startListening();
    } else {
      print("Reconhecimento de voz não está disponível");
    }
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if(!status.isGranted){
      status = await Permission.microphone.request();
      if(status.isDenied){
        print("Permissão do microfone negada");
      }
    }
  }

  void _startListening() async {
    await requestMicrophonePermission();/*solicita permissão do microfone*/
    if (!_isListening) {
      try{
        await _speechToText.listen(
            onResult: (result) {
              if (result.recognizedWords.toLowerCase() == "iniciar") {
                _navigateToQRView();
              }
            },
            localeId: "pt-BR");

        setState(() => _isListening = true);
      } catch (e){
        print("Erro ao iniciar a escuta: $e");
      }
    }
  }

  void _navigateToQRView() {
    _speechToText.stop(); /*Para a escuta antes de navegar*/
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewExample()),
    ).then((_) {
      _speakFallbackText();
      _startListening(); /*Inicia a escuta ao retornar*/
    });
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Para o TTS ao sair
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFEAB08A),
                child: Icon(
                  Icons.bug_report,
                  size: 50,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Vision App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Obrigado por '
                      'utilizar o Vision App, um '
                      'aplicativo '
                      'dedicado a promover o aprendizado sobre o mundo dos '
                      'insetos de forma inclusiva. Toque ou diga "Iniciar" '
                      'para explorar e descobrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos.\nViva uma experiência interessante.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Diga "Iniciar" ou toque no botão abaixo para começar.',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB08A),
                  padding:const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  // Navegar para a próxima tela
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRViewExample(),
                    ),
                  ).then((_) {
                    // Lê o texto novamente ao retornar
                    _speakFallbackText();
                  });
                },
                child: const Text(
                  'Iniciar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
