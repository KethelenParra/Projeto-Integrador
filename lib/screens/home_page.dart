import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVoiceFeatures();
  }

  Future<void> _initAudioServices() async{
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();

    await _configureTTS();
    await _checkPermissions();
    await _initSpeechRecognition();

    _startAudioFlow();
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    setState(() => _permissionGranted = micStatus.isGranted);

    if (!_permissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permissão do microfone é necessária")),
      );
    }
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
    _flutterTts.setCompletionHandler(() {
      // Reinicia a escuta quando termina de falar
      if (_permissionGranted) {
        _startListening();
      }
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
      final available = await _speechToText.initialize(
        onStatus: (status) => print("Status STT: $status"),
        onError: (error) {
          print("Erro STT: $error");
          _retryListening();
        },
      );

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reconhecimento de voz não disponível")),
        );
      }
    } catch (e) {
      print("Erro ao inicializar STT: $e");
    }
  }

  void _startAudioFlow() {
    if (_permissionGranted) {
      _startContinuousListening();
      _speakWelcomeMessage();
    }
  }

  void _startContinuousListening() {
    if (!_permissionGranted || _isListening) return;

    _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords.toLowerCase().contains('iniciar')) {
          _navigateToQRView();
        }
      },
      localeId: 'pt-BR',
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      partialResults: false,
    ).then((value) {
      if (mounted) {
        setState(() => _isListening = value ?? false);
      }
    }).catchError((error) {
      print("Erro ao escutar: $error");
      _retryListening();
    });
  }

  void _retryListening() {
    Future.delayed(const Duration(seconds: 1), _startContinuousListening);
  }


  Future<void> _speakWelcomeMessage() async {
    if (_isSpeaking) return;

    await _flutterTts.speak(
      "Obrigado por utilizar o Vision App, um aplicativo dedicado a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descubrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante. Na parte inferior da tela haverá duas opções de comandos de voz para navegar. Basta dizer: lista, para acessar a tela com todas as opções de insetos ou: escanear, para abrir a tela de QR Code e obter informações detalhadas sobre o inseto escaneado.",
    );
  }

  void _startListening() {
    if (!_permissionGranted || _isListening) return;

    _speechToText.listen(
      onResult: (result) {
        if (result.recognizedWords.toLowerCase().contains('iniciar')) {
          _navigateToQRView();
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

  void _navigateToQRView() {
    _stopAllAudio();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewExample()),
    ).then((_) {
      if (mounted) {
        _startAudioFlow();
      }
    });
  }

  void _stopAllAudio() {
    _flutterTts.stop();
    _speechToText.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isListening = false;
      });
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
    switch (state) {
      case AppLifecycleState.resumed:
        _startAudioFlow();
        break;
      case AppLifecycleState.paused:
        _stopAllAudio();
        break;
      default:
        break;
    }
  }

  void _onItemTapped(int index) {
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
    // 1. Tela de boas-vindas (sem o botão "Iniciar")
    // 2. Tela com a lista de insetos
    final List<Widget> _screens = [
      Center(
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
                  'Obrigado por utilizar o Vision App, um aplicativo dedicado a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descubrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
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
    );
  }
}
