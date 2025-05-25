import 'package:flutter/material.dart';
import 'package:vision_app_3d/screens/insect_list/insect_list_screen.dart';
import 'package:vision_app_3d/screens/qr_view_exemple.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/recognition_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart';

class HomePageController {
  final BuildContext context;
  final TtsService _tts = TtsService();
  final RecognitionService _rec = RecognitionService();
  final VibrationService _vib = VibrationService();

  bool _isListening = false;

  HomePageController(this.context);

  /// Sempre fala o prompt curto.
  Future<void> init() async {
    await _tts.stop();
    await _rec.stop();
    _isListening = false;

    await _tts.configure(language: 'pt-BR', rate: 0.5, volume: 1.0);
    _tts.setHandlers(
      onStart: () {},
      onComplete: _onTtsComplete,
      onError: (_) {},
    );

    if (!await _rec.initialize(context: context)) return;
    await _tts.speak(
        'Obrigado por utilizar o Vision App, um aplicativo dedicado a promover '
        'o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar '
        'e descobrir informações sobre diferentes espécies de insetos, com recursos '
        'em áudio, vídeos e através da experiência com as mãos. Viva uma experiência '
        'interessante. Diga lista para ir para a lista de insetos ou escanear para '
        'ir para a página do QR Code.');
  }

  void dispose() {
    _tts.stop();
    _rec.stop();
  }

  void _onTtsComplete() async {
    if (!_isListening) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    _isListening = true;
    await _vib.vibrate(duration: 100);
    await _rec.listen(
      onResult: handleVoiceCommand,
      localeId: 'pt-BR',
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
    );
  }

  Future<void> handleVoiceCommand(String command) async {
    final cmd = command.toLowerCase().trim();
    await _rec.stop();
    _isListening = false;

    if (cmd.contains('lista')) {
      await _execute('Abrindo lista de insetos', _goToList);
    } else if (cmd.contains('escanear')) {
      await _execute('Abrindo leitor de QR Code', _goToQR);
    } else {
      await _tts.speak('Comando não reconhecido');
      await _startListening();
    }
  }

  Future<void> _execute(String msg, Future<void> Function() act) async {
    await _vib.vibrate(duration: 100);
    await _tts.speak(msg);
    await act();
  }

  Future<void> _goToList() async {
    await _tts.stop();
    await _rec.stop();
    _isListening = false;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InsectListScreen()),
    );
    // após voltar da lista, relê o prompt
    await init();
  }

  Future<void> _goToQR() async {
    await _tts.stop();
    await _rec.stop();
    _isListening = false;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRViewExample()),
    );
    // após voltar do QR, relê o prompt
    await init();
  }
}
