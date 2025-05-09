import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';
import 'package:vision_app_3d/screens/quiz_screen.dart';
import 'package:vision_app_3d/service/speechService.dart';
import 'insect_details_screen.dart';
import 'home_page.dart';
import 'insect.dart';

class InsectListScreen extends StatefulWidget {
  const InsectListScreen({super.key});

  @override
  State<InsectListScreen> createState() => _InsectListScreenState();
}

//TODO Corrigir a ativação da fala
class _InsectListScreenState extends State<InsectListScreen> with WidgetsBindingObserver {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isSpeaking = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 500), ()
    {
      if (mounted) {
        _configureTts().then((_) {
          _checkPermissions().then((_) => _initializeSpeech());
        });
      }
    });
  }

  @override
  void dispose() {
    _stopAllAudio();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _configureTts() async {
    _flutterTts.setStartHandler(() {
      print("TTS iniciado - desligando reconhecimento");
      setState(() => _isSpeaking = true);
      // Delay maior antes de parar o reconhecimento
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _isListening) {
          _speechService.stop().then((_) {
            print("Reconhecimento parado com sucesso");
          }).catchError((e) {
            print("Erro ao parar reconhecimento: $e");
          });
        }
      });
    });

    _flutterTts.setCompletionHandler(() async {
      print("TTS completado - preparando para ativar reconhecimento");
      setState(() => _isSpeaking = false);
      // Delay maior e verificação de estado
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_isListening && !_isSpeaking) {
        print("Iniciando reconhecimento pós-TTS");
        await _startListeningWithRetry();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      print("Erro no TTS: $msg");
      setState(() => _isSpeaking = false);
      if (mounted) _startListeningWithRetry();
    });

    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _startListeningWithRetry({int attempt = 0}) async {
    if (attempt >= 3 || !mounted) return;

    try {
      await _startListening();
      _retryCount = 0; // Resetar contador se bem-sucedido
    } catch (e) {
      print("Falha na tentativa ${attempt + 1}: $e");
      await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      if (mounted) {
        await _startListeningWithRetry(attempt: attempt + 1);
      }
    }
  }

  Future<void> _initializeSpeech() async {
    if (!mounted) return;

    bool initialized = await _speechService.initialize(context: context);
    if (initialized) {
      if (!_isSpeaking) {
        await _speakInstruction();
        await _startListeningWithRetry();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falha ao inicializar reconhecimento de voz")),
      );
    }
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de microfone necessária'),
            action: SnackBarAction(label: 'Configurações', onPressed: openAppSettings),
          ),
        );
      }
    }
  }

  Future<void> _startListening() async {
    if (_isSpeaking || !mounted) {
      print("Não iniciar escuta - TTS ativo ou tela não montada");
      return;
    }

    try {
      print("Preparando ambiente para escuta...");

      // Verificar permissões novamente
      if (!(await Permission.microphone.isGranted)) {
        await _checkPermissions();
        return;
      }

      // Reinicializar se necessário
      if (!_speechService.isInitialized) {
        print("Reinicializando SpeechService...");
        await _speechService.initialize(context: context);
      }

      print("Parando qualquer escuta anterior...");
      await _speechService.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      print("Iniciando nova sessão de escuta...");
      await _speechService.listen(
        onResult: (command) {
          if (command
              .trim()
              .isNotEmpty) {
            print("Comando recebido: $command");
            _handleVoiceCommand(command);
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 15),
        // Tempo aumentado
        pauseFor: const Duration(seconds: 5),
        // Pausa aumentada
        onSoundLevelChange: (level) {
          if (level > 0) print("Nível de som detectado: $level dB");
        },
      );

      setState(() => _isListening = true);
      print("Escuta ativada com sucesso");
    } catch (e) {
      print("Falha crítica ao iniciar escuta: $e");
      if (mounted) setState(() => _isListening = false);
      await _handleListeningError(e);
    }
  }

  Future<void> _handleListeningError(dynamic error) async {
    print("Tratando erro: ${error.toString()}");

    if (error.toString().contains('error_no_match')) {
      if (_retryCount < 2) {
        _retryCount++;
        print("Tentativa $_retryCount - Nenhum comando reconhecido");
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && !_isSpeaking) {
          await _startListening();
        }
      } else {
        print("Máximo de tentativas alcançado");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Não consegui te ouvir. Tente novamente mais tarde.")),
          );
        }
        _retryCount = 0;
      }
    } else {
      print("Erro não tratado: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro no microfone: ${error.toString()}")),
        );
      }
    }
  }

  Future<void> _handleUnrecognizedCommand() async {
    await _flutterTts.speak("Comando não reconhecido. Tente novamente.");
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted && !_isSpeaking) {
      await _startListening();
    }
  }

  Future<void> _speakInstruction() async {
    try {
      await _flutterTts.speak(
        "Fale o nome de um inseto para ver mais informações. Diga claramente: Escorpião, Borboleta, Barbeiro, Abelha ou Aranha. "
            "Diga Voltar para retornar a tela inicial",
      );
    } catch (e) {
      print("Erro no TTS: $e");
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _vibrate({bool isNavigation = false}) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: isNavigation ? 300 : 200);
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (_isSpeaking || !mounted) return;

    final lowerCaseCommand = command.toLowerCase().trim();
    print("Processando comando: $lowerCaseCommand");

    await _stopAllAudio();
    await Future.delayed(const Duration(milliseconds: 100));

    if (_matchesCommand(lowerCaseCommand, 'voltar')) {
      await _executeCommand('Voltar', _navigateBackToHome);
      return;
    }

    final insectUrl = insectData.keys.firstWhere(
          (url) => _matchesCommand(lowerCaseCommand, insectData[url]?.name.toLowerCase() ?? ''),
      orElse: () => '',
    );

    if (insectUrl.isNotEmpty) {
      final insect = insectData[insectUrl];
      await _executeCommand(insect!.name, () => _navigateToInsectDetail(insectUrl));
    } else {
      await _handleUnrecognizedCommand();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isSpeaking) {
            _initializeSpeech();
          }
        });
        break;
      case AppLifecycleState.paused:
        _stopAllAudio();
        break;
      default:
        break;
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = {
      'escorpiao': {
        'escorpião',
        'escorpiao',
        'scorpiao',
        'escorpio',
        'scorpio',
        'escorpia',
        'escorpiom',
        'escorpion',
        'skorpio',
        'escorp',
        'eskorpião',
        'escorpeão',
        'escorpiaum',
      },
      'borboleta': {
        'borboleta',
        'borboletas',
        'borboletta',
        'butterfly',
        'borboletinha',
        'borbo',
        'borboleto',
        'borbole',
        'borbol',
        'borbolete',
        'borboletah',
      },
      'barbeiro': {
        'barbeiro',
        'barbero',
        'barbeiros',
        'triatomine',
        'kissing bug',
        'barberio',
        'barbeir',
        'barbei',
        'barber',
        'barbe',
        'barbeyro',
        'barbeiru',
        'barbeirao',
      },
      'abelha': {
        'abelha',
        'abelhas',
        'bee',
        'bees',
        'abela',
        'abelia',
        'abelh',
        'abel',
        'abeha',
        'abeia',
        'abehla',
        'abelya',
        'abeilha',
      },
      'aranha': {
        'aranha',
        'aranhas',
        'spider',
        'spiders',
        'arania',
        'arana',
        'aranh',
        'aran',
        'aranaa',
        'aranhaa',
        'aranya',
        'araniha',
        'aranah',
      },
      'voltar': {
        'voltar',
        'volta',
        'retornar',
        'regressar',
        'back',
        'return',
        'volt',
        'volte',
        'retorna',
        'regressa',
        'vultar',
        'voltah',
        'voltaar',
        'voutar',
        'voltarr',
        'volter',
        'voltare',
        'vouta',
        'voltara',
        'voltas',
        'voltir',
        'voltarre',
      },
    };

    // Função para normalizar texto (remover acentos, espaços e deixar em minúsculo)
    String normalize(String text) {
      return removeDiacritics(text).toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final normalizedInput = normalize(input);
    final normalizedCommand = normalize(command);

    final matched = variations[normalizedCommand]?.any((variant) => normalizedInput.contains(normalize(variant))) ?? false;

    print("Verificando comando '$command': input='$input', matched=$matched");
    return matched;
  }

  Future<void> _executeCommand(String command, Function() action) async {
    await _flutterTts.speak("Executando $command");
    _vibrate(isNavigation: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    action();
  }

  Future<void> _navigateToInsectDetail(String insectUrl) async {
    final insect = insectData[insectUrl];
    if (insect != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InsectDetailsScreen(insect: insect),
        ),
      );
      _handleNavigationReturn();
    } else {
      await _flutterTts.speak("Inseto não encontrado. Tente novamente.");
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!_isSpeaking && mounted) {
        _startListening();
      }
    }
  }

  void _navigateBackToHome() {
    _speechService.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _handleNavigationReturn() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _initializeSpeech();
        }
      });
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _flutterTts.stop();
      await _speechService.stop();
      setState(() {
        _isListening = false;
        _isSpeaking = false;
      });
    } catch (e) {
      print("Erro ao parar áudio: $e");
      setState(() {
        _isListening = false;
        _isSpeaking = false;
      });
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate();
            _flutterTts.stop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Fale ou toque em um inseto para ver mais informações.",
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
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      insect.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onTap: () {
                      _vibrate(isNavigation: true);
                      _flutterTts.stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InsectDetailsScreen(insect: insect),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _initializeSpeech();
                        }
                      });
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