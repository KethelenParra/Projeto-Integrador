import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  Future<void> configure({
    String language = 'pt-BR',
    double rate = 0.5,
    double volume = 1.0,
  }) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(volume);
  }

  void setHandlers({
    Function()? onStart,
    Function()? onComplete,
    Function(String)? onError,
  }) {
    _tts.setStartHandler(() {
      _isSpeaking = true;
      onStart?.call();
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete?.call();
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onError?.call(msg);
    });
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  bool get isSpeaking => _isSpeaking;
}
