import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart'; // Para openAppSettings
import 'package:vision_app_3d/screens/home_page.dart';
import 'package:vision_app_3d/service/speech_service.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart'; // Importado
import 'insect_details_screen.dart';
import 'package:vision_app_3d/screens/insect.dart'; // Para Insect e insectData

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController();
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();
  final VibrationService _vibrationService = VibrationService(); // Adicionado

  bool _isScanCompleted = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (!mounted) return;
    // A inicialização dos serviços de voz será chamada pelo didChangeAppLifecycleState
    // ou por um addPostFrameCallback para garantir que o contexto está pronto.
    // E também aqui para o primeiro carregamento.
    await _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (_servicesInitialized || !mounted) return;
    print("QRViewExample: Iniciando serviços...");
    _servicesInitialized = true;

    try {
      await _checkPermissions(); // Checar permissões de microfone e câmera
      await _configureTts();
      await _initSpeechService();
      await _speakInstructions(); // A escuta começará após esta fala, via onComplete do TTS
    } catch (e) {
      print("QRViewExample: Erro na inicialização dos serviços: $e");
      _servicesInitialized = false; // Permite nova tentativa
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao iniciar serviços: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _checkPermissions() async {
    // Permissão da Câmera (para MobileScanner)
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }
    if (!cameraStatus.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de câmera necessária para escanear QR Codes.'),
          action: SnackBarAction(label: 'Configurações', onPressed: openAppSettings),
        ),
      );
    }

    // Permissão do Microfone (para SpeechService)
    // O SpeechService.initialize também faz uma checagem, mas podemos fazer uma aqui também.
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    if (!micStatus.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de microfone necessária para comandos de voz.'),
          action: SnackBarAction(label: 'Configurações', onPressed: openAppSettings),
        ),
      );
    }
  }

  @override
  void dispose() {
    print("QRViewExample dispose");
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose(); // Dispose do MobileScannerController
    _stopAllServices();
    super.dispose();
  }

  Future<void> _stopAllServices() async {
    print("QRViewExample: Parando todos os serviços...");
    await _ttsService.stop();
    await _speechService.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isListening = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // super.didChangeAppLifecycleState(state); // Não é necessário para WidgetsBindingObserver
    print("QRViewExample AppLifecycleState: $state");
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_servicesInitialized) {
          print("QRViewExample resumido, inicializando serviços.");
          _initializeServices();
        } else if (mounted && _servicesInitialized && !_isListening && !_isSpeaking) {
          // Se os serviços estavam ok, mas a escuta parou
          print("QRViewExample resumido, reiniciando escuta.");
          _restartListening(delayMs: 500);
        }
        // O MobileScanner widget geralmente lida com o reinício da câmera automaticamente
        // quando o app é resumido e o widget está visível.
        // Se você precisar de controle explícito e tiver certeza de que o controller não foi disposed,
        // você poderia chamar _scannerController.start() aqui, mas geralmente não é necessário.
        // Ex: if (!_scannerController.isDisposed) { _scannerController.start(); }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive: // Tratar inactive também, pois pode preceder paused
        print("QRViewExample pausado/inativo, parando serviços.");
        _stopAllServices();
        // O MobileScanner widget também geralmente lida com a parada da câmera.
        // Se precisar de controle explícito:
        // if (!_scannerController.isDisposed) { _scannerController.stop(); }
        break;
      case AppLifecycleState.detached:
        // Não fazemos nada aqui, pois o dispose cuidará disso
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<void> _configureTts() async {
    print("QRViewExample: Configurando TTS...");
    await _ttsService.initialize(
      language: "pt-BR",
      speechRate: 0.6,
      // Ajustado para corresponder ao original, mas 0.5 é o padrão do TtsService
      onStart: () {
        if (mounted) setState(() => _isSpeaking = true);
      },
      onComplete: () async {
        if (!mounted) return;
        setState(() => _isSpeaking = false);
        print("QRViewExample: TTS onComplete.");
        // Só inicia a escuta se não estivermos no meio de um scan ou outra operação
        if (mounted && !_isListening && !_isScanCompleted) {
          await Future.delayed(const Duration(milliseconds: 300));
          _startListening();
        }
      },
      onError: (msg) {
        if (!mounted) return;
        setState(() => _isSpeaking = false);
        print("QRViewExample: TTS onError: $msg");
        if (mounted && !_isListening && !_isScanCompleted) {
          _startListening(); // Tenta iniciar a escuta mesmo se o TTS falhar
        }
      },
    );
  }

  Future<void> _speakInstructions() async {
    if (!mounted) return;
    print("QRViewExample: Falando instruções...");
    await _ttsService.speak(
      "Aponte o celular para o QR Code. Coloque o QR Code na área demarcada. "
      "A leitura será feita automaticamente. "
      "Diga 'voltar' para retornar.",
    );
    // A escuta será iniciada pelo onComplete do TTS
  }

  Future<void> _initSpeechService() async {
    if (!mounted) return;
    print("QRViewExample: Inicializando SpeechService...");
    bool initialized = await _speechService.initialize(context: context);
    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Falha ao inicializar reconhecimento de voz")),
      );
    }
  }

  Future<void> _startListening() async {
    if (!mounted || _isSpeaking || _isListening || !_speechService.isInitialized || _isScanCompleted) {
      print(
          "QRViewExample: Não pode iniciar escuta. s:$_isSpeaking, l:$_isListening, init:${_speechService.isInitialized}, scan:$_isScanCompleted");
      return;
    }

    try {
      print("QRViewExample: Iniciando escuta...");
      // await _speechService.stop(); // Não é necessário se _isListening já protege
      // await Future.delayed(const Duration(milliseconds: 100)); // Menor delay

      await _speechService.listen(
        onResult: (command) {
          if (command.isNotEmpty) _handleVoiceCommand(command);
        },
        localeId: "pt-BR",
        listenFor: const Duration(seconds: 60),
        // Reduzido, mas ainda longo
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) {
          // if (level > 0) print("Nível de som: $level dB"); // Log menos verboso
        },
      );
      if (mounted) setState(() => _isListening = true);
    } catch (e) {
      print("QRViewExample: Erro ao iniciar escuta: $e");
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _restartListening({int delayMs = 1000}) async {
    if (!mounted) return;
    print("QRViewExample: Tentando reiniciar escuta em $delayMs ms...");

    if (_isListening) {
      await _speechService.stop();
      if (mounted) setState(() => _isListening = false);
    }
    if (_isSpeaking || _isScanCompleted) {
      print("QRViewExample: Não pode reiniciar escuta: falando ou scan completo.");
      return;
    }

    await Future.delayed(Duration(milliseconds: delayMs));

    if (mounted && !_isSpeaking && !_isListening && !_isScanCompleted) {
      print("QRViewExample: Reiniciando escuta agora...");
      await _startListening();
    } else {
      print("QRViewExample: Condições para reiniciar escuta não atendidas após delay.");
    }
  }

  void _handleVoiceCommand(String command) {
    if (!mounted) return;
    final lowerCaseCommand = command.toLowerCase().trim();
    print("QRViewExample: Comando recebido: $lowerCaseCommand");

    if (_matchesCommand(lowerCaseCommand, 'voltar')) {
      _navigateBackToHome();
    } else {
      // Opcional: Feedback para comando não reconhecido
      // _ttsService.speak("Comando não reconhecido. Diga 'voltar'.");
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = {
      'voltar': [
        'voltar', 'votar', 'votah', 'voltah', 'volta', // Adicionado 'votah', 'voltah'
        'retornar', 'retorna', 'voltar para trás', 'vai voltar',
        'ir para trás', 'voltar menu', 'voltar início',
      ],
    };
    bool matched = variations[command]?.any((variant) => input.contains(variant)) ?? false;
    if (matched) print("Comando '$input' corresponde a '$command'");
    return matched;
  }

  void _navigateBackToHome() {
    if (!mounted) return;
    print("QRViewExample: Navegando de volta para Home.");
    _stopAllServices(); // Para tudo antes de navegar
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _onScanDetected(BarcodeCapture barcodeCapture) {
    if (!mounted || _isScanCompleted) return;

    final String code = barcodeCapture.barcodes.first.rawValue ?? '';
    if (code.isEmpty) {
      print("QR Code vazio detectado.");
      return;
    }

    print('QRViewExample: Código escaneado: $code');
    _vibrationService.vibrate(duration: 200); // Vibrar ao detectar

    // Parar escuta de voz e TTS para não interferir
    _stopAllServices();

    if (mounted) setState(() => _isScanCompleted = true);

    // Verificar se o código do QR code corresponde a um inseto conhecido
    // Este é um PONTO CRÍTICO: 'insectData' precisa estar definido e populado.
    // Por exemplo, em 'insect.dart':
    // final Map<String, Insect> insectData = {
    //   'qr_abelha': Insect(name: 'Abelha', videoPath: 'assets/videos/abelha.mp4', description: 'Descrição da abelha...', /* ... */),
    //   // ... outros insetos
    // };
    if (insectData.containsKey(code)) {
      final insect = insectData[code]!;
      print("QRViewExample: Inseto '${insect.name}' encontrado. Navegando para detalhes...");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InsectDetailsScreen(insect: insect),
        ),
      ).then((_) {
        // Quando retornar da tela de detalhes
        print("QRViewExample: Retornou da InsectDetailsScreen.");
        if (mounted) {
          setState(() => _isScanCompleted = false); // Permitir novo scan
          _servicesInitialized = false; // Forçar reinicialização dos serviços para pegar o contexto certo
          _initializeServices(); // Reinicia instruções e escuta
        }
      });
    } else {
      print("QRViewExample: QR Code não reconhecido: $code");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code não reconhecido: $code')),
        );
        // Após um scan não reconhecido, permitir novo scan e reiniciar a escuta
        setState(() => _isScanCompleted = false);
        _restartListening(delayMs: 1000); // Reinicia a escuta após um tempo
      }
    }
  }

  void closeScreen() {
    _isScanCompleted = false;
    _ttsService.stop(); // Usa o método stop do TtsService
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text(
          'Escaneie o QR Code',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            _navigateBackToHome(); // Usar o método que para os serviços
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1, // Ajustado flex
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Aponte a câmera para o QR Code", // Simplificado
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "A leitura será feita automaticamente",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3, // Ajustado flex
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7, // Responsivo
                height: MediaQuery.of(context).size.width * 0.7, // Responsivo
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  // Para aplicar o borderRadius ao MobileScanner
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onScanDetected, // Usar o método refatorado
                        // Opções adicionais do MobileScanner podem ser configuradas aqui
                        // Ex: allowDuplicates: false, (padrão é false)
                      ),
                      // Container para a borda de marcação (sobre o scanner)
                      Container(
                        width: double.infinity, // Ocupa toda a largura do ClipRRect
                        height: double.infinity, // Ocupa toda a altura do ClipRRect
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade300, width: 5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1, // Ajustado flex
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "Developed by VisionApp Group", // Exemplo
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
