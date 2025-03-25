import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart'; // Import para vibração personalizada
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../screens/qr_view_exemple.dart';
import '../screens/insect_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _permissionGranted = false;
  int _selectedIndex = 0; // Exibe a tela de boas-vindas por padrão
  bool _firstTime = true;
  DateTime? _lastCommandTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions().then((_) { // Verifique permissões primeiro
      if (_permissionGranted) {
        _initializeVoiceFeatures();
      }
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    setState(() => _permissionGranted = status.isGranted);

    if (!_permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ative as permissões do microfone nas configurações'))
      );
    }
  }

  Future<void> _initAudioServices() async {
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();

    await _configureTTS();
    await _initSpeechRecognition();

    _startInfiniteListening();
    _speakWelcomeMessage();
  }

  void _startInfiniteListening() {
    if (!_permissionGranted || _isListening) return;

    _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          print("Comando reconhecido: $command");
          _lastCommandTime = DateTime.now();

          if (command.contains('escanear')) {
            _navigateToQRView();
          } else if (command.contains('lista')) {
            _navigateToListView();
          }
        }
      },
      localeId: 'pt-BR',
      listenMode: stt.ListenMode.dictation, // Modo ditado para captura contínua
      cancelOnError: false,
      partialResults: false,
      listenFor: Duration(minutes: 30), // Tempo longo de escuta
      pauseFor: Duration(seconds: 1),
      onSoundLevelChange: (level) {
        // Pode ser usado para feedback visual do nível de áudio
      },
    ).then((value) {
      if (mounted) {
        setState(() => _isListening = value ?? false);
        // Reinicia imediatamente se parou sem comando
        if (value == false && !_isSpeaking) {
          _startInfiniteListening();
        }
      }
    });
  }

  Future<void> _initializeVoiceFeatures() async {
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();

    await _configureTTS();
    await _checkMicrophonePermission();
    if (_permissionGranted) {
      await _initSpeechRecognition();
      _startListening();
    }
    _speakWelcomeMessage();
  }

  Future<void> _configureTTS() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      print("Erro TTS: $msg");
    });
  }

  Future<void> _checkMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    setState(() => _permissionGranted = status.isGranted);

    if (!_permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permissão do microfone é necessária para comandos de voz")),
      );
    }
  }

  Future<void> _initSpeechRecognition() async {
    try {
      // Para qualquer escuta ativa antes de reiniciar
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      try {
        final available = await _speechToText.initialize(
          onStatus: (status) {
            if (status == 'listening') {
              print("Mic ativo");
            }
          },
          onError: (error) {
            if (error.errorMsg !=
                'error_no_match') { // Ignora especificamente este erro
              print("Erro relevante: ${error.errorMsg}");
              _retryListening();
            }
          },
        );
        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Recurso de voz não disponível")),
            );
          }
        }
      } catch (e){
        print("Message: $e");
      }
    } catch (e) {
      print("Erro crítico ao inicializar STT: $e");
    }
  }

  void _startAudioFlow() {
    if (!_permissionGranted) return;

    if (!_isListening) {
      _startContinuousListening();
    }

    // Fala a mensagem completa apenas na primeira vez
    if (!_isSpeaking && _firstTime) {
      _speakWelcomeMessage(fullMessage: true);
      _firstTime = false;
    }
  }

  Future<void> _startContinuousListening() async {
    if (!_permissionGranted || _isListening || !mounted) return;

    try {
      // 1. Pare qualquer escuta anterior
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      // 2. Delay para estabilização
      await Future.delayed(Duration(milliseconds: 300));

      // 3. Inicie a escuta
      final success = await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final command = result.recognizedWords.toLowerCase();
            if (command.contains('escanear')) _navigateToQRView();
            if (command.contains('lista')) _navigateToListView();
          }
        },
        localeId: 'pt-BR',
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: false,
        listenFor: Duration(minutes: 5),
      );

      // 4. Atualize o estado
      if (mounted) {
        setState(() => _isListening = success ?? false);
      }

    } catch (e) {
      print("Falha ao ativar microfone: $e");
      if (mounted) {
        setState(() => _isListening = false);
      }
      _retryListening();
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = {
      'escanear': ['escanear', 'scanear', 'escaneia', 'scanner'],
      'lista': ['lista', 'listar', 'listagem', 'ver lista']
    };

    return variations[command]?.any((variant) => input.contains(variant)) ?? false;
  }

  void _executeCommand(String command, Function() action) {
    print("Executando comando: $command");
    _vibrate(); // Feedback tátil
    action();
  }

  void _retryListening() {
    if (!mounted || _isListening) return;

    Future.delayed(Duration(seconds: 1), () {
      if (mounted && !_isListening) {
        _startContinuousListening();
      }
    });
  }

  int _retryCount = 0;

  Future<void> _speakWelcomeMessage({bool fullMessage = true}) async {
    if (_isSpeaking) return;

    try {
      setState(() => _isSpeaking = true);

      final message = fullMessage
          ? "Obrigado por utilizar o Vision App, um aplicativo dedicado a "
          "promover"
          "o aprendizado sobre o mundo dos insetos de forma inclusiva, para "
          "explorar e descubrir informações sobre diferentes espécies de "
          "insetos, com recursos em áudio, vídeos e através da experiência "
          "com as mãos. Viva uma experiência interessante. Na parte inferior "
          "da tela haverá duas opções de comandos de voz para navegar. Basta "
          "dizer: lista, para acessar a tela com todas as opções de insetos "
          "ou: escanear, para abrir a tela de QR Code e obter informações "
          "detalhadas sobre o inseto escaneado."
          : "Bem-vindo de volta. Diga 'lista' ou 'escanear' para continuar.";

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(message);
    } catch (e) {
      print("Erro ao falar mensagem: $e");
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
      // Reinicia a escuta após terminar de falar
      if (!_isListening) {
        _startContinuousListening();
      }
    }
  }

  void _startListening() {
    if (!_permissionGranted || _isListening) return;

    _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords.toLowerCase().contains('escanear')) {
          _navigateToQRView();
        } else if(result.recognizedWords.toLowerCase().contains('lista')){
          _navigateToListView();
        }
      },
      localeId: 'pt-BR',
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      partialResults: false,
    ).then((value) {
      if (value != null) {
        setState(() => _isListening = value);
      }
    });
  }

  void _navigateToQRView() async {
    await _stopAllAudio();
    _firstTime = false; // Marca que não é mais a primeira vez

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewExample()),
    );

    _handleNavigationReturn();
  }

  void _navigateToListView() async {
    await _stopAllAudio();
    _firstTime = false; // Marca que não é mais a primeira vez

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InsectListScreen()),
    );

    _handleNavigationReturn();
  }
  void _handleNavigationReturn() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _startAudioFlow();
          _speakWelcomeMessage(fullMessage: false); // Mensagem reduzida ao voltar
        }
      });
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _flutterTts.stop();
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isListening = false;
        });
      }
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

  // Função para acionar a vibração personalizada
  void _vibrate() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 200); // vibra por 200 milissegundos
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // Reinicia mais rápido quando o app volta ao foco
        Future.delayed(const Duration(milliseconds: 1), _startAudioFlow);
        break;
      case AppLifecycleState.paused:
        _stopAllAudio();
        break;
      default:
        break;
    }
  }

  void _onItemTapped(int index) {
    _vibrate(); // Aciona a vibração ao tocar no item
    if (index == 0) {
      // Ao tocar em "Escanear", navega para a tela QRViewExample
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRViewExample(),
        ),
      ).then((_) {
        _speakWelcomeMessage(); // Reproduz novamente a mensagem ao retornar
      });
    } else if (index == 1) {
      // Ao tocar em "Lista", atualiza o estado para exibir a tela de lista de insetos
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define as duas telas:
    // 1. Tela de boas-vindas
    // 2. Tela com a lista de insetos
    final List<Widget> _screens = [
      const Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                  'Obrigado por utilizar o Vision App, um aplicativo dedicado a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descubrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante.',
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
      const InsectListScreen(), // Tela de lista de insetos
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
      floatingActionButton: FloatingActionButton(
        onPressed: _startContinuousListening,
        backgroundColor: _isListening ? Colors.green : Colors.red,
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_off,
          color: Colors.white,
        ),
      ),
    );
  }
}
