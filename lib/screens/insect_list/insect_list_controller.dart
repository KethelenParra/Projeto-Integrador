import 'package:flutter/material.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'package:vision_app_3d/screens/insect_details/insect_details_screen.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/recognition_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart';

const Map<String, List<String>> _insectPronunciations = {
  'Escorpião': ['escorpião', 'escorpiao', 'eskorpiao', 'es corpiao'],
  'Borboleta': ['borboleta', 'borboletta', 'boboleta'],
  'Barbeiro': ['barbeiro', 'barbiro', 'barbeiru'],
  'Abelha': ['abelha', 'abeja', 'abelia'],
  'Aranha': ['aranha', 'arania', 'aranjha'],
};

class InsectListController {
  final BuildContext context;
  final TtsService _tts = TtsService();
  final RecognitionService _rec = RecognitionService();
  final VibrationService _vib = VibrationService();

  bool _isListening = false;
  bool _isSpeaking = false;

  InsectListController(this.context);

  Future<void> init() async {
    await _tts.configure();
    _tts.setHandlers(
      onStart: _onSpeakStart,
      onComplete: _onSpeakComplete,
      onError: _onSpeakError,
    );

    if (!await _rec.initialize(context: context)) return;

    await Future.delayed(const Duration(milliseconds: 300));
    await _speakInstruction();
  }

  void dispose() {
    _stopAll();
  }

  void _onSpeakStart() {
    _isSpeaking = true;
    if (_isListening) {
      _rec.stop();
      _isListening = false;
    }
  }

  void _onSpeakComplete() {
    _isSpeaking = false;
    if (!_isListening) {
      Future.delayed(const Duration(milliseconds: 500), _startListening);
    }
  }

  void _onSpeakError(String _) {
    _isSpeaking = false;
    _startListening();
  }

  Future<void> _speakInstruction() async {
    const text = 'Fale o nome de um inseto para ver mais informações. '
        'Diga claramente: Escorpião, Borboleta, Barbeiro, Abelha ou Aranha. '
        'Diga voltar para retornar à tela inicial.';
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    _isListening = true;
    await _vib.vibrate();
    await _rec.listen(onResult: handleVoiceCommand);
  }

  Future<void> handleVoiceCommand(String command) async {
    final cmd = command.toLowerCase().trim();
    await _rec.stop();
    _isListening = false;

    if (cmd.contains('voltar')) {
      // volta para HomePage e dispara didPopNext lá
      await _stopAll();
      Navigator.pop(context);
      return;
    }

    String? matched;
    for (var e in _insectPronunciations.entries) {
      if (e.value.contains(cmd)) {
        matched = e.key;
        break;
      }
    }

    if (matched != null) {
      final insect = insectData.values.firstWhere((ins) => ins.name == matched);
      await _stopAll();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InsectDetailsScreen(insect: insect)),
      );
      // ao voltar do detalhe, a própria lista é reativada pelo lifecycle e chama init()
    } else {
      await _tts.speak('Inseto não encontrado. Tente novamente.');
      await _startListening();
    }
  }

  Future<void> _stopAll() async {
    await _tts.stop();
    await _rec.stop();
    _isListening = false;
    _isSpeaking = false;
  }
}
