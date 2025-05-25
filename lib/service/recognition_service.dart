import 'package:flutter/material.dart';
import 'speech_service.dart';

class RecognitionService {
  final SpeechService _speech = SpeechService();

  Future<bool> initialize({required BuildContext context}) =>
      _speech.initialize(context: context);

  Future<void> listen({
    required Function(String) onResult,
    String localeId = 'pt_BR',
    Duration listenFor = const Duration(seconds: 60),
    Duration pauseFor = const Duration(seconds: 10),
    Function(double)? onSoundLevelChange,
  }) =>
      _speech.listen(
        onResult: onResult,
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        onSoundLevelChange: onSoundLevelChange,
      );

  Future<void> stop() => _speech.stop();
  Future<void> reset() => _speech.reset();

  bool get isInitialized => _speech.isInitialized;
  bool get isListening => _speech.isListening;
  bool get permissionGranted => _speech.permissionGranted;
  String get lastError => _speech.lastError;
}
