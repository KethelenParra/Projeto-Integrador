import 'package:flutter/material.dart';
import 'package:vision_app_3d/service/speech_service.dart';
import 'package:vision_app_3d/service/tts_service.dart'; // Importa o TtsService
import 'package:vision_app_3d/service/vibration_service.dart'; // Importa o VibrationService
import '../screens/qr_view_exemple.dart';
import '../screens/insect_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService(); // Usa o TtsService
  final SpeechService _speechService = SpeechService();
  final VibrationService _vibrationService = VibrationService(); // Usa o VibrationService
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    setState(() => _isInitialized = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _initializeVoiceFeatures();
    }
  }

  Future<void> _initializeVoiceFeatures() async {
    try {
      print("Inicializando voice features...");
      await _configureTts();
      bool initialized = await _speechService.initialize(context: context);
      if (!initialized) {
        print("Falha ao inicializar SpeechService: ${_speechService.lastError}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao iniciar reconhecimento de voz: ${_speechService.lastError}")),
          );
        }
        return;
      }
      await _speakWelcomeMessage();
    } catch (e) {
      print("Erro ao inicializar voice features: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _configureTts() async {
    try {
      await _ttsService.initialize(
        // Usa o método initialize do TtsService
        language: "pt-BR",
        speechRate: 0.5,
        volume: 1.0,
        onComplete: () async {
          setState(() => _isSpeaking = false);
          print("TTS completed speaking");
          if (mounted && !_isListening) {
            await Future.delayed(const Duration(milliseconds: 500));
            await _startContinuousListeningWithRetry();
          }
        },
        onError: (msg) async {
          setState(() {
            _isSpeaking = false;
            _isListening = false;
          });
          print("Erro no TTS: $msg");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro no TTS: $msg")));
            await Future.delayed(const Duration(milliseconds: 500));
            await _startContinuousListeningWithRetry();
          }
        },
      );
    } catch (e) {
      print("Erro ao configurar TTS: $e");
    }
  }

  Future<void> _speakWelcomeMessage() async {
    if (_isSpeaking) return;
    try {
      setState(() => _isSpeaking = true);
      String message = "Obrigado por utilizar o Vision App, um aplicativo dedicado a "
          "promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para "
          "explorar e descobrir informações sobre diferentes espécies de "
          "insetos, com recursos em áudio, vídeos e através da experiência "
          "com as mãos. Viva uma experiência interessante. Diga lista para ir para a lista de insetos ou escanear para ir para a página do QR Code.";
      await _ttsService.speak(message); // Usa o método speak do TtsService
    } catch (e) {
      print("Erro ao falar mensagem: $e");
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _startContinuousListeningWithRetry({int retryCount = 0}) async {
    const maxRetries = 5;
    if (retryCount >= maxRetries) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Falha ao iniciar reconhecimento de voz após várias tentativas.")),
        );
        await _ttsService.speak(
            "Não foi possível iniciar o reconhecimento de voz. Verifique as permissões ou tente novamente."); // Usa o método speak do TtsService
      }
      print("Máximo de retries atingido");
      return;
    }

    try {
      print("Tentativa $retryCount de iniciar escuta...");
      setState(() => _isListening = false);
      await _speechService.stop();
      if (!await _speechService.checkPermissions(context: context)) {
        throw Exception("Permissão de microfone não concedida");
      }
      await _startContinuousListening();
    } catch (e) {
      print("Tentativa $retryCount falhou: $e");
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        await _speechService.reset();
        await _speechService.initialize(context: context);
        await _startContinuousListeningWithRetry(retryCount: retryCount + 1);
      }
    }
  }

  Future<void> _startContinuousListening() async {
    if (_isSpeaking || !mounted || !_speechService.permissionGranted) {
      print("Não pode iniciar escuta: Speaking=$_isSpeaking, Mounted=$mounted, Permission=${_speechService.permissionGranted}");
      return;
    }

    try {
      print("Iniciando escuta contínua...");
      if (!_speechService.isInitialized) {
        print("Reinicializando SpeechService...");
        bool initialized = await _speechService.initialize(context: context);
        if (!initialized) {
          throw Exception("Failed to initialize SpeechService: ${_speechService.lastError}");
        }
      }

      await _speechService.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      await _speechService.listen(
        onResult: (command) {
          print("Resultado recebido: '$command'");
          _handleVoiceCommand(command);
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 10),
        onSoundLevelChange: (level) {
          print("Nível de som: $level");
          if (level < -10) {
            print("Aviso: Nível de som muito baixo, microfone pode não estar captando");
          }
        },
      );

      setState(() => _isListening = true);
      _vibrationService.vibrate(); // Usa o método vibrate do VibrationService
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microfone ativo. Fale seu comando.")),
        );
      }
      print("Escuta iniciada com sucesso");
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      setState(() => _isListening = false);
      rethrow;
    }
  }

  void _handleVoiceCommand(String command) async {
    final lowerCaseCommand = command.toLowerCase();
    print("🟢 Processando comando: '$lowerCaseCommand'");

    try {
      await _speechService.stop();
      setState(() => _isListening = false);

      if (command.isEmpty) {
        print("Comando vazio recebido, provavelmente erro no reconhecimento");
        await _ttsService.speak("Nenhum comando detectado. Diga lista ou escanear."); // Usa o método speak do TtsService
        _startContinuousListening();
        _vibrationService.vibrate(duration: 100); // Usa o método vibrate do VibrationService
      } else if (_matchesCommand(lowerCaseCommand, 'escanear')) {
        await _executeCommand('Direcionando para a tela de QR Code', _navigateToQRView);
      } else if (_matchesCommand(lowerCaseCommand, 'lista')) {
        await _executeCommand('Direcionando para a lista de insetos', _navigateToListView);
      } else {
        await _ttsService.speak("Comando não reconhecido. Diga lista ou escanear."); // Usa o método speak do TtsService
        _vibrationService.vibrate(duration: 100); // Usa o método vibrate do VibrationService
      }
    } catch (e) {
      print("🔴 Erro no handleVoiceCommand: $e");
    } finally {
      if (mounted && !_isSpeaking && !_isListening) {
        print("🔄 Reiniciando escuta...");
        await Future.delayed(const Duration(milliseconds: 500));
        await _startContinuousListeningWithRetry();
      }
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = {
      'escanear': ['escanear', 'scan', 'escaner', 'scanner'],
      'lista': ['lista', 'list', 'listar', 'ista', 'sta', 'ta', 'lis', 'li', 'li'],
    };
    bool matched = variations[command.toLowerCase()]?.any((variant) => input.contains(variant)) ?? false;
    print("Verificando comando '$command': input='$input', matched=$matched");
    return matched;
  }

  Future<void> _executeCommand(String command, Function() action) async {
    _vibrationService.vibrate(); // Usa o método vibrate do VibrationService
    await _ttsService.speak(command); // Usa o método speak do TtsService
    await Future.delayed(const Duration(milliseconds: 800));
    action();
  }

  void _navigateToScreen(Widget screen) async {
    await _stopAllAudio();
    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    if (mounted) _initializeVoiceFeatures();
  }

  void _navigateToQRView() => _navigateToScreen(const QRViewExample());

  void _navigateToListView() {
    _vibrationService.vibrate(); // Usa o método vibrate do VibrationService
    _navigateToScreen(const InsectListScreen());
  }

  Future<void> _stopAllAudio() async {
    try {
      await _ttsService.stop(); // Usa o método stop do TtsService
      await _speechService.stop();
      setState(() {
        _isSpeaking = false;
        _isListening = false;
      });
      print("All audio stopped successfully");
    } catch (e) {
      print("Error stopping audio: $e");
    }
  }

  @override
  void dispose() {
    _stopAllAudio();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && !_isSpeaking) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _initializeVoiceFeatures();
        });
      }
    } else if (state == AppLifecycleState.paused) {
      _stopAllAudio();
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      _navigateToScreen(const QRViewExample());
    } else if (index == 1) {
      _navigateToScreen(const InsectListScreen());
    }
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
                child: Icon(Icons.bug_report, size: 50, color: Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 15),
              const Text('Vision App', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Bem-vindo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Obrigado por utilizar o Vision App, um aplicativo dedicado'
                  ' a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descobrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFEAB08A),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
        ],
      ),
    );
  }
}
