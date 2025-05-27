import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _internalIsSpeaking = false; // Estado interno gerenciado pelos handlers do plugin

  // Callbacks que o usuário da classe (ex: InsectListScreen) pode fornecer
  Function? _userOnStartCallback;
  Function? _userOnCompleteCallback;
  Function(String)? _userOnErrorCallback;

  TtsService() {
    // Configura os handlers do flutter_tts uma vez.
    // Eles atualizarão o estado interno e chamarão os callbacks do usuário se estiverem definidos.
    _flutterTts.setStartHandler(() {
      print("TTS Service Handler: Speech Started");
      _internalIsSpeaking = true;
      _userOnStartCallback?.call(); // Chama o callback do usuário se existir
    });

    _flutterTts.setCompletionHandler(() {
      print("TTS Service Handler: Speech Completed");
      _internalIsSpeaking = false;
      _userOnCompleteCallback?.call(); // Chama o callback do usuário se existir
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Service Handler: Speech Error: $msg");
      _internalIsSpeaking = false;
      _userOnErrorCallback?.call(msg); // Chama o callback do usuário se existir
    });
  }

  Future<void> initialize({
    String language = "pt-BR",
    double speechRate = 0.5,
    double volume = 1.0,
    // Callbacks opcionais que a tela pode passar para ser notificada sobre os eventos do TTS
    Function? onStart,
    Function? onComplete,
    Function(String)? onError,
  }) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(volume);

      // CORREÇÃO APLICADA AQUI:
      // ESSENCIAL: Faz com que `await _flutterTts.speak()` espere a conclusão da fala.
      await _flutterTts.awaitSpeakCompletion(true); // Nome do método corrigido

      // Armazena os callbacks fornecidos pelo usuário para serem usados pelos handlers
      // configurados no construtor.
      _userOnStartCallback = onStart;
      _userOnCompleteCallback = onComplete;
      _userOnErrorCallback = onError;

      print("TTS Service: Initialized successfully with awaitSpeakCompletion=true.");

    } catch (e) {
      print("TTS Service: Error during initialize: $e");
      _userOnErrorCallback?.call("Erro ao inicializar TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) {
      print("TTS Service: Texto para falar está vazio. Não falando.");
      return;
    }

    try {
      print("TTS Service: Chamando _flutterTts.speak('$text') e aguardando conclusão...");
      // Com `awaitSpeakCompletion(true)` configurado no `initialize`,
      // o `await` aqui esperará a fala terminar.
      await _flutterTts.speak(text);
      // Quando esta linha é alcançada, a fala terminou (ou falhou e lançou uma exceção).
      // O `setCompletionHandler` (ou `setErrorHandler`) já terá sido chamado pelo plugin.
      print("TTS Service: `await _flutterTts.speak('$text')` liberado.");
    } catch (e) {
      print("TTS Service: Erro capturado durante `await _flutterTts.speak`: $e");
      if (_internalIsSpeaking) { // Garante que o estado seja resetado
        _internalIsSpeaking = false;
      }
      _userOnErrorCallback?.call("Erro durante speak: $e");
    }
  }

  Future<void> stop() async {
    try {
      print("TTS Service: Chamando _flutterTts.stop()...");
      await _flutterTts.stop();
      _internalIsSpeaking = false; // Garante o estado após a parada
      print("TTS Service: _flutterTts.stop() chamado.");
    } catch (e) {
      print("TTS Service: Erro durante _flutterTts.stop: $e");
      _internalIsSpeaking = false;
      _userOnErrorCallback?.call("Erro durante stop: $e");
    }
  }

  bool get isSpeaking => _internalIsSpeaking;
}
