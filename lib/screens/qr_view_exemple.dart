import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Importar o pacote para leitura de texto
import 'package:vision_app_3d/screens/home_page.dart';
import 'package:vision_app_3d/service/speechService.dart';
import 'insect_details_screen.dart';
import 'package:vision_app_3d/screens/insect.dart'; // Importar a classe Insect e o mapeamento insectData
// TODO organizar esta parte
class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final MobileScannerController controller = MobileScannerController();
  final FlutterTts _flutterTts = FlutterTts(); // Instância do TTS
  final SpeechService _speechService = SpeechService();
  bool isScanCompleted = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _configureTts().then((_) => _speakInstructions());
    _initSpeechService();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechService.stop(); // Para o serviço de voz
    super.dispose();
  }

  Future<void> _configureTts() async {
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _isListening = false;
      });
      _speechService.stop();
    });

    _flutterTts.setCompletionHandler(() async {
      setState(() => _isSpeaking = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _startListening();
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      if (mounted) _startListening();
    });

    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
  }

  Future<void> _speakInstructions() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(
      "Aponte o celular para o QR Code. Coloque o QR Code na área demarcada. "
          "A leitura será feita automaticamente. "
          "Diga 'voltar' para retornar.",
    );
  }

  Future<void> _initSpeechService() async {
    bool initialized = await _speechService.initialize(context: context);
    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falha ao inicializar reconhecimento de voz")),
      );
    }
  }

  Future<void> _startListening() async {
    if (_isSpeaking || !mounted || !_speechService.isInitialized) return;

    try {
      await _speechService.stop();
      await Future.delayed(const Duration(milliseconds: 200));

      await _speechService.listen(
        onResult: (command) {
          if (command.isNotEmpty) _handleVoiceCommand(command);
        },
        localeId: "pt-BR",
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        onSoundLevelChange: (level) {
          if (level > 0) print("Nível de som: $level dB");
        },
      );

      setState(() => _isListening = true);
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _handleVoiceCommand(String command) {
    final lowerCaseCommand = command.toLowerCase();
    print("Comando recebido: $lowerCaseCommand");

    if (_matchesCommand(lowerCaseCommand, 'voltar')) {
      _navigateBackToHome();
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = {
      'voltar': [
        'voltar',
        'volta',
        'retornar',
        'retorna',
        'voltar para trás',
        'vai voltar',
        'ir para trás',
        'voltar menu',
        'voltar início',
      ],
    };
    return variations[command]?.any((variant) => input.contains(variant)) ?? false;
  }

  void _navigateBackToHome() {
    _speechService.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void closeScreen() {
    isScanCompleted = false;
    _flutterTts.stop(); // Para o TTS caso um código seja detectado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text(
          'Escaneie o QR Code',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            _flutterTts.stop(); // Interrompe qualquer leitura
            Navigator.pop(context); // Volta para a tela anterior
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Coloque o QR Code na área demarcada",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "A leitura será feita automaticamente",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (barcodeCapture) {
                        if (!isScanCompleted) {
                          final String code = barcodeCapture.barcodes.first.rawValue ?? '';
                          print('Código escaneado: $code'); // Log para depuração
                          if (insectData.containsKey(code)) {
                            final insect = insectData[code]!;
                            isScanCompleted = true;
                            _flutterTts.stop(); // Para o TTS ao navegar para outra tela
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InsectDetailsScreen(
                                  insect: insect,
                                ),
                              ),
                            ).then((_) {
                              closeScreen(); // Reseta a tela após a navegação
                              _speakInstructions(); // Reproduz as instruções novamente
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('QR Code não reconhecido: $code')),
                            );
                          }
                        }
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "Developed by Estudantes",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}