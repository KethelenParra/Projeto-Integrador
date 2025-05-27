import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vision_app_3d/service/speech_service.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart';
import 'insect_details_screen.dart';
import 'home_page.dart';
import 'insect.dart';

class InsectListScreen extends StatefulWidget {
  const InsectListScreen({super.key});

  @override
  State<InsectListScreen> createState() => _InsectListScreenState();
}

class _InsectListScreenState extends State<InsectListScreen> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();
  final VibrationService _vibrationService = VibrationService();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _canStartListeningAfterTTS = false;
  bool _servicesInitialized = false;
  bool _navigatingToDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("InsectListScreen: initState");
    _servicesInitialized = false; // Força reinicialização ao entrar na tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true && !_servicesInitialized) {
        print("InsectListScreen: Iniciando _initializeApp via postFrameCallback");
        _initializeApp();
      }
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted || _servicesInitialized) {
      print("InsectListScreen: _initializeApp bloqueado: mounted=$mounted, _servicesInitialized=$_servicesInitialized");
      return;
    }
    print("InsectListScreen: _initializeApp - Iniciando serviços...");
    _servicesInitialized = true;
    _canStartListeningAfterTTS = false;
    _navigatingToDetails = false;

    try {
      await _checkPermissions();
      await _configureTts();
      await _initializeSpeechService();

      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _canStartListeningAfterTTS = true;
        await _speakInstruction();
      }
    } catch (e) {
      print("InsectListScreen: Erro na inicialização: $e");
      _servicesInitialized = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao iniciar: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _configureTts() async {
    print("InsectListScreen: Configurando TTS...");
    await _ttsService.initialize(
      language: 'pt-BR',
      speechRate: 0.6,
      volume: 1.0,
      onStart: () {
        if (mounted) setState(() => _isSpeaking = true);
        print("InsectListScreen: TTS onStart");
      },
      onComplete: () async {
        if (!mounted) return;
        setState(() => _isSpeaking = false);
        print(
            "InsectListScreen: TTS onComplete. _canStartListeningAfterTTS: $_canStartListeningAfterTTS, _navigatingToDetails: $_navigatingToDetails");

        if (_navigatingToDetails) {
          print("InsectListScreen: TTS onComplete - Navegando, não iniciando escuta.");
          return;
        }

        if (_canStartListeningAfterTTS && _speechService.isInitialized) {
          _canStartListeningAfterTTS = false;
          if (mounted && !_isListening && !_isSpeaking) {
            print("InsectListScreen: TTS onComplete - Iniciando escuta.");
            await _startListeningWithRetry();
          }
        } else {
          print("InsectListScreen: TTS onComplete - Condições para escuta não atendidas. "
              "speechService.isInitialized: ${_speechService.isInitialized}");
        }
      },
      onError: (msg) {
        if (mounted) setState(() => _isSpeaking = false);
        print("InsectListScreen: Erro no TTS: $msg");
        _canStartListeningAfterTTS = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro no áudio: $msg")),
          );
        }
      },
    );
    print("InsectListScreen: TTS configurado com sucesso");
  }

  Future<void> _initializeSpeechService() async {
    bool initialized = false;
    int attempts = 0;
    const maxAttempts = 5;

    while (!initialized && attempts < maxAttempts && mounted) {
      attempts++;
      print("InsectListScreen: Tentativa $attempts de inicializar SpeechService...");
      initialized = await _speechService.initialize(context: context);
      if (!initialized) {
        print("InsectListScreen: Tentativa $attempts falhou: ${_speechService.lastError}");
        if (attempts < maxAttempts) await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    if (!initialized && mounted) {
      print("InsectListScreen: SpeechService não inicializado após $maxAttempts tentativas.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível iniciar o reconhecimento de voz.")),
      );
    } else if (initialized) {
      print("InsectListScreen: SpeechService inicializado com sucesso.");
    }
  }

  Future<void> _speakInstruction() async {
    if (_isSpeaking || !mounted) {
      print("InsectListScreen: Não pode falar instrução: _isSpeaking=$_isSpeaking, mounted=$mounted");
      return;
    }
    print("InsectListScreen: Falando instrução...");
    await _ttsService.speak(
      "Fale o nome de um inseto para ver mais informações. Diga claramente: Escorpião, Borboleta, Barbeiro, Abelha ou Aranha. "
      "Diga Voltar para retornar a tela inicial",
    );
    print("InsectListScreen: Instrução enviada ao TTS.");
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissão de microfone necessária'),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _startListeningWithRetry({int attempt = 0, int maxRetries = 2}) async {
    if (!mounted || _isListening || _isSpeaking || _navigatingToDetails) {
      print("InsectListScreen: _startListeningWithRetry bloqueado: "
          "mounted=$mounted, _isListening=$_isListening, _isSpeaking=$_isSpeaking, _navigatingToDetails=$_navigatingToDetails");
      return;
    }
    if (attempt >= maxRetries) {
      print("InsectListScreen: Máximo de tentativas de escuta atingido.");
      _canStartListeningAfterTTS = true;
      await _ttsService.speak("Não foi possível ativar o microfone após várias tentativas.");
      return;
    }

    try {
      await _startListening();
    } catch (e) {
      print("InsectListScreen: Falha na tentativa de escuta ${attempt + 1}: $e");
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      if (mounted && !_isListening && !_isSpeaking && !_navigatingToDetails) {
        await _startListeningWithRetry(attempt: attempt + 1, maxRetries: maxRetries);
      }
    }
  }

  Future<void> _startListening() async {
    if (!mounted || _isSpeaking || _isListening || !_speechService.isInitialized || _navigatingToDetails) {
      print("InsectListScreen: Não pode iniciar escuta: "
          "mounted=$mounted, _isSpeaking=$_isSpeaking, _isListening=$_isListening, "
          "speechInit=${_speechService.isInitialized}, _navigatingToDetails=$_navigatingToDetails");
      if (mounted && !_speechService.isInitialized && !_isSpeaking && !_navigatingToDetails) {
        _canStartListeningAfterTTS = true;
        await _ttsService.speak("Serviço de voz não está pronto.");
      }
      return;
    }

    print("InsectListScreen: Iniciando escuta...");
    if (mounted) setState(() => _isListening = true);
    try {
      await _speechService.listen(
        onResult: (command) {
          if (!mounted) return;
          print("InsectListScreen: Resultado recebido: '$command'");
          if (command.trim().isNotEmpty) {
            _handleVoiceCommand(command);
          } else {
            print("InsectListScreen: Comando vazio recebido.");
            _canStartListeningAfterTTS = true;
            _ttsService.speak("Nenhum comando detectado. Diga o nome de um inseto ou voltar.");
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 10),
        autoRestartOnNoMatch: true,
        onSoundLevelChange: (level) {
// Opcional: Log apenas para níveis significativos
// if (level > 0) print("Nível de som: $level");
        },
      );
      print("InsectListScreen: Escuta ativada com sucesso.");
    } catch (e) {
      print("InsectListScreen: Erro ao iniciar escuta: $e");
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro no microfone: ${e.toString()}")),
        );
        _canStartListeningAfterTTS = true;
        await _restartListening(delayMs: 1500);
      }
    }
  }

  Future<void> _restartListening({int delayMs = 1000}) async {
    if (!mounted || _navigatingToDetails) {
      print("InsectListScreen: _restartListening bloqueado: mounted=$mounted, _navigatingToDetails=$_navigatingToDetails");
      return;
    }
    print("InsectListScreen: Tentando reiniciar escuta em $delayMs ms...");

    if (_isListening) {
      await _speechService.stop();
      if (mounted) setState(() => _isListening = false);
    }
    if (_isSpeaking) {
      print("InsectListScreen: Não pode reiniciar escuta: TTS falando.");
      _canStartListeningAfterTTS = false;
      return;
    }
    await Future.delayed(Duration(milliseconds: delayMs));
    if (mounted && !_isSpeaking && !_isListening && !_navigatingToDetails) {
      print("InsectListScreen: Reiniciando escuta agora...");
      await _startListeningWithRetry();
    } else {
      print("InsectListScreen: Condições para reiniciar escuta não atendidas após delay.");
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (!mounted) return;

    await _speechService.stop();
    if (mounted) setState(() => _isListening = false);
    await _ttsService.stop();
    if (mounted) setState(() => _isSpeaking = false);

    print("InsectListScreen: Processando comando: '$command'");

    try {
      final lowerCaseCommand = command.toLowerCase().trim();

      if (_matchesCommand(lowerCaseCommand, 'voltar')) {
        _canStartListeningAfterTTS = false;
        await _executeCommand('Voltando para a tela inicial', _navigateToHome);
        return;
      }

      final insectUrl = insectData.keys.firstWhere(
        (url) => _matchesCommand(lowerCaseCommand, insectData[url]?.name.toLowerCase() ?? ''),
        orElse: () => '',
      );

      if (insectUrl.isNotEmpty && insectData[insectUrl] != null) {
        if (mounted) setState(() => _navigatingToDetails = true);
        _canStartListeningAfterTTS = false;
        await _executeCommand(insectData[insectUrl]!.name, () => _navigateToInsectDetail(insectData[insectUrl]!));
      } else {
        _canStartListeningAfterTTS = true;
        await _ttsService.speak("Comando não reconhecido. Tente novamente.");
      }
    } catch (e) {
      print("InsectListScreen: Erro ao processar comando: $e");
      _canStartListeningAfterTTS = true;
      await _ttsService.speak("Ocorreu um erro ao processar o comando.");
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
        'escorpiaum'
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
        'borboletah'
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
        'barbeirao'
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
        'abeilha'
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
        'aranah'
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
        'voltarre'
      },
    };

    String normalize(String text) {
      return removeDiacritics(text).toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final normalizedInput = normalize(input);
    final normalizedCommand = normalize(command);

    final commandVariations = variations[normalizedCommand];
    if (commandVariations == null) return false;

    final matched = commandVariations.any((variant) => normalizedInput.contains(normalize(variant)));
    print("InsectListScreen: Verificando comando '$command' vs input '$input': matched=$matched");
    return matched;
  }

  Future<void> _executeCommand(String ttsResponse, Function() action) async {
    _vibrationService.vibrate();
    await _ttsService.speak(ttsResponse);
    if (mounted) action();
  }

  Future<void> _navigateToInsectDetail(Insect insect) async {
    print("InsectListScreen: Navegando para detalhes de ${insect.name}...");
    await _stopAllAudio();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => InsectDetailsScreen(insect: insect)),
      ).then((_) {
        if (mounted) {
          print("InsectListScreen: Retornou de InsectDetailsScreen. Reinicializando.");
          _navigatingToDetails = false;
          _servicesInitialized = false;
          _initializeApp();
        }
      });
    }
  }

  void _navigateToHome() async {
    print("InsectListScreen: Navegando para HomePage...");
    await _stopAllAudio();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  Future<void> _stopAllAudio() async {
    print("InsectListScreen: Parando áudio e escuta...");
    _canStartListeningAfterTTS = false;
    await _ttsService.stop();
    await _speechService.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isSpeaking = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("InsectListScreen: Ciclo de vida alterado: $state");
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_servicesInitialized && ModalRoute.of(context)?.isCurrent == true) {
          print("InsectListScreen: App resumed, inicializando serviços.");
          _initializeApp();
        } else if (mounted && _servicesInitialized && !_isSpeaking && !_isListening && !_navigatingToDetails) {
          print("InsectListScreen: App resumed, reiniciando escuta.");
          _canStartListeningAfterTTS = true;
          _restartListening(delayMs: 500);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print("InsectListScreen: App pausado/inativo, parando áudio.");
        _stopAllAudio();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    print("InsectListScreen: Disposing...");
    WidgetsBinding.instance.removeObserver(this);
    _stopAllAudio();
    _servicesInitialized = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text(
          'Lista de Insetos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrationService.vibrate();
            _navigateToHome();
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
                final String insectKey = insectData.keys.elementAt(index);
                final Insect insect = insectData[insectKey]!;
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
                      _vibrationService.vibrate();
                      if (mounted) setState(() => _navigatingToDetails = true);
                      _navigateToInsectDetail(insect);
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
