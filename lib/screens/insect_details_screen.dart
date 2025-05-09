import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:vibration/vibration.dart';
import '../data/data_definition.dart'; // para InsetoData
import 'quiz_screen.dart';

class InsectDetailsScreen extends StatefulWidget {
  final InsetoData inseto;
  const InsectDetailsScreen({Key? key, required this.inseto}) : super(key: key);

  @override
  _InsectDetailsScreenState createState() => _InsectDetailsScreenState();
}

class _InsectDetailsScreenState extends State<InsectDetailsScreen> {
  late VideoPlayerController _videoController;
  final ScrollController _scrollController = ScrollController();
  double _currentScrollPosition = 0;

  @override
  void initState() {
    super.initState();

    // Configura e inicia o vídeo
    _videoController = VideoPlayerController.asset(widget.inseto.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.pause();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ins = widget.inseto;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: Text(ins.nome, style: const TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate();
            _videoController.pause();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            ins.nome,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_videoController.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            )
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),

          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_videoController.value.isPlaying) {
                    _videoController.pause();
                  } else {
                    _videoController.play();
                  }
                  _vibrate();
                });
              },
              child: Text(_videoController.value.isPlaying ? 'Pause' : 'Play'),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            height: 300,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
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
                        ins.descricao,
                        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                        speed: const Duration(milliseconds: 50),
                        cursor: '|',
                      ),
                    ],
                    isRepeatingAnimation: false,
                    onFinished: _scrollToBottom,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB08A),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                _vibrate();
                if (_videoController.value.isPlaying) {
                  _videoController.pause();
                }
                _videoController.seekTo(Duration.zero);
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(insectName: ins.nome),
                  ),
                );
              },
              child: const Text('Fazer Quiz', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ]),
      ),
    );
  }
}
