import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
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
    await _configureTTS();
    await _initializeSpeechService();
    await _speakWelcomeMessage();
  }

  Future<void> _configureTTS() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
      _speechService.stop();
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
      if (mounted) _startListening();
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      if (mounted) _startListening();
    });
  }

  Future<void> _initializeSpeechService() async {
    bool initialized = await _speechService.initialize(context: context);
    if (initialized) {
      _startListening();
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
        'quiz',
        'quis',
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
        'reproduzir video',
      ],
    };

    return variations[command]?.any((variant) => input.toLowerCase().contains(variant)) ?? false;
  }

  Future<void> _speakWelcomeMessage() async {
    String message = "Detalhes do ${widget.insect.name}. "
        "Diga 'quiz' para iniciar o questionário ou 'voltar' para retornar à tela anterior e 'video' para habilitar o audio do video sobre o inseto";
    await _flutterTts.speak(message);
  }

  Future<void> _startListening() async {
    if (_isSpeaking || !mounted || !_speechService.isInitialized) return;

    try {
      await _speechService.listen(
        onResult: _handleVoiceCommand,
        localeId: "pt_BR",
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {},
      );
      setState(() => _isListening = true);
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      setState(() => _isListening = false);
    }
  }

  void _handleVoiceCommand(String command) async {
    if (_matchesCommand(command, 'voltar')) {
      await _executeCommand('voltar', () {
        _videoController.pause();
        Navigator.pop(context);
      });
    } else if (_matchesCommand(command, 'perguntas')) {
      await _executeCommand('quiz', () {
        _videoController.pause();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(insectName: widget.insect.name),
          ),
        ).then((_) {
          if (mounted) {
            _initializeServices();
          }
        });
      });
    } else if (_matchesCommand(command, 'video')) {
      await _executeCommand(_videoController.value.isPlaying ? 'pausar vídeo' : 'iniciar vídeo', () {
        setState(() {
          if (_videoController.value.isPlaying) {
            _vibrate();
            _videoController.pause();
          } else {
            _vibrate();
            _videoController.play();
          }
        });
      });
    }
  }

  Future<void> _executeCommand(String command, Function() action) async {
    _vibrate();
    await _flutterTts.speak("Executando $command");
    await Future.delayed(const Duration(milliseconds: 500));
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

  // Função para começar a escutar o comando de voz
/*
  void _listenForCommand() async {
    if (!_isListening) {
      bool available = await _speechToText.listen(
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          if (command.contains("quiz")) {
            _vibrate(); // Vibração ao reconhecer o comando
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
          } else if (command.contains("voltar")) {
            _vibrate(); // Vibração ao reconhecer o comando
            _videoController.pause(); // Pausa o vídeo ao voltar
            Navigator.pop(context);
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
      }
    }
  }
*/

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