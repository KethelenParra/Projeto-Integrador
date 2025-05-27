import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:video_player/video_player.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:vision_app_3d/service/speech_service.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart';
import 'quiz_screen.dart';

class InsectDetailsScreen extends StatefulWidget {
  final Insect insect;

  const InsectDetailsScreen({super.key, required this.insect});

  @override
  State<InsectDetailsScreen> createState() => _InsectDetailsScreenState();
}

class _InsectDetailsScreenState extends State<InsectDetailsScreen> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService();
  late VideoPlayerController _videoController;
  final ScrollController _scrollController = ScrollController();
  final SpeechService _speechService = SpeechService();
  final VibrationService _vibrationService = VibrationService();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessingVideoCommand = false;
  bool _shouldStartQuizAfterVideo = false;
  bool _servicesInitialized = false;
  bool _videoPlayerInitialized = false;
  bool _canStartListeningAfterTTS = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("InsectDetailsScreen: initState for ${widget.insect.name}");

    _videoController = VideoPlayerController.asset(widget.insect.videoPath)
      ..initialize().then((_) {
        if (!mounted) return;
        print("InsectDetailsScreen: Video Player initialized for ${widget.insect.videoPath}");
        _videoPlayerInitialized = true;
        setState(() {});
        _videoController.addListener(_videoPlaybackListener);
      }).catchError((error) {
        print("InsectDetailsScreen: Erro ao inicializar VideoPlayer: $error");
        _videoPlayerInitialized = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao carregar vídeo: ${error.toString()}")),
          );
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_servicesInitialized) {
        print("InsectDetailsScreen: Iniciando _initializeServices via postFrameCallback");
        _initializeServices();
      }
    });
  }

  void _videoPlaybackListener() {
    if (!mounted || !_videoPlayerInitialized || !_videoController.value.isInitialized) return;

    final bool isFinished =
        _videoController.value.position >= _videoController.value.duration && _videoController.value.duration > Duration.zero;

    if (!_videoController.value.isPlaying && isFinished) {
      print("InsectDetailsScreen: Vídeo terminou.");
      _canStartListeningAfterTTS = true;

      if (_shouldStartQuizAfterVideo) {
        print("InsectDetailsScreen: Iniciando quiz após vídeo.");
        _navigateToQuizView();
        _shouldStartQuizAfterVideo = false;
      } else {
        print("InsectDetailsScreen: Falando instruções pós-vídeo.");
        _ttsService.stop().then((_) {
          if (mounted) {
            _ttsService.speak("O vídeo terminou. Diga 'perguntas' para o quiz, ou 'voltar'.");
          }
        });
      }
    }
  }

  Future<void> _initializeServices() async {
    if (_servicesInitialized || !mounted) {
      print("InsectDetailsScreen: _initializeServices bloqueado: _servicesInitialized=$_servicesInitialized, mounted=$mounted");
      return;
    }
    print("InsectDetailsScreen: Iniciando todos os serviços...");
    _servicesInitialized = true;
    _canStartListeningAfterTTS = false;

    try {
      await _checkMicrophonePermissions();
      await _configureTts();
      await _initializeSpeechService();

      if (mounted) {
        await _speakWelcomeMessage();
      }
    } catch (e) {
      print("InsectDetailsScreen: Erro na inicialização geral dos serviços: $e");
      _servicesInitialized = false;
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
    const maxAttempts = 5;

    while (!initialized && attempts < maxAttempts && mounted) {
      attempts++;
      print("InsectDetailsScreen: Tentativa $attempts de inicializar SpeechService...");
      initialized = await _speechService.initialize(context: context);
      if (!initialized) {
        print("InsectDetailsScreen: Tentativa $attempts falhou: ${_speechService.lastError}");
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    if (!initialized && mounted) {
      print("InsectDetailsScreen: SpeechService não inicializado após $maxAttempts tentativas.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível iniciar o reconhecimento de voz.")),
      );
    } else if (initialized) {
      print("InsectDetailsScreen: SpeechService inicializado com sucesso.");
    }
  }

  Future<void> _configureTts() async {
    print("InsectDetailsScreen: Configurando TTS...");
    await _ttsService.initialize(
      language: "pt-BR",
      speechRate: 0.5,
      volume: 1.0,
      onStart: () {
        print("InsectDetailsScreen: TTS onStart");
        if (mounted) {
          setState(() => _isSpeaking = true);
          if (_isListening) {
            _speechService.stop();
            setState(() => _isListening = false);
          }
        }
      },
      onComplete: () async {
        if (!mounted) return;
        print("InsectDetailsScreen: TTS onComplete. _canStartListeningAfterTTS: $_canStartListeningAfterTTS");
        setState(() => _isSpeaking = false);

        if (_isProcessingVideoCommand ||
            (_videoPlayerInitialized && _videoController.value.isInitialized && _videoController.value.isPlaying)) {
          print("InsectDetailsScreen: TTS onComplete - Vídeo ou comando ativo. Não iniciando escuta.");
          _canStartListeningAfterTTS = false;
          return;
        }

        if (_shouldStartQuizAfterVideo) {
          print("InsectDetailsScreen: Iniciando quiz após TTS.");
          _navigateToQuizView();
          _shouldStartQuizAfterVideo = false;
          return;
        }

        if (_canStartListeningAfterTTS && _speechService.isInitialized) {
          print("InsectDetailsScreen: TTS onComplete - Iniciando escuta após delay.");
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted && !_isSpeaking && !_isListening) {
            await _safeStartListening();
          }
        }
      },
      onError: (msg) {
        if (!mounted) return;
        print("InsectDetailsScreen: TTS onError - $msg");
        setState(() {
          _isSpeaking = false;
          _canStartListeningAfterTTS = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro no TTS: $msg")),
        );
        if (mounted && !_videoPlayerInitialized || !_videoController.value.isPlaying) {
          _restartListening(delayMs: 1000);
        }
      },
    );
    print("InsectDetailsScreen: TTS configurado.");
  }

  Future<void> _handleVoiceCommand(String command) async {
    if (!mounted || _isSpeaking) {
      print("InsectDetailsScreen: Comando ignorado: _isSpeaking=$_isSpeaking, mounted=$mounted");
      return;
    }

    print("InsectDetailsScreen: Processando comando: '$command'");
    await _speechService.stop();
    if (mounted) setState(() => _isListening = false);
    await _ttsService.stop();
    if (mounted) setState(() => _isSpeaking = false);

    _canStartListeningAfterTTS = true;

    try {
      final lowerCommand = command.toLowerCase().trim();

      if (_matchesCommand(lowerCommand, 'voltar')) {
        await _executeCommand('Retornando para a lista de insetos', _navigateToListView);
        return;
      }

      if (_matchesCommand(lowerCommand, 'video')) {
        print("InsectDetailsScreen: Comando 'video' reconhecido.");
        if (mounted) setState(() => _isProcessingVideoCommand = true);
        await _handleVideoActionByVoice(lowerCommand);
        return;
      }

      if (_matchesCommand(lowerCommand, 'parar')) {
        print("InsectDetailsScreen: Comando 'parar' reconhecido.");
        if (_videoPlayerInitialized && _videoController.value.isInitialized && _videoController.value.isPlaying) {
          if (mounted) setState(() => _isProcessingVideoCommand = true);
          await _executeCommand("Parando vídeo", () {
            if (mounted && _videoPlayerInitialized) _videoController.pause();
          });
        } else {
          await _ttsService.speak("O vídeo não está tocando para ser parado.");
        }
        if (mounted) setState(() => _isProcessingVideoCommand = false);
        return;
      }

      if (_matchesCommand(lowerCommand, 'perguntas')) {
        print("InsectDetailsScreen: Comando 'perguntas' reconhecido.");
        if (_videoPlayerInitialized && _videoController.value.isInitialized && _videoController.value.isPlaying) {
          if (mounted) setState(() => _shouldStartQuizAfterVideo = true);
          _canStartListeningAfterTTS = false;
          await _ttsService.speak("O quiz iniciará após o término do vídeo.");
        } else {
          await _executeCommand('Navegando para o quiz', _navigateToQuizView);
        }
        return;
      }

      print("InsectDetailsScreen: Comando não reconhecido: '$lowerCommand'");
      await _ttsService.speak("Comando não reconhecido. Tente 'reproduzir vídeo', 'parar vídeo', 'perguntas' ou 'voltar'.");
    } catch (e) {
      print("InsectDetailsScreen: Erro ao processar comando: $e");
      _canStartListeningAfterTTS = true;
      if (mounted) setState(() => _isProcessingVideoCommand = false);
      if (mounted && !_isSpeaking && !_isListening && !(_videoPlayerInitialized && _videoController.value.isPlaying)) {
        await _restartListening();
      }
    }
  }

  Future<void> _handleVideoActionByVoice(String command) async {
    _canStartListeningAfterTTS = true;
    try {
      if (!_videoPlayerInitialized || !_videoController.value.isInitialized) {
        await _ttsService.speak("O vídeo ainda não está pronto. Aguarde.");
        if (mounted) setState(() => _isProcessingVideoCommand = false);
        return;
      }

      bool wasPlaying = _videoController.value.isPlaying;
      String ttsMessage = "";
      bool playAction = false;
      bool pauseAction = false;

      if (command.contains('reproduzir') ||
          command.contains('play') ||
          command.contains('iniciar') ||
          command.contains('começar') ||
          command.contains('tocar')) {
        if (!wasPlaying) {
          playAction = true;
          ttsMessage = "Reproduzindo vídeo.";
        } else {
          ttsMessage = "O vídeo já está em reprodução.";
          _canStartListeningAfterTTS = false;
        }
      } else if (command.contains('pausar')) {
        if (wasPlaying) {
          pauseAction = true;
          ttsMessage = "Vídeo pausado.";
        } else {
          ttsMessage = "O vídeo já está pausado.";
        }
      } else {
        if (wasPlaying) {
          pauseAction = true;
          ttsMessage = "Vídeo pausado.";
        } else {
          playAction = true;
          ttsMessage = "Reproduzindo vídeo.";
        }
      }

      if (playAction) {
        if (mounted) _videoController.play();
        _canStartListeningAfterTTS = false;
        print("InsectDetailsScreen: Vídeo INICIADO por comando: $command");
      } else if (pauseAction) {
        if (mounted) _videoController.pause();
        print("InsectDetailsScreen: Vídeo PAUSADO por comando: $command");
      }

      await _ttsService.speak(ttsMessage);
    } catch (e) {
      print("InsectDetailsScreen: Erro em _handleVideoActionByVoice: $e");
      _canStartListeningAfterTTS = true;
      await _ttsService.speak("Ocorreu um erro com o vídeo.");
    } finally {
      if (mounted) setState(() => _isProcessingVideoCommand = false);
      if (mounted && !_isSpeaking && !_videoController.value.isPlaying) {
        await _restartListening(delayMs: 1200);
      }
    }
  }

  Future<void> _stopAllAudioAndVideo() async {
    print("InsectDetailsScreen: Parando áudio e vídeo...");
    _canStartListeningAfterTTS = false;
    await _ttsService.stop();
    await _speechService.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isListening = false;
      });
    }
    if (_videoPlayerInitialized && _videoController.value.isInitialized && _videoController.value.isPlaying) {
      await _videoController.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("InsectDetailsScreen: AppLifecycleState: $state");
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_servicesInitialized) {
          print("InsectDetailsScreen: App resumido, inicializando serviços.");
          _initializeServices();
        } else if (mounted &&
            _servicesInitialized &&
            !_isListening &&
            !_isSpeaking &&
            !(_videoPlayerInitialized && _videoController.value.isPlaying)) {
          print("InsectDetailsScreen: App resumido, reiniciando escuta.");
          _canStartListeningAfterTTS = true;
          _restartListening(delayMs: 500);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print("InsectDetailsScreen: App pausado/inativo, parando áudio/vídeo.");
        _stopAllAudioAndVideo();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _navigateToQuizView() async {
    await _stopAllAudioAndVideo();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuizScreen(insectName: widget.insect.name)),
      ).then((_) {
        if (mounted) {
          print("InsectDetailsScreen: Retornou do QuizScreen, reinicializando serviços.");
          _servicesInitialized = false;
          _initializeServices();
        }
      });
    }
  }

  void _navigateToListView() async {
    await _stopAllAudioAndVideo();
    if (mounted) {
      Navigator.pop(context);
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
      'parar': [
        'parar',
        'pausar',
        'stop',
        'pára',
        'pare',
        'parar vídeo',
        'parar video',
      ],
    };

    return variations[command]?.any((variant) => input.toLowerCase().contains(variant)) ?? false;
  }

  Future<void> _speakWelcomeMessage() async {
    if (!mounted) return;
    print("InsectDetailsScreen: Falando mensagem de boas-vindas...");
    _canStartListeningAfterTTS = true;
    await _ttsService.speak(
      "Detalhes sobre ${widget.insect.name}. "
      "Diga 'perguntas' para o quiz, 'reproduzir vídeo' para o vídeo, ou 'voltar'.",
    );
    print("InsectDetailsScreen: Mensagem de boas-vindas enviada ao TTS.");
  }

  Future<void> _safeStartListening({Duration listenFor = const Duration(minutes: 10)}) async {
    if (!mounted) {
      print("InsectDetailsScreen: SafeStartListening - Widget não montado.");
      return;
    }
    if (_isSpeaking) {
      print("InsectDetailsScreen: SafeStartListening - TTS está falando.");
      return;
    }
    if (_isListening) {
      print("InsectDetailsScreen: SafeStartListening - Já está escutando.");
      return;
    }
    if (_videoPlayerInitialized && _videoController.value.isInitialized && _videoController.value.isPlaying) {
      print("InsectDetailsScreen: SafeStartListening - Vídeo está tocando.");
      return;
    }
    if (!_speechService.isInitialized) {
      print("InsectDetailsScreen: SafeStartListening - SpeechService não inicializado. Tentando reinicializar...");
      await _initializeSpeechService();
      if (!_speechService.isInitialized) {
        print("InsectDetailsScreen: SafeStartListening - SpeechService ainda não inicializado.");
        _canStartListeningAfterTTS = true;
        await _ttsService.speak("Os comandos de voz não estão disponíveis. Verifique as permissões do microfone.");
        return;
      }
    }

    try {
      print("InsectDetailsScreen: SafeStartListening - Iniciando escuta...");
      await _startListening(listenFor: listenFor);
    } catch (e) {
      if (mounted) _handleListeningError(e);
    }
  }

  Future<void> _startListening({Duration listenFor = const Duration(minutes: 10)}) async {
    if (!mounted || _isSpeaking || _isListening || (_videoPlayerInitialized && _videoController.value.isPlaying)) {
      print("InsectDetailsScreen: Não pode iniciar escuta: "
          "mounted=$mounted, _isSpeaking=$_isSpeaking, _isListening=$_isListening, videoPlaying=${_videoController.value.isPlaying}");
      return;
    }

    try {
      if (mounted) setState(() => _isListening = true);
      print("InsectDetailsScreen: Iniciando escuta...");
      await _speechService.listen(
        onResult: _handleVoiceCommand,
        localeId: 'pt-BR',
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 10),
        autoRestartOnNoMatch: true,
        onSoundLevelChange: (level) {
          if (level > 0) print("InsectDetailsScreen: Nível de som: $level");
        },
      );
      print("InsectDetailsScreen: Escuta ativada com sucesso.");
    } catch (e) {
      print("InsectDetailsScreen: Erro ao iniciar escuta: $e");
      if (mounted) _handleListeningError(e);
    }
  }

  Future<void> _handleListeningError(dynamic error) async {
    print("InsectDetailsScreen: Erro no reconhecimento de voz: $error");
    if (mounted) setState(() => _isListening = false);

    String errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('error_audio') || errorMessage.contains('error 7')) {
      print("InsectDetailsScreen: Erro no áudio.");
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
        await _speechService.reset();
        await _initializeSpeechService();
      }
    } else if (errorMessage.contains('error_client') || errorMessage.contains('error_busy')) {
      print("InsectDetailsScreen: Erro no cliente de reconhecimento. Reinicializando serviços.");
      if (mounted) {
        _servicesInitialized = false;
        await _initializeServices();
        return;
      }
    } else if (errorMessage.contains('error_no_match')) {
      print("InsectDetailsScreen: Nenhum comando reconhecido.");
      if (mounted) {
        await _ttsService.speak("Não entendi. Por favor, repita o comando.");
      }
    } else if (!errorMessage.contains('error_speech_timeout')) {
      print("InsectDetailsScreen: Erro de reconhecimento não tratado: $errorMessage");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Problema temporário no reconhecimento de voz")),
        );
      }
    }

    if (mounted && !_isSpeaking && !(_videoPlayerInitialized && _videoController.value.isPlaying) && !_isListening) {
      print("InsectDetailsScreen: Tentando reiniciar escuta após erro.");
      _canStartListeningAfterTTS = true;
      await _restartListening(delayMs: 1500);
    }
  }

  Future<void> _checkMicrophonePermissions() async {
    var status = await ph.Permission.microphone.status;
    if (!status.isGranted) {
      status = await ph.Permission.microphone.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microfone não autorizado'),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: () {
                ph.openAppSettings(); // Use the alias
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _restartListening({int delayMs = 1000, Duration listenFor = const Duration(minutes: 10)}) async {
    if (!mounted) {
      print("InsectDetailsScreen: _restartListening - Widget não montado.");
      return;
    }
    if (_isSpeaking || (_videoPlayerInitialized && _videoController.value.isInitialized && _videoController.value.isPlaying)) {
      print("InsectDetailsScreen: Não pode reiniciar escuta: TTS ou vídeo ativo.");
      _canStartListeningAfterTTS = false;
      return;
    }

    print("InsectDetailsScreen: Tentando reiniciar escuta em $delayMs ms...");

    if (_isListening) {
      await _speechService.stop();
      if (mounted) setState(() => _isListening = false);
    }

    await _checkMicrophonePermissions();
    await Future.delayed(Duration(milliseconds: delayMs));

    if (mounted && !_isSpeaking && !(_videoPlayerInitialized && _videoController.value.isPlaying) && !_isListening) {
      print("InsectDetailsScreen: Reiniciando escuta agora...");
      await _safeStartListening(listenFor: listenFor);
    } else {
      print("InsectDetailsScreen: Condições para reiniciar escuta não atendidas após delay.");
    }
  }

  Future<void> _executeCommand(String ttsCommand, Function() action) async {
    _vibrationService.vibrate();
    await _ttsService.speak(ttsCommand);
    if (mounted) action();
  }

  @override
  void dispose() {
    print("InsectDetailsScreen: Disposing ${widget.insect.name}...");
    WidgetsBinding.instance.removeObserver(this);
    _videoController.removeListener(_videoPlaybackListener);
    _videoController.dispose();
    _scrollController.dispose();
    _stopAllAudioAndVideo();
    _servicesInitialized = false;
    super.dispose();
  }

  Widget _buildVideoPlayerControls() {
    if (!_videoPlayerInitialized || !_videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(_videoController.value.isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 28),
        label: Text(_videoController.value.isPlaying ? 'Pausar Vídeo' : 'Reproduzir Vídeo', style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _videoController.value.isPlaying ? Colors.orangeAccent : Colors.lightGreen,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () {
          if (!_videoPlayerInitialized || !_videoController.value.isInitialized) return;
          _vibrationService.vibrate();
          _ttsService.stop();
          _speechService.stop();
          if (mounted) {
            setState(() {
              _isSpeaking = false;
              _isListening = false;
              _canStartListeningAfterTTS = false;
              if (_videoController.value.isPlaying) {
                _videoController.pause();
              } else {
                _videoController.play();
              }
            });
          }
          if (!_videoController.value.isPlaying && mounted) {
            _canStartListeningAfterTTS = true;
            _restartListening(delayMs: 700);
          } else if (_videoController.value.isPlaying && mounted) {
            _canStartListeningAfterTTS = false;
          }
        },
      ),
    );
  }

  void _scrollToBottomAnimated() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
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
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrationService.vibrate();
            _navigateToListView();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.insect.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            if (_videoPlayerInitialized && _videoController.value.isInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            const SizedBox(height: 10),
            _buildVideoPlayerControls(),
            const SizedBox(height: 20),
            Container(
              height: 250,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
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
                          textStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                          speed: const Duration(milliseconds: 40),
                          cursor: '_',
                        ),
                      ],
                      isRepeatingAnimation: false,
                      onFinished: _scrollToBottomAnimated,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.quiz_outlined, color: Colors.white),
                label: const Text(
                  'Fazer Quiz',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () {
                  _vibrationService.vibrate();
                  _navigateToQuizView();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB08A),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
