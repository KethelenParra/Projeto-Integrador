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

  Future<bool> checkPermissions({BuildContext? context}) async {
    final status = await Permission.microphone.request();
    _permissionGranted = status.isGranted;
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
      print("Initialization failed: Microphone permission denied");
      _lastError = "Microphone permission denied";
      return false;
    }

    try {
      print("Attempting to initialize SpeechToText...");
      // Obtém os idiomas disponíveis para depuração
      List<dynamic> locales = await _speechToText.locales();
      print("Available locales: ${locales.map((locale) => locale.localeId).toList()}");

      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          print("SpeechToText Status: $status");
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
        },
        onError: (error) {
          print("SpeechToText Error: ${error.errorMsg}, Permanent: ${error.permanent}");
          _lastError = error.errorMsg;
          _isListening = false;
          if (error.permanent || error.errorMsg == 'error_client' || error.errorMsg == 'error_busy') {
            _isInitialized = false; // Force reinitialization on critical errors
          }
        },
        debugLogging: true, // Ativa logs detalhados para depuração
      );

      if (_isInitialized) {
        print("SpeechToText initialization successful");
        // Verifica se o idioma pt-BR está disponível
        String localeId = 'pt_BR'; // Note o underline em vez de hífen
        if (locales.map((locale) => locale.localeId).contains(localeId)) {
          print("Locale $localeId is available");
        } else {
          print("Locale $localeId not available, falling back to default");
          localeId = 'en_US'; // Fallback para inglês se pt-BR não estiver disponível
        }
      } else {
        print("SpeechToText initialization failed");
        _lastError = "Initialization failed";
      }
      print("SpeechToText initialization result: $_isInitialized");
      return _isInitialized;
    } catch (e) {
      print("Error initializing SpeechToText: $e");
      _lastError = "Exception during initialization: $e";
      _isInitialized = false;
      return false;
    }
  }

  Future<void> listen({
    required Function(String) onResult,
    String localeId = 'pt_BR',
    Duration? listenFor,
    Duration? pauseFor,
    required Null Function(dynamic level) onSoundLevelChange,
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
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 45), // Aumentado para 45 segundos
        pauseFor: const Duration(seconds: 5),   // Aumentado para 5 segundos
        sampleRate: 44100,
 // Tentar uma taxa de amostragem maior
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
    if (_isListening) {
      print("Stopping speech recognition");
      await _speechToText.stop();
      _isListening = false;
    }
  }

  bool get isListening => _isListening;

  bool get isInitialized => _isInitialized;

  bool get permissionGranted => _permissionGranted;

  String get lastError => _lastError;
}
