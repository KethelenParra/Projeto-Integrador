import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _listening = false;
  bool _permission = false;
  String _lastError = '';

  Future<void> reset() async {
    await _speech.stop();
    _initialized = false;
    _listening = false;
    _lastError = '';
    await _speech.cancel();
  }

  Future<bool> checkPermissions({BuildContext? context}) async {
    var status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.microphone.request();
    }
    _permission = await Permission.microphone.isGranted;
    if (!_permission && context != null && context.mounted) {
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
    return _permission;
  }

  Future<bool> initialize({BuildContext? context}) async {
    if (_initialized) return true;
    if (!await checkPermissions(context: context)) {
      _lastError = 'Permissão de microfone negada';
      return false;
    }
    _initialized = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') _listening = false;
      },
      onError: (e) {
        _lastError = e.errorMsg;
        _listening = false;
      },
      debugLogging: true,
    );
    return _initialized;
  }

  Future<void> listen({
    required Function(String) onResult,
    String localeId = 'pt_BR',
    Duration listenFor = const Duration(seconds: 60),
    Duration pauseFor = const Duration(seconds: 10),
    Function(double)? onSoundLevelChange,
  }) async {
    if (!_initialized || _listening) return;
    await _speech.listen(
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty) onResult(r.recognizedWords);
      },
      onSoundLevelChange: onSoundLevelChange,
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
      listenFor: listenFor,
      pauseFor: pauseFor,
    );
    _listening = true;
  }

  Future<void> stop() async {
    await _speech.stop();
    _listening = false;
  }

  bool get isInitialized => _initialized;
  bool get isListening => _listening;
  bool get permissionGranted => _permission;
  String get lastError => _lastError;
}
