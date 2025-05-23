import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:vision_app_3d/service/speechService.dart';
import 'insect_details_screen.dart';
import 'home_page.dart';
import 'insect.dart';

class InsectListScreen extends StatefulWidget {
  const InsectListScreen({super.key});

  @override
  State<InsectListScreen> createState() => _InsectListScreenState();
}

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print("Inicializando InsectListScreen...");
      await _configureTts();
      await _checkPermissions();
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        await _initializeSpeechService();

        await _speakInstruction();

        if (mounted) {
          await _flutterTts.awaitSpeakCompletion(true);

          await Future.delayed(const Duration(milliseconds: 500));

          await _startListeningWithRetry();
        }
      }
    } catch (e) {
      print("Erro na inicialização: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao iniciar: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _configureTts() async {
    try {
      print("Configurando TTS...");
      // Verificar idiomas disponíveis
      List<dynamic> languages = await _flutterTts.getLanguages;
      print("Idiomas disponíveis: $languages");
      String targetLanguage = 'pt-BR';

      await _flutterTts.setLanguage(targetLanguage);
      await _flutterTts.setSpeechRate(0.6);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        print("TTS iniciado");
        setState(() => _isSpeaking = true);
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
        print("TTS completado");
        setState(() => _isSpeaking = false);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted && !_isListening && !_isSpeaking) {
          print("Iniciando reconhecimento pós-TTS");
          await _startListeningWithRetry();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        print("Erro no TTS: $msg");
        setState(() => _isSpeaking = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro no áudio: $msg")),
          );
          _startListeningWithRetry();
        }
      });

      print("TTS configurado com sucesso");
    } catch (e) {
      print("Erro ao configurar TTS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao configurar áudio: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _initializeSpeechService() async {
    bool initialized = false;
    int attempts = 0;

    while (!initialized && attempts < 3 && mounted) {
      attempts++;
      print("Tentativa $attempts de inicializar SpeechService...");
      initialized = await _speechService.initialize(context: context);

      if (!initialized) {
        print("Tentativa $attempts falhou: ${_speechService.lastError}");
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }

    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível iniciar o reconhecimento de voz")),
      );
      // Continuar com TTS mesmo se SpeechService falhar
      await _speakInstruction();
    }
  }

  @override
  void dispose() {
    print("Disposing InsectListScreen...");
    _stopAllAudio();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    if (_isSpeaking || !mounted) {
      print("Não pode falar: _isSpeaking=$_isSpeaking, mounted=$mounted");
      return;
    }

    try {
      print("Falando instrução...");
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(
        "Fale o nome de um inseto para ver mais informações. Diga claramente: Escorpião, Borboleta, Barbeiro, Abelha ou Aranha. "
        "Diga Voltar para retornar a tela inicial",
      );
    } catch (e) {
      print("Erro ao falar instrução: $e");
      setState(() => _isSpeaking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao falar instrução: ${e.toString()}")),
        );
      }
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

  Future<void> _startListeningWithRetry({int attempt = 0}) async {
    if (attempt >= 3 || !mounted) {
      print("Máximo de tentativas atingido ou não montado");
      return;
    }

    try {
      await _startListening();
      _retryCount = 0;
    } catch (e) {
      print("Falha na tentativa ${attempt + 1}: $e");
      await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      if (mounted) {
        await _startListeningWithRetry(attempt: attempt + 1);
      }
    }
  }

  Future<void> _startListening() async {
    if (!mounted || _isSpeaking || _isListening) {
      print("Não pode iniciar escuta: mounted=$mounted, _isSpeaking=$_isSpeaking, _isListening=$_isListening");
      return;
    }

    try {
      print("Iniciando escuta...");
      setState(() => _isListening = true);

      await _speechService.listen(
        onResult: (command) {
          print("Resultado recebido: '$command'");
          if (command.trim().isNotEmpty) {
            _handleVoiceCommand(command);
          } else {
            print("Comando vazio recebido, reiniciando escuta");
            _flutterTts.speak("Nenhum comando detectado. Diga o nome de um inseto ou voltar.").then((_) {
              if (mounted && !_isSpeaking) {
                _startListening();
              }
            });
            _vibrate();
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 10),
        onSoundLevelChange: (level) {
          if (level > 0) print("Nível de som: $level");
        },
      );

      print("Escuta ativada com sucesso");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microfone ativo. Fale seu comando.")),
        );
      }
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      setState(() => _isListening = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro no microfone: ${e.toString()}")),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!_isSpeaking) {
          _startListening();
        }
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

  void _vibrate({int duration = 100}) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (!mounted) return;

    if (_isSpeaking) {
      print("Interrompendo TTS para processar comando...");
      await _flutterTts.stop(); // ou o nome do seu serviço TTS
      _isSpeaking = false;
    }

    print("Processando comando: '$command'");
    await _speechService.stop();
    setState(() => _isListening = false);

    try {
      final lowerCaseCommand = command.toLowerCase().trim();

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
    } catch (e) {
      print("Erro ao processar comando: $e");
    } finally {
      if (mounted && !_isSpeaking && !_isListening) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _startListening();
      }
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
    _vibrate();
    await _flutterTts.speak(command);
    await Future.delayed(const Duration(milliseconds: 800));
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

  Future<void> _handleNavigationReturn() async {
    if (mounted) {
      print("Retornando de navegação, reinicializando áudio...");
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        await _configureTts();
        await _speakInstruction();
        await _startListeningWithRetry();
      }
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
      print("All audio stopped successfully");
    } catch (e) {
      print("Erro ao parar áudio: $e");
      setState(() {
        _isListening = false;
        _isSpeaking = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Ciclo de vida alterado: $state");
    switch (state) {
      case AppLifecycleState.resumed:
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isSpeaking) {
            _initializeApp();
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
                      _vibrate();
                      _flutterTts.stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InsectDetailsScreen(insect: insect),
                        ),
                      ).then((_) {
                        if (mounted) {
                          _handleNavigationReturn();
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
