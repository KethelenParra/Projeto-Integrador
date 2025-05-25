import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:vision_app_3d/screens/insect_list_screen.dart';
import 'package:vision_app_3d/screens/qr_view_exemple.dart';
import 'package:vision_app_3d/service/speechService.dart';
import 'quiz_screen.dart';
import 'package:vibration/vibration.dart'; // Import para vibração personalizada

class InsectDetailsScreen extends StatefulWidget {
  final Insect insect;

  const InsectDetailsScreen({super.key, required this.insect});

  @override
  State<InsectDetailsScreen> createState() => _InsectDetailsScreenState();
}

class _InsectDetailsScreenState extends State<InsectDetailsScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  late VideoPlayerController _videoController;
  final ScrollController _scrollController = ScrollController();
  double _currentScrollPosition = 0;
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isVideoEnabled = true;
  bool _isProcessingVideoCommand = false;
  bool _shouldStartQuizAfterVideo = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.insect.videoPath)
      ..initialize().then((_) {
        setState(() {});
      });

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _configureTTS();
      await _initializeSpeechService();
      await _speakWelcomeMessage();
    } catch (e) {
      print("Erro na inicialização: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao iniciar serviços: ${e.toString()}")),
        );
        // Tenta reiniciar após erro
        await Future.delayed(const Duration(seconds: 1));
        _initializeServices();
      }
    }
  }

  Future<void> _initializeSpeechService() async {
    bool initialized = false;
    int attempts = 0;

    while (!initialized && attempts < 3 && mounted) {
      attempts++;
      initialized = await _speechService.initialize(context: context);

      if (!initialized) {
        print("Tentativa $attempts falhou - esperando para tentar novamente");
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (!initialized && mounted) {
      throw Exception("Não foi possível inicializar o serviço de voz após 3 tentativas");
    }
  }

  Future<void> _configureTTS() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
      if (_isListening) {
        _speechService.stop();
      }
    });

    _flutterTts.setCompletionHandler(() async {
      setState(() => _isSpeaking = false);

      if (_shouldStartQuizAfterVideo && !_isProcessingVideoCommand && !_videoController.value.isPlaying) {
        print("Iniciando quiz após vídeo");
        _navigateToQuizView();
        _shouldStartQuizAfterVideo = false;
      }

      if (_isProcessingVideoCommand || _videoController.value.isPlaying) return;

      if (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        await _safeStartListening();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      if (mounted && !_videoController.value.isPlaying) {
        _startListening();
      }
    });
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (!mounted || _isSpeaking) return;

    final lowerCommand = command.toLowerCase().trim();
    print("Processando comando: $lowerCommand");

    await _speechService.stop();
    setState(() => _isListening = false);

    try {
      if (_matchesCommand(lowerCommand, 'voltar')) {
        _videoController.pause();
        await _executeCommand('Retornando para a lista de insetos', _navigateToListView);
        return;
      }

      if (_matchesCommand(lowerCommand, 'video')) {
        _isProcessingVideoCommand = true;
        await _handleVideoCommand();
        return;
      }

      if (_matchesCommand(lowerCommand, 'parar') && _videoController.value.isPlaying) {
        await _executeCommand("Parando vídeo", () {
          _videoController.pause();
          _isProcessingVideoCommand = false;
        });
        return;
      }

      if (_matchesCommand(lowerCommand, 'perguntas')) {
        if (_isProcessingVideoCommand || _videoController.value.isPlaying) {
          setState(() => _shouldStartQuizAfterVideo = true);
          await _flutterTts.speak("Quando terminar o vídeo, iniciaremos o quiz");
        } else {
          await _executeCommand('Navegando para o quiz', _navigateToQuizView);
        }
        return;
      }

      await _flutterTts.speak("Comando não reconhecido. Tente dizer 'reproduzir vídeo', 'parar vídeo', 'perguntas' ou 'voltar'.");
    } catch (e) {
      print("Erro no comando: $e");
    } finally {
      if (!_isVideoCommandActive && mounted && !_isSpeaking && !_videoController.value.isPlaying) {
        await _restartListening();
      }
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _flutterTts.stop();
      await _speechService.stop();
      setState(() {
        _isSpeaking = false;
        _isListening = false;
      });
      if (_videoController.value.isPlaying) {
        await _videoController.pause();
      }
      print("All audio stopped successfully");
    } catch (e) {
      print("Error stopping audio: $e");
    }
  }

  void _navigateToScreen(Widget screen) async {
    await _stopAllAudio();
    if (!mounted) {
      print("Não pode navegar: widget não montado");
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _navigateToQuizView() async {
    _navigateToScreen(QuizScreen(insectName: widget.insect.name));
    await _speechService.stop();
  }

  void _navigateToListView() async {
    _navigateToScreen(const InsectListScreen());
    await _speechService.stop();
  }

  bool _isVideoCommandActive = false;

  Future<void> _handleVideoCommand() async {
    try {
      if (!_videoController.value.isInitialized) {
        await _flutterTts.speak("O vídeo não está pronto. Tente novamente.");
        print("Vídeo não inicializado");
        return;
      }

      // Parar reconhecimento de voz antes de iniciar o vídeo
      if (_isListening) {
        await _speechService.stop();
        setState(() => _isListening = false);
      }

      setState(() {
        if (_videoController.value.isPlaying) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
      });

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak("Vídeo iniciado.");

      await Future.delayed(const Duration(milliseconds: 500));

      // Listener para detectar término do vídeo
      _videoController.addListener(() {
        if (!_videoController.value.isPlaying && _videoController.value.position >= _videoController.value.duration) {
          print("Vídeo terminou");
          setState(() => _isProcessingVideoCommand = false);
          if (_shouldStartQuizAfterVideo && mounted) {
            _navigateToQuizView();
            _shouldStartQuizAfterVideo = false;
          } else {
            // Falar a mensagem após o vídeo terminar
            _flutterTts.stop();
            _flutterTts.speak("Agora, diga perguntas para iniciar o quiz, ou voltar para voltar à seleção de insetos.");
          }
          // Reativar escuta após o vídeo terminar
          if (mounted && !_isSpeaking) {
            _restartListening();
          }
        }
      });
    } finally {
      _isProcessingVideoCommand = false;
      if (!_videoController.value.isPlaying && mounted && !_isSpeaking) {
        await _restartListening(delayMs: 1200);
      }
    }
  }

  Future<void> _startQuiz() async {
    _vibrate();
    await _flutterTts.speak("Preparando o quiz sobre ${widget.insect.name}");

    if (_videoController.value.isPlaying) {
      _videoController.pause();
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(insectName: widget.insect.name),
        ),
      );
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
      'perguntas': [
        'questionário',
        'perguntas',
        'teste',
        'iniciar quiz',
        'começar quiz',
        'fazer quiz',
        'responder',
        'responder perguntas',
        'testar conhecimento',
      ],
      'video': [
        'habilitar vídeo',
        'habilitar video',
        'ativar vídeo',
        'ativar video',
        'mostrar vídeo',
        'mostrar video',
        'iniciar vídeo',
        'iniciar video',
        'play vídeo',
        'play video',
        'reproduzir vídeo',
        'reproduzir',
        'reproduzir video',
        'dar play no vídeo',
        'dar play no video',
        'tocar vídeo',
        'tocar video',
        'começar vídeo',
        'começar video',
      ],
    };

    return variations[command]?.any((variant) => input.toLowerCase().contains(variant)) ?? false;
  }

  Future<void> _speakWelcomeMessage() async {
    String message = "Indo para ${widget.insect.name}. "
        "Diga 'perguntas' para iniciar o questionário, 'reproduzir video' para controlar o vídeo, ou 'voltar' para retornar.";
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(message);
  }

  Future<void> _safeStartListening({Duration listenFor = const Duration(minutes: 10)}) async {
    try {
      await _startListening(listenFor: listenFor); // Removido o timeout
    } catch (e) {
      if (mounted) _handleListeningError(e);
    }
  }

  Future<void> _startListening({Duration listenFor = const Duration(minutes: 10)}) async {
    if (!mounted || _isSpeaking || _isListening || _videoController.value.isPlaying) {
      print(
          "Não pode iniciar escuta: montado=$mounted, falando=$_isSpeaking, escutando=$_isListening, vídeo rodando=${_videoController.value.isPlaying}");
      return;
    }

    try {
      setState(() => _isListening = true);

      await _speechService.listen(
        onResult: _handleVoiceCommand,
        localeId: 'pt-BR',
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 10),
        // Aumentado para 10 segundos
        onSoundLevelChange: (level) {
          if (level > 0) print("Nível de som: $level");
        },
      );
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      if (mounted) {
        setState(() => _isListening = false);
        await _handleListeningError(e);
      }
    }
  }

  Future<void> _handleListeningError(dynamic error) async {
    print("🛑 Erro no reconhecimento de voz: ${error.toString()}");

    await _speechService.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }

    if (error.toString().contains('error_no_match')) {
      print("🔇 Nenhum comando reconhecido");
      if (mounted) {
        await _flutterTts.awaitSpeakCompletion(true);
        await _flutterTts.speak("Não entendi. Por favor, repita o comando.");
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted && !_isSpeaking) {
          await _restartListening(delayMs: 500);
        }
      }
    } else if (error.toString().contains('error_audio') || error.toString().contains('Error 7')) {
      print("🎤 Erro no áudio (Error 7) - verificando permissões e reinicializando");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Problema no microfone. Verifique as permissões ou tente novamente."),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: openAppSettings,
            ),
          ),
        );

        // Tentar reinicializar o SpeechService
        await _speechService.reset();
        await _initializeSpeechService();

        await Future.delayed(const Duration(seconds: 2));
        if (mounted && !_isSpeaking && !_videoController.value.isPlaying) {
          await _restartListening(delayMs: 1000);
        }
      }
    } else if (error.toString().contains('error_client') || error.toString().contains('error_busy')) {
      print("🔄 Erro no cliente - reinicializando serviços");
      if (mounted) {
        await _initializeServices();
      }
    } else {
      print("⚠️ Erro não tratado - tentando recuperação");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Problema temporário no reconhecimento de voz")),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted && !_isSpeaking && !_videoController.value.isPlaying) {
          await _restartListening(delayMs: 1000);
        }
      }
    }
  }

  Future<void> _checkMicrophonePermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microfone não autorizado'),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  void _toggleVideo() {
    _vibrate();
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
    });
  }

  Future<void> _restartListening({int delayMs = 2000, Duration listenFor = const Duration(minutes: 10)}) async {
    if (!mounted || _isSpeaking || _videoController.value.isPlaying) {
      print(
          "Não pode reiniciar escuta: montado=$mounted, falando=$_isSpeaking, vídeo rodando=${_videoController.value.isPlaying}");
      return;
    }

    try {
      print("Preparando para reiniciar reconhecimento de voz...");

      if (_isListening) {
        await _speechService.stop();
        setState(() => _isListening = false);
      }

      // Verificar permissões antes de reiniciar
      await _checkMicrophonePermissions();

      await Future.delayed(Duration(milliseconds: delayMs));

      if (mounted && !_isSpeaking && !_videoController.value.isPlaying) {
        print("Iniciando nova tentativa de escuta com listenFor=${listenFor.inSeconds}s...");
        await _safeStartListening(listenFor: listenFor);
      }
    } catch (e) {
      print("Erro ao reiniciar escuta: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Problema ao ativar microfone")),
        );

        await Future.delayed(const Duration(seconds: 2)); // Aumentado para 2 segundos
        if (mounted && !_videoController.value.isPlaying) {
          _restartListening(delayMs: 1000, listenFor: listenFor);
        }
      }
    }
  }

  Future<void> _executeCommand(String command, Function() action) async {
    _vibrate();
    await _flutterTts.speak(command);
    await Future.delayed(const Duration(milliseconds: 800));
    action();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechService.stop();
    _videoController.pause();
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Função para acionar a vibração personalizada
  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200); // vibração de 200ms
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _currentScrollPosition += 30;
      _scrollController.animateTo(
        _currentScrollPosition,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: Text(
          widget.insect.name,
          style: const TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate(); // Vibração ao clicar no botão de voltar
            _videoController.pause(); // Pausa o vídeo ao voltar
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do Inseto
            Text(
              widget.insect.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Vídeo
            if (_videoController.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              )
            else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            // Botão Pause/Play com vibração para ambas ações
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_videoController.value.isPlaying) {
                      _vibrate(); // Vibração ao pausar o vídeo
                      _videoController.pause();
                    } else {
                      _vibrate(); // Vibração ao dar play
                      _videoController.play();
                    }
                  });
                },
                child: Text(
                  _videoController.value.isPlaying ? 'Pause' : 'Play',
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Descrição com fundo fixo e animação
            Container(
              height: 300,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView(
                  controller: _scrollController,
                  children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          widget.insect.description,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          speed: const Duration(milliseconds: 50),
                          cursor: '|',
                        ),
                      ],
                      isRepeatingAnimation: false,
                      onNextBeforePause: (index, isLast) {
                        _scrollToBottom();
                      },
                      onFinished: () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _vibrate(); // Vibração ao clicar no botão "Fazer Quiz"
                  if (_videoController.value.isPlaying) {
                    _videoController.pause();
                  }
                  _videoController.seekTo(Duration.zero);
                  setState(() {
                    _currentScrollPosition = 0;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(insectName: widget.insect.name),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB08A),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Fazer Quiz',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
