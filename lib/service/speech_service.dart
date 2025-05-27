import 'package:flutter/material.dart'; // Para BuildContext, ScaffoldMessenger
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _permissionGranted = false;
  String _lastError = '';

  // Parâmetros para a lógica de reinício automático
  Function(String)? _currentOnResultCallback;
  String _currentLocaleId = 'pt_BR';
  Duration _currentListenForDuration = const Duration(minutes: 3); // Padrão: 3 minutos de escuta
  Duration _currentPauseForDuration = const Duration(seconds: 15); // Padrão: 15s de silêncio para parar
  Function(double)? _currentOnSoundLevelChangeCallback;
  bool _shouldAutoRestartOnNoMatch = false;
  int _autoRestartAttempts = 0;
  static const int _maxAutoRestartAttempts = 2; // Limite de tentativas de reinício automático

  factory SpeechService() => _instance;

  SpeechService._internal();

  Future<void> reset() async {
    print("SpeechService: Resetando...");
    await _speechToText.stop();
    _isInitialized = false; // Requer reinicialização
    _isListening = false;
    _lastError = '';
    _resetAutoRestartState(); // Reseta o estado de auto-restart
    print("SpeechService: Resetado.");
  }

  Future<bool> checkPermissions({BuildContext? context}) async {
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      final requestedStatus = await Permission.microphone.request();
      _permissionGranted = requestedStatus.isGranted;
    } else {
      _permissionGranted = status.isGranted;
    }

    if (!_permissionGranted && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permissão de microfone necessária para comandos de voz.'),
          action: SnackBarAction(
            label: 'Configurações',
            onPressed: openAppSettings, // Garanta que openAppSettings está acessível
          ),
        ),
      );
    }
    print("SpeechService: Permissão de microfone concedida: $_permissionGranted");
    return _permissionGranted;
  }

  Future<bool> initialize({BuildContext? context}) async {
    if (_isInitialized) {
      print("SpeechService: Já inicializado.");
      return true;
    }

    _permissionGranted = await checkPermissions(context: context);
    if (!_permissionGranted) {
      _lastError = "Permissão de microfone negada";
      print("SpeechService: Inicialização falhou - $_lastError");
      return false;
    }

    try {
      print("SpeechService: Tentando inicializar SpeechToText engine...");
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          print("SpeechService: Status do Engine STT: $status");
          bool engineIsActuallyListening = _speechToText.isListening;

          if (!engineIsActuallyListening && _isListening) {
            // Se o nosso estado _isListening era true, mas o engine parou
            print("SpeechService: Engine STT parou inesperadamente. _isListening era true. LastError: $_lastError");
            _isListening = false; // Sincroniza nosso estado
            if (_shouldAutoRestartOnNoMatch &&
                _lastError.isEmpty && // Só reinicia se não foi um erro crítico que parou
                _autoRestartAttempts < _maxAutoRestartAttempts) {
              print("SpeechService: Reiniciando escuta devido à parada do engine (onStatus). Tentativa: ${_autoRestartAttempts + 1}");
              _performAutoRestart();
            } else {
              _resetAutoRestartState();
            }
          }
        },
        onError: (errorNotification) {
          print("SpeechService: Erro no Engine STT: ${errorNotification.errorMsg}, Permanente: ${errorNotification.permanent}");
          _lastError = errorNotification.errorMsg;
          _isListening = false; // Erro implica que parou de escutar

          if (_shouldAutoRestartOnNoMatch &&
              (errorNotification.errorMsg.contains('error_no_match') || // Erro específico do Android/iOS
                  errorNotification.errorMsg.contains('error_speech_timeout') || // Outro erro comum
                  errorNotification.errorMsg.contains(' reconhecimento') // Parte de "Nenhuma correspondência de reconhecimento"
              ) &&
              _autoRestartAttempts < _maxAutoRestartAttempts) {
            print("SpeechService: Reiniciando escuta devido a no_match/timeout (onError). Tentativa: ${_autoRestartAttempts + 1}");
            _performAutoRestart();
          } else {
            print("SpeechService: Não reiniciando (erro não qualificado ou limite de tentativas). Erro: ${errorNotification.errorMsg}");
            _resetAutoRestartState();
          }
        },
        debugLogging: true, // Mantenha para depuração
      );

      if (!_isInitialized) {
        _lastError = "Falha na inicialização do SpeechToText engine.";
        print("SpeechService: $_lastError");
        if (context != null && context.mounted) {
          // Evitar mostrar SnackBar se já mostrado pelo checkPermissions
        }
      } else {
        print("SpeechService: Engine STT inicializado com sucesso.");
      }
      return _isInitialized;
    } catch (e) {
      _lastError = "Exceção durante a inicialização do SpeechToText: $e";
      print("SpeechService: $_lastError");
      _isInitialized = false;
      return false;
    }
  }

  void _performAutoRestart() async {
    if (!mounted || !_isInitialized || _isListening || !_permissionGranted || _currentOnResultCallback == null) {
      print("SpeechService: Condições para reinício automático não atendidas (pré-delay). "
          "Mounted: $mounted, Initialized: $_isInitialized, Listening: $_isListening, "
          "Permission: $_permissionGranted, Callback: ${_currentOnResultCallback != null}");
      _resetAutoRestartState(); // Garante que não fique preso tentando reiniciar
      return;
    }

    _autoRestartAttempts++;
    print("SpeechService: Atrasando reinício automático por 700ms. Tentativa: $_autoRestartAttempts");
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted && _isInitialized && !_isListening && _permissionGranted && _currentOnResultCallback != null) {
      print("SpeechService: Executando chamada de escuta interna para reinício automático.");
      _listenInternal(
        onResult: _currentOnResultCallback!,
        localeId: _currentLocaleId,
        listenFor: _currentListenForDuration,
        pauseFor: _currentPauseForDuration,
        onSoundLevelChange: _currentOnSoundLevelChangeCallback,
      );
    } else {
      print("SpeechService: Condições para reinício automático não atendidas após delay.");
      _resetAutoRestartState();
    }
  }

  void _resetAutoRestartState() {
    print("SpeechService: Resetando estado de reinício automático.");
    _shouldAutoRestartOnNoMatch = false;
    _autoRestartAttempts = 0;
    // Não limpar _currentOnResultCallback etc. aqui, pois eles são definidos pela chamada `listen` do usuário.
  }

  // Método público para iniciar a escuta
  Future<void> listen({
    required Function(String) onResult,
    String localeId = 'pt_BR',
    Duration? listenFor, // Usuário pode sobrescrever o padrão
    Duration? pauseFor,   // Usuário pode sobrescrever o padrão
    Function(double)? onSoundLevelChange,
    bool autoRestartOnNoMatch = false, // Novo parâmetro
  }) async {
    if (!_isInitialized) {
      _lastError = "Serviço de fala não inicializado.";
      print("SpeechService: $_lastError Tente chamar initialize() primeiro.");
      // Opcional: tentar inicializar automaticamente? Pode ser arriscado sem contexto.
      // bool success = await initialize();
      // if (!success) return;
      return;
    }
    if (_isListening) {
      _lastError = "Já está escutando.";
      print("SpeechService: $_lastError");
      return;
    }
    if (!_permissionGranted) {
      _lastError = "Permissão de microfone não concedida.";
      print("SpeechService: $_lastError");
      // Opcional: Tentar pedir permissão de novo?
      // bool permOK = await checkPermissions();
      // if(!permOK) return;
      return;
    }

    _lastError = ''; // Limpa erros anteriores para uma nova sessão de escuta
    _autoRestartAttempts = 0; // Reseta contador para uma nova chamada explícita de listen()

    // Armazena parâmetros para potencial reinício automático
    _currentOnResultCallback = onResult;
    _currentLocaleId = localeId;
    _currentListenForDuration = listenFor ?? const Duration(minutes: 3); // Padrão de 3 min
    _currentPauseForDuration = pauseFor ?? const Duration(seconds: 20); // Padrão de 20s de silêncio
    _currentOnSoundLevelChangeCallback = onSoundLevelChange;
    _shouldAutoRestartOnNoMatch = autoRestartOnNoMatch;

    print("SpeechService: Chamada pública para listen. AutoRestart: $_shouldAutoRestartOnNoMatch. "
        "ListenFor: $_currentListenForDuration, PauseFor: $_currentPauseForDuration");

    return _listenInternal(
      onResult: _currentOnResultCallback!,
      localeId: _currentLocaleId,
      listenFor: _currentListenForDuration,
      pauseFor: _currentPauseForDuration,
      onSoundLevelChange: _currentOnSoundLevelChangeCallback,
    );
  }

  // Método interno que realmente chama o _speechToText.listen
  Future<void> _listenInternal({
    required Function(String) onResult,
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
    Function(double)? onSoundLevelChange,
  }) async {
    if (!_isInitialized || _isListening || !_permissionGranted) {
      print("SpeechService: _listenInternal bloqueado. Init: $_isInitialized, Listening: $_isListening, Perm: $_permissionGranted");
      return;
    }
    _lastError = ''; // Limpa antes de cada tentativa de baixo nível

    try {
      bool validResultThisSession = false; // Para ajudar a decidir se "notListening" foi por falta de resultado

      await _speechToText.listen(
        onResult: (result) {
          print("SpeechService: STT onResult: '${result.recognizedWords}', final: ${result.finalResult}, conf: ${result.confidence}");
          if (result.recognizedWords.isNotEmpty) {
            validResultThisSession = true; // Marcamos que algo foi reconhecido
            onResult(result.recognizedWords); // Chama o callback do usuário

            if (result.finalResult) {
              // Se um resultado final e não vazio é obtido, consideramos a "tarefa" de escuta como concluída.
              // Paramos de tentar reiniciar automaticamente para esta sequência de comando.
              print("SpeechService: Resultado final recebido. Desativando reinício automático para esta sessão.");
              _resetAutoRestartState();
            }
          }
        },
        onSoundLevelChange: onSoundLevelChange,
        localeId: localeId ?? 'pt_BR',
        listenMode: stt.ListenMode.dictation, // Modo adequado para comandos mais longos
        cancelOnError: true, // Importante para o onError do initialize ser chamado em erros como no_match
        partialResults: true, // Receber resultados parciais pode ser útil
        listenFor: listenFor,
        pauseFor: pauseFor,
        // sampleRate: 44100, // Opcional, pode ou não melhorar
      );
      _isListening = true; // Define o estado APÓS a chamada bem-sucedida para listen
      print("SpeechService: STT.listen() chamado com sucesso, _isListening = true");
    } catch (e) {
      _lastError = "Exceção durante a chamada STT.listen: $e";
      print("SpeechService: $_lastError");
      _isListening = false;
      // Se a chamada listen() em si falhar (exceção aqui),
      // e o reinício automático estiver ativo, tenta reiniciar.
      if (_shouldAutoRestartOnNoMatch && _autoRestartAttempts < _maxAutoRestartAttempts) {
        print("SpeechService: Reiniciando escuta devido a exceção em _listenInternal. Tentativa: ${_autoRestartAttempts + 1}");
        _performAutoRestart();
      } else {
        _resetAutoRestartState();
      }
    }
  }

  Future<void> stop() async {
    print("SpeechService: Chamada de stop() pelo usuário.");
    // Quando o usuário chama stop, desativa qualquer reinício automático pendente.
    _resetAutoRestartState();
    try {
      await _speechToText.stop();
      _isListening = false; // Confirma que parou
      print("SpeechService: STT parado com sucesso via stop().");
    } catch (e) {
      _lastError = "Erro ao parar STT via stop(): $e";
      print("SpeechService: $_lastError");
      // Mesmo com erro, o estado de escuta provavelmente mudou.
      _isListening = _speechToText.isListening; // Atualiza com o estado real do plugin
    }
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  String get lastError => _lastError;

  // Adicionar uma propriedade `mounted` simulada ou remover checagens de `mounted`
  // já que este serviço não é um Widget. As checagens de mounted devem ser feitas
  // nas classes de State que usam este serviço antes de chamadas setState ou UI.
  // Para este exemplo, vou assumir que o contexto (se passado) é verificado pelo chamador.
  bool get mounted => true; // Placeholder - idealmente, não ter lógica de UI aqui.
}
