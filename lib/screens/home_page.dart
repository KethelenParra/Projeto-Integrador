import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vision_app_3d/service/speechService.dart';
import '../screens/qr_view_exemple.dart';
import '../screens/insect_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isSpeaking = false;
  int _selectedIndex = 0;
  bool _isInitialized = false;
  int _retryCount = 0;
  bool _wasCompletedClosed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async{
    if (_isInitialized) return;

    setState(() => _isInitialized = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      await _configureTTS();
      await _speakWelcomeMessage();
    }
  }

  Future<void> _initializeVoiceFeatures() async {
    try {
      print("Inicializando voice features...");
      await _configureTTS();
      await _speakWelcomeMessage();

      bool initialized = await _speechService.initialize(context: context);
      if (!initialized && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao iniciar reconhecimento de voz")),
        );
      }
    } catch (e) {
      print("Erro ao inicializar voice features: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _configureTTS() async {
    print("Configurando TTS...");
    try {
      await _flutterTts.setLanguage("pt-BR");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        print("TTS started");
        setState(() => _isSpeaking = true);
        _speechService.stop().catchError((e) => print("Erro ao parar reconhecimento: $e"));
      });

      _flutterTts.setCompletionHandler(() async {
        print("TTS completed");
        setState(() => _isSpeaking = false);
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && !_isListening) {
          await _startContinuousListeningWithRetry();
        }
      });

      _flutterTts.setErrorHandler((msg) async {
        print("Erro TTS: $msg");
        setState(() => _isSpeaking = false);
        if (mounted && !_isListening) {
          await Future.delayed(const Duration(milliseconds: 300));
          await _startContinuousListeningWithRetry();
        }
      });
    } catch (e) {
      print("Erro ao configurar TTS: $e");
    }
  }

  Future<void> _startContinuousListeningWithRetry({int retryCount = 0}) async {
    if (retryCount >= 3) {
      print("Máximo de tentativas alcançado");
      return;
    }

    try {
      await _startContinuousListening();
    } catch (e) {
      print("Erro ao iniciar escuta, tentativa ${retryCount + 1}: $e");
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _startContinuousListeningWithRetry(retryCount: retryCount + 1);
      }
    }
  }

  Future<void> _startAudioFlow() async {
    if (!_speechService.permissionGranted || _speechService.isListening || _isSpeaking) {
      print(
          "Cannot start audio flow: Permission: ${_speechService.permissionGranted}, Listening: ${_speechService.isListening}, Speaking: $_isSpeaking");
      return;
    }

    if (!_speechService.isListening && _speechService.isInitialized) {
      await _startContinuousListening();
    } else if (!_speechService.isInitialized) {
      print("SpeechService not initialized, attempting to initialize...");
      bool initialized = await _speechService.initialize(context: context);
      if (initialized) {
        await _startContinuousListening();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Falha ao inicializar reconhecimento de voz")),
          );
        }
      }
    }
  }

  Future<void> _startContinuousListening() async {
    if (_isSpeaking || !mounted) {
      print("Condições não atendidas para iniciar escuta");
      return;
    }

    try {
      print("Iniciando escuta contínua...");

      // Reinicialize o serviço se necessário
      if (!_speechService.isInitialized) {
        print("Reinicializando SpeechService...");
        await _speechService.initialize(context: context);
      }

      await _speechService.stop();
      await Future.delayed(const Duration(milliseconds: 200));

      await _speechService.listen(
        onResult: (command) {
          if (command.isNotEmpty) {
            _handleVoiceCommand(command);
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 10),
        // Aumente o tempo
        pauseFor: const Duration(seconds: 2),
        onSoundLevelChange: (level) {
          if (level > 0) print("Nível de som: $level dB");
        },
      );

      setState(() => _isListening = true);
      print("Escuta iniciada com sucesso");
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      setState(() => _isListening = false);
      rethrow;
    }
  }

  void _handleVoiceCommand(String command) {
    final lowerCaseCommand = command.toLowerCase();
    print("Comando transcrito: '$lowerCaseCommand'");

    if (_matchesCommand(lowerCaseCommand, 'escanear')) {
      print("Comando 'escanear' reconhecido!");
      _executeCommand('escanear', _navigateToQRView);
    } else if (_matchesCommand(lowerCaseCommand, 'lista')) {
      print("Comando 'lista' reconhecido!");
      _executeCommand('lista', _navigateToListView);
    } else if (_matchesCommand(lowerCaseCommand, 'voltar')) {
      print("Comando 'voltar' reconhecido!");
      if (_selectedIndex == 0) {
        _flutterTts.speak("Você já está na tela inicial.");
      } else {
        setState(() => _selectedIndex = 0);
      }
    } else {
      print("Comando não reconhecido: '$lowerCaseCommand'");
      _handleUnrecognizedCommand();
    }
  }

  Future<void> _handleUnrecognizedCommand() async {
    try {
      await _flutterTts.speak("Comando não reconhecido. Tente 'escanear' ou 'lista'.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comando não reconhecido. Tente 'escanear' ou 'lista'.")),
        );
      }
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_isSpeaking && mounted) {
        _startContinuousListening();
      }
    } catch (e) {
      print("Erro ao lidar com comando não reconhecido: $e");
      if (!_isSpeaking && mounted) {
        _startContinuousListening();
      }
    }
  }

  Future<void> _handleListeningError(dynamic error) async {
    print("Tratando erro de escuta: $error");

    if (_retryCount < 3) {
      _retryCount++;
      print("Tentativa $_retryCount de reiniciar escuta");
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && !_isSpeaking) {
        await _startContinuousListening();
      }
    } else {
      _retryCount = 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Problema com o microfone. Tente novamente.")),
        );
      }
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = {
      'escanear': [
        'escanear', 'escaner', 'scan', 'scanner', 'scannear',
        'escanea', 'escan', 'escaniar', 'eskanear', 'escanearr',
        'escane', 'escan', 'escania', 'escanne', 'escanear',
        'eskenear', 'eskaner', 'esc', 'esca', 'escanir', // Mais variações
      ],
      'lista': [
        'lista', 'list', 'listar', 'listas', 'lissta',
        'listaa', 'lis', 'listinha', 'listah', 'lixta',
        'lishta', 'lesta', 'lest', 'listo', 'listu',
        'listh', 'liista', 'leesta', 'listta', 'lizta',
        'listea', 'listi', 'lisst', 'listae', 'listra',
        'list', 'listar', 'list', 'listarr', 'listre', // Mais variações
        'listara', 'listas', 'listir', 'listare', 'listor',
      ],
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
    final matched = variations[command.toLowerCase()]?.any((variant) => input.contains(variant)) ?? false;
    print("Verificando comando '$command': input='$input', matched=$matched");
    return matched;
  }

  void _executeCommand(String command, Function() action) async {
    print("Executando comando: $command");
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak("Executando $command");
    _vibrate();
    action();
  }

  Future<void> _speakWelcomeMessage() async {
    if (_isSpeaking) return;

    try {
      setState(() => _isSpeaking = true);

      String message = "Obrigado por utilizar o Vision App, um aplicativo dedicado a "
            "promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para "
            "explorar e descobrir informações sobre diferentes espécies de "
            "insetos, com recursos em áudio, vídeos e através da experiência "
            "com as mãos. Viva uma experiência interessante. Na parte inferior "
            "da tela haverá duas opções de comandos de voz para navegar. Basta "
            "dizer: lista, para acessar a tela com todas as opções de insetos "
            "ou: escanear, para abrir a tela de QR Code e obter informações "
            "detalhadas sobre o inseto escaneado.";

      await _flutterTts.speak(message);
    } catch (e) {
      print("Erro ao falar mensagem: $e");
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  void _navigateToScreen(Widget screen) async{
    await _stopAllAudio();
    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));

    if (mounted){
      _initializeVoiceFeatures();
    }
  }

  void _navigateToQRView() async {
    _navigateToScreen(const QRViewExample());
  }

  void _navigateToListView() async {
    _navigateToScreen(const InsectListScreen());
  }

  Future<void> _stopAllAudio() async {
    try {
      await _flutterTts.stop();
      await _speechService.stop();
      setState(() {
        _isSpeaking = false;
        _isListening = false;
      });
    } catch (e) {
      print("Erro ao parar áudio: $e");
    }
  }

  @override
  void dispose() {
    _stopAllAudio();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_isSpeaking) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _initializeVoiceFeatures();
          });
        }
        break;
      case AppLifecycleState.paused:
        _stopAllAudio();
        break;
      case AppLifecycleState.detached:
        _wasCompletedClosed = true; // Marca que o app foi completamente fechado
        break;
      default:
        break;
    }
  }


  void _onItemTapped(int index) {
    _vibrate();
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRViewExample(),
        ),
      ).then((_) {
        _startAudioFlow();
      });
    } else if (index == 1) {
      setState(() {
        _selectedIndex = index;
      });
      _startAudioFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFEAB08A),
                child: Icon(
                  Icons.bug_report,
                  size: 50,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Vision App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Obrigado por utilizar o Vision App, um aplicativo dedicado'
                  ' a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descobrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
      const InsectListScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFEAB08A),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Escanear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lista',
          ),
        ],
      ),
    );
  }
}
