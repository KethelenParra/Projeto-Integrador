import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:vision_app_3d/screens/quiz_screen.dart';
import 'package:vision_app_3d/service/recognition_service.dart';
import 'package:vision_app_3d/service/speech_service.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart';

/// Controller da tela de detalhes de inseto
typedef VoidCallback = void Function();

class InsectDetailsController {
  final BuildContext context;
  final Insect insect;
  final VoidCallback playVideo;
  final VoidCallback pauseVideo;
  final TtsService _tts = TtsService();
  final RecognitionService _rec = RecognitionService();
  final VibrationService _vib = VibrationService();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _awaitVideoCompletion = false;

  InsectDetailsController({
    required this.context,
    required this.insect,
    required this.playVideo,
    required this.pauseVideo,
  });

  /// Inicializa TTS, reconhecimento e fala instruções iniciais
  Future<void> init() async {
    await _stopAll();
    await _configureTts();
    bool ok = await _rec.initialize(context: context);
    if (!ok) return;
    _speakInstruction();
  }

  Future<void> _configureTts() async {
    await _tts.configure(language: 'pt-BR', rate: 0.5, volume: 1.0);
    _tts.setHandlers(
      onStart: () {
        _isSpeaking = true;
        if (_isListening) {
          _rec.stop();
          _isListening = false;
        }
      },
      onComplete: () async {
        _isSpeaking = false;
        if (_awaitVideoCompletion) {
          // não iniciar escuta até o vídeo terminar
          _awaitVideoCompletion = false;
          return;
        }
        await Future.delayed(const Duration(milliseconds: 300));
        _startListening();
      },
      onError: (msg) {
        _isSpeaking = false;
        _startListening();
      },
    );
  }

  /// Fala instruções de uso na tela
  Future<void> _speakInstruction() async {
    final msg = 'Detalhando ${insect.name}. '
        'Diga "reproduzir vídeo", "perguntas" para o quiz ou "lista" para voltar à lista de insetos.';
    await _tts.speak(msg);
  }

  /// Repete instruções (e.g. no fim do vídeo ou retorno do quiz)
  Future<void> repeatInstruction() async {
    await _tts.stop();
    await _rec.stop();
    _speakInstruction();
  }

  Future<void> _startListening() async {
    if (_isSpeaking || _isListening) return;
    _isListening = true;
    await _vib.vibrate();
    await _rec.listen(onResult: handleVoiceCommand);
  }

  /// Processa comando de voz
  Future<void> handleVoiceCommand(String command) async {
    final cmd = command.toLowerCase().trim();
    await _rec.stop();
    _isListening = false;
    await _vib.vibrate();

    if (cmd.contains('lista')) {
      pauseVideo();
      Navigator.pop(context);
    } else if (cmd.contains('reproduzir')) {
      await _tts.speak('Reproduzindo vídeo');
      _awaitVideoCompletion = true;
      playVideo();
    } else if (cmd.contains('perguntas') || cmd.contains('quiz')) {
      pauseVideo();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizScreen(insectName: insect.name)),
      );
    } else {
      final err =
          'Comando não reconhecido. Diga "reproduzir vídeo", "perguntas" para o quiz ou "lista" para voltar à lista de insetos.';
      await _tts.speak(err);
    }
  }

  Future<void> _stopAll() async {
    await _tts.stop();
    await _rec.stop();
    _isListening = false;
    _isSpeaking = false;
    _awaitVideoCompletion = false;
  }

  void dispose() {
    _tts.stop();
    _rec.stop();
  }
}
