import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _permissionGranted = false;
  String _lastError = '';

  factory SpeechService() => _instance;

  SpeechService._internal();

  Future<void> reset() async {
    print("Resetando SpeechService...");
    await _speechToText.stop();
    _isInitialized = false;
    _isListening = false;
    _lastError = '';
    await _speechToText.cancel();
    print("SpeechService resetado");
  }

  Future<bool> checkPermissions({BuildContext? context}) async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.microphone.request();
    }
    _permissionGranted = await Permission.microphone.isGranted;
    if (!_permissionGranted && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permissão de microfone necessária.'),
          action: SnackBarAction(
            label: 'Configurações',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
    print("Permission check result: $_permissionGranted");
    return _permissionGranted;
  }

  Future<bool> initialize({BuildContext? context}) async {
    if (_isInitialized) {
      print("SpeechService already initialized");
      return true;
    }

    _permissionGranted = await checkPermissions(context: context);
    if (!_permissionGranted) {
      _lastError = "Microphone permission denied";
      return false;
    }

    try {
      print("Attempting to initialize SpeechToText...");
      List<dynamic> locales = await _speechToText.locales();
      print("Available locales: ${locales.map((locale) => locale.localeId).toList()}");

      String localeId = 'pt_BR';
      if (!locales.map((locale) => locale.localeId).contains(localeId)) {
        print("Locale $localeId not available, falling back to en_US");
        localeId = 'en_US';
      }

      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          print("SpeechToText Status: $status");
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            print("Status $status detectado, aguardando chamador para reiniciar escuta");
          }
        },
        onError: (error) {
          print("SpeechToText Error: ${error.errorMsg}, Permanent: ${error.permanent}");
          _lastError = error.errorMsg;
          _isListening = false;
        },
        debugLogging: true,
      );

      if (!_isInitialized) {
        _lastError = "Initialization failed";
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Falha ao inicializar reconhecimento de voz: $_lastError")),
          );
        }
      }
      print("SpeechService initialization result: $_isInitialized");
      return _isInitialized;
    } catch (e) {
      print("Error initializing SpeechToText: $e");
      _lastError = "Exception during initialization: $e";
      _isInitialized = false;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao inicializar reconhecimento de voz: $e")),
        );
      }
      return false;
    }
  }

  Future<void> listen({
    required Function(String) onResult,
    String localeId = 'pt_BR',
    Duration? listenFor,
    Duration? pauseFor,
    Function(double)? onSoundLevelChange,
  }) async {
    if (!_isInitialized || _isListening || !_permissionGranted) {
      print(
          "Cannot listen: Initialized: $_isInitialized, Listening: $_isListening, Permission: $_permissionGranted, Last Error: $_lastError");
      return;
    }

    try {
      print("Starting speech recognition with locale: $localeId");
      await _speechToText.listen(
        onResult: (result) {
          print("Speech result: ${result.recognizedWords}, Final: ${result.finalResult}, Confidence: ${result.confidence}");
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords); // Enviar todos os resultados
          }
        },
        onSoundLevelChange: onSoundLevelChange,
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        listenFor: listenFor ?? const Duration(seconds: 120), // Aumentado
        pauseFor: pauseFor ?? const Duration(seconds: 5),
        sampleRate: 44100, // Aumentado para melhor qualidade
      );
      _isListening = true;
      print("Speech recognition started");
    } catch (e) {
      print("Error starting listen: $e");
      _lastError = "Error starting listen: $e";
      _isListening = false;
    }
  }

  Future<void> stop() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      print("Speech recognition stopped");
    } catch (e) {
      print("Error stopping speech recognition: $e");
      _lastError = "Error stopping speech recognition: $e";
    }
  }

  bool get isListening => _isListening;

  bool get isInitialized => _isInitialized;

  bool get permissionGranted => _permissionGranted;

  String get lastError => _lastError;
}
