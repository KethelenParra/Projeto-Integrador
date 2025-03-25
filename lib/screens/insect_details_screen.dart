import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'quiz_screen.dart';
import 'package:vibration/vibration.dart'; // Import para vibração personalizada

class InsectDetailsScreen extends StatefulWidget {
  final Insect insect;

  const InsectDetailsScreen({super.key, required this.insect});

  @override
  State<InsectDetailsScreen> createState() => _InsectDetailsScreenState();
}

class _InsectDetailsScreenState extends State<InsectDetailsScreen> {
  late VideoPlayerController _videoController;
  final ScrollController _scrollController = ScrollController();
  double _currentScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.insect.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play(); // Inicia o vídeo automaticamente
      });
  }

  @override
  void dispose() {
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
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
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
                      builder: (context) =>
                          QuizScreen(insectName: widget.insect.name),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB08A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
