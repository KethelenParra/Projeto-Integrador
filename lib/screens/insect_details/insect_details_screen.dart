import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:vibration/vibration.dart';
import 'package:vision_app_3d/main.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:vision_app_3d/screens/quiz_screen.dart';
import 'package:vision_app_3d/service/vibration_service.dart';
import 'insect_details_controller.dart';

class InsectDetailsScreen extends StatefulWidget {
  final Insect insect;
  const InsectDetailsScreen({Key? key, required this.insect}) : super(key: key);

  @override
  State<InsectDetailsScreen> createState() => _InsectDetailsScreenState();
}

class _InsectDetailsScreenState extends State<InsectDetailsScreen>
    with RouteAware {
  late final InsectDetailsController _ctrl;
  late final VideoPlayerController _videoCtrl;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _videoCtrl = VideoPlayerController.asset(widget.insect.videoPath)
      ..initialize().then((_) => setState(() {}));
    _videoCtrl.addListener(() {
      if (_videoCtrl.value.isInitialized &&
          !_videoCtrl.value.isPlaying &&
          _videoCtrl.value.position >= _videoCtrl.value.duration) {
        _ctrl.repeatInstruction();
      }
    });

    _ctrl = InsectDetailsController(
      context: context,
      insect: widget.insect,
      playVideo: () => setState(() => _videoCtrl.play()),
      pauseVideo: () => setState(() => _videoCtrl.pause()),
    );
    _ctrl.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _ctrl.dispose();
    _videoCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // voltou do quiz
    _ctrl.repeatInstruction();
  }

  void _vibrate() {
    VibrationService().vibrate();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
    );
  }

  void _onPlayPause() {
    _vibrate();
    setState(() {
      _videoCtrl.value.isPlaying ? _videoCtrl.pause() : _videoCtrl.play();
    });
  }

  void _onQuizPress() {
    _vibrate();
    _videoCtrl.pause();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(insectName: widget.insect.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: Text(widget.insect.name,
            style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate();
            _videoCtrl.pause();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              widget.insect.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Vídeo
            if (_videoCtrl.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoCtrl.value.aspectRatio,
                child: VideoPlayer(_videoCtrl),
              )
            else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),

            // Play/Pause
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _vibrate();
                  setState(() {
                    _videoCtrl.value.isPlaying
                        ? _videoCtrl.pause()
                        : _videoCtrl.play();
                  });
                },
                child: Text(_videoCtrl.value.isPlaying ? 'Pause' : 'Play'),
              ),
            ),
            const SizedBox(height: 20),

            // Descrição animada
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2))
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
                              fontSize: 16, color: Colors.black),
                          speed: const Duration(milliseconds: 50),
                          cursor: '|',
                        ),
                      ],
                      isRepeatingAnimation: false,
                      onNextBeforePause: (_, __) => _scrollToBottom(),
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

            // Botão Fazer Quiz
            Center(
              child: ElevatedButton(
                onPressed: _onQuizPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB08A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Fazer Quiz',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
