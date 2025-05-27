import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as AppSettingsPlugin;
import 'package:diacritic/diacritic.dart';
import 'package:vision_app_3d/service/speech_service.dart';
import 'package:vision_app_3d/service/tts_service.dart';
import 'package:vision_app_3d/service/vibration_service.dart';
import 'questions.dart';

// Importa a constante para sinalização
import 'package:vision_app_3d/screens/insect_list_screen.dart'; // Para POP_TO_INSECT_LIST_SIGNAL se definido lá, ou defina localmente.

// Sinalizador especial para ser retornado pela QuizScreen
// É melhor definir isso num local comum ou passá-lo, mas para este exemplo, vamos redefinir se necessário.
const String POP_TO_INSECT_LIST_SIGNAL = 'POP_TO_INSECT_LIST_AND_RESTART_AUDIO';

Future<void> openAppSettings() async {
  print("QuizScreen: Tentando abrir configurações do app...");
  await AppSettingsPlugin.openAppSettings();
}

class QuizScreen extends StatefulWidget {
  final String insectName;

  const QuizScreen({Key? key, required this.insectName}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();
  final VibrationService _vibrationService = VibrationService();

  int _score = 0;
  int _currentQuestionIndex = 0;
  late List<int?> _answers;
  int? _selectedAnswer;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _servicesInitialized = false;
  bool _canStartListeningAfterTTS = false;

  bool _isResultDialogOpen = false;
  late PageController _pageController;
  PageController? _resultPageController;
  bool _isResultPageNavigating = false;

  List<Question> _currentQuizQuestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("QuizScreen initState for: ${widget.insectName}");

    _currentQuizQuestions = Questions.questionsMap[widget.insectName] ?? [];
    print("QuizScreen initState: Número de perguntas para '${widget.insectName}': ${_currentQuizQuestions.length}");

    if (_currentQuizQuestions.isEmpty) {
      print("ALERTA: Nenhuma pergunta encontrada para ${widget.insectName}");
      _answers = [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ttsService.speak("Desculpe, não há perguntas disponíveis para este inseto.").then((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      });
    } else {
      _answers = List.filled(_currentQuizQuestions.length, null);
    }

    _pageController = PageController();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (!mounted) return;
    await _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (_servicesInitialized || !mounted) return;
    print("QuizScreen: Iniciando serviços...");
    _servicesInitialized = true;
    _canStartListeningAfterTTS = false;

    try {
      await _checkMicrophonePermission();
      await _configureTts();
      await _initializeSpeechService();

      if (_currentQuizQuestions.isNotEmpty) {
        _startQuiz();
      } else {
        print("QuizScreen: Sem perguntas para iniciar o quiz após inicialização dos serviços.");
      }
    } catch (e) {
      print("QuizScreen: Erro na inicialização dos serviços: $e");
      _servicesInitialized = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao iniciar Quiz: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _initializeSpeechService() async {
    if (!mounted) return;
    print("QuizScreen: Inicializando SpeechService...");
    bool initialized = await _speechService.initialize(context: context);
    if (!initialized && mounted) {
      print("QuizScreen: Falha ao inicializar SpeechService.");
      _canStartListeningAfterTTS = true;
      await _ttsService.speak("Serviço de comandos de voz não pôde ser iniciado.");
    } else if (initialized) {
      print("QuizScreen: SpeechService inicializado com sucesso.");
    }
  }

  void _startQuiz() {
    if (!mounted || _currentQuizQuestions.isEmpty) {
      print("QuizScreen: Não pode iniciar quiz, sem perguntas.");
      return;
    }
    print("QuizScreen: _startQuiz - Número de perguntas: ${_currentQuizQuestions.length}");
    _currentQuestionIndex = 0;
    _score = 0;
    _answers = List.filled(_currentQuizQuestions.length, null);
    _selectedAnswer = null;
    _isResultDialogOpen = false;

    if (_pageController.hasClients && _pageController.page?.round() != 0) {
      _pageController.jumpToPage(0);
    }

    print("QuizScreen: Iniciando Quiz. Falando primeira pergunta.");
    _speakCurrentQuestion();
  }

  Future<void> _checkMicrophonePermission() async {
    final status = await AppSettingsPlugin.Permission.microphone.status;
    if (!status.isGranted) {
      final result = await AppSettingsPlugin.Permission.microphone.request();
      if (!result.isGranted && mounted) {
        print("QuizScreen: Permissão de microfone negada");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissão de microfone necessária para responder por voz.'),
            action: SnackBarAction(label: 'Configurações', onPressed: openAppSettings),
          ),
        );
      }
    }
  }

  Future<void> _configureTts() async {
    print("QuizScreen: Configurando TTS...");
    await _ttsService.initialize(
      language: "pt-BR",
      speechRate: 0.6,
      volume: 1.0,
      onStart: () {
        if (mounted) setState(() => _isSpeaking = true);
      },
      onComplete: () async {
        if (!mounted) return;
        setState(() => _isSpeaking = false);
        print(
            "QuizScreen: TTS onComplete. _canStartListeningAfterTTS: $_canStartListeningAfterTTS, _isResultDialogOpen: $_isResultDialogOpen, _isResultPageNavigating: $_isResultPageNavigating");

        if (_isResultDialogOpen) {
          if (_canStartListeningAfterTTS) {
            _canStartListeningAfterTTS = false;
            print("QuizScreen: TTS onComplete (Result Dialog) - Iniciando escuta para comandos de resultado.");
            await Future.delayed(const Duration(milliseconds: 300));
            await _startListeningForResultCommands();
            if (mounted) {
              setState(() => _isResultPageNavigating = false);
              print("QuizScreen: TTS onComplete (Result Dialog) - _isResultPageNavigating resetado para false.");
            }
          } else {
            if (mounted && _isResultPageNavigating) {
              setState(() => _isResultPageNavigating = false);
              print(
                  "QuizScreen: TTS onComplete (Result Dialog) - _canStartListeningAfterTTS era false, mas _isResultPageNavigating resetado.");
            }
          }
        } else {
          if (_canStartListeningAfterTTS) {
            _canStartListeningAfterTTS = false;
            if (mounted &&
                _currentQuizQuestions.isNotEmpty &&
                _currentQuestionIndex < _currentQuizQuestions.length &&
                _answers[_currentQuestionIndex] == null &&
                !_isListening &&
                _speechService.isInitialized) {
              print("QuizScreen: TTS onComplete (Question) - Iniciando escuta para resposta da pergunta $_currentQuestionIndex.");
              await Future.delayed(const Duration(milliseconds: 300));
              await _startListening();
            } else {
              print(
                  "QuizScreen: TTS onComplete (Question) - Condições para escuta não atendidas. Q_Index: $_currentQuestionIndex, Answered: ${_answers.length > _currentQuestionIndex && _answers[_currentQuestionIndex] != null}, Listening: $_isListening, SpeechInit: ${_speechService.isInitialized}");
              if (mounted && !_speechService.isInitialized && !_isSpeaking) {
                _canStartListeningAfterTTS = true;
                await _ttsService.speak("Serviço de voz não está pronto para receber sua resposta.");
              }
            }
          }
        }
      },
      onError: (msg) {
        if (mounted) setState(() => _isSpeaking = false);
        print("QuizScreen: TTS onError: $msg");
        _canStartListeningAfterTTS = false;
        if (mounted && _isResultDialogOpen && _isResultPageNavigating) {
          setState(() => _isResultPageNavigating = false);
          print("QuizScreen: TTS onError (Result Dialog) - _isResultPageNavigating resetado.");
        }
      },
    );
  }

  Future<void> _speakCurrentQuestion() async {
    if (!mounted || _currentQuizQuestions.isEmpty || _currentQuestionIndex >= _currentQuizQuestions.length) {
      print(
          "QuizScreen: Não pode falar pergunta - índice inválido ($_currentQuestionIndex) ou sem perguntas (${_currentQuizQuestions.length}).");
      return;
    }

    final currentQuestion = _currentQuizQuestions[_currentQuestionIndex];
    String questionText = currentQuestion.question;
    List<String> options = currentQuestion.options;
    String ttsMessage = "Pergunta ${_currentQuestionIndex + 1}: $questionText. ";
    for (int i = 0; i < options.length; i++) {
      ttsMessage += "Opção ${i + 1}: ${options[i]}. ";
    }
    ttsMessage += "Fale o número da opção desejada.";

    print("QuizScreen: Falando pergunta ${_currentQuestionIndex + 1}");
    await _ttsService.stop();
    _canStartListeningAfterTTS = true;
    await _ttsService.speak(ttsMessage);
  }

  Future<void> _startListening() async {
    if (!mounted ||
        _isSpeaking ||
        _isListening ||
        !_speechService.isInitialized ||
        _isResultDialogOpen ||
        (_currentQuizQuestions.isNotEmpty &&
            _currentQuestionIndex < _currentQuizQuestions.length &&
            _answers[_currentQuestionIndex] != null)) {
      print(
          "QuizScreen: Não pode iniciar escuta (geral): s:$_isSpeaking, l:$_isListening, speechInit:${_speechService.isInitialized}, resultOpen:$_isResultDialogOpen, answered:${_answers.length > _currentQuestionIndex && _answers[_currentQuestionIndex] != null}");
      return;
    }

    print("QuizScreen: Iniciando escuta para resposta da pergunta $_currentQuestionIndex...");
    if (mounted) setState(() => _isListening = true);
    try {
      await _speechService.listen(
        onResult: (command) {
          if (mounted && command.trim().isNotEmpty) {
            _handleVoiceCommand(command);
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 7),
        autoRestartOnNoMatch: true,
        onSoundLevelChange: (level) {},
      );
    } catch (e) {
      print("QuizScreen: Erro ao iniciar escuta: $e");
      if (mounted) {
        setState(() => _isListening = false);
        _canStartListeningAfterTTS = true;
        await _restartListening(isForResultDialog: false);
      }
    }
  }

  Future<void> _restartListening({required bool isForResultDialog, int delayMs = 1000}) async {
    if (!mounted) return;
    print("QuizScreen: Tentando reiniciar escuta em $delayMs ms. Para diálogo: $isForResultDialog");

    if (_isListening) {
      await _speechService.stop();
      if (mounted) setState(() => _isListening = false);
    }
    if (_isSpeaking) {
      print("QuizScreen: Não pode reiniciar escuta: TTS falando.");
      return;
    }
    await Future.delayed(Duration(milliseconds: delayMs));
    if (mounted && !_isSpeaking && !_isListening) {
      if (isForResultDialog && _isResultDialogOpen) {
        print("QuizScreen: Reiniciando escuta para o diálogo de resultados.");
        _startListeningForResultCommands();
      } else if (!isForResultDialog &&
          !_isResultDialogOpen &&
          (_currentQuizQuestions.isNotEmpty &&
              _currentQuestionIndex < _currentQuizQuestions.length &&
              _answers[_currentQuestionIndex] == null)) {
        print("QuizScreen: Reiniciando escuta para perguntas.");
        _startListening();
      } else {
        print(
            "QuizScreen: Condições de reinício de escuta não correspondentes ou pergunta já respondida. CurrentIndex: $_currentQuestionIndex, AnswersLength: ${_answers.length}");
      }
    }
  }

  void _handleVoiceCommand(String command) {
    if (!mounted || _isResultDialogOpen) return;

    if (_currentQuestionIndex >= _currentQuizQuestions.length) {
      print(
          "QuizScreen: _handleVoiceCommand - _currentQuestionIndex fora dos limites. Index: $_currentQuestionIndex, Length: ${_currentQuizQuestions.length}");
      return;
    }
    final currentQuestion = _currentQuizQuestions[_currentQuestionIndex];

    _speechService.stop();
    if (mounted) setState(() => _isListening = false);

    final String lowerCommand = command.toLowerCase().trim();
    print("QuizScreen: Recebeu comando bruto: '$command', normalizado: '$lowerCommand'");

    final optionMatch = currentQuestion.matchVoiceCommand(lowerCommand);
    print("QuizScreen: Resultado de matchVoiceCommand: $optionMatch");

    if (optionMatch['recognized'] == true) {
      final int selectedOption = optionMatch['value'] as int;
      print("QuizScreen: Opção por voz ${selectedOption + 1} RECONHECIDA para Q${_currentQuestionIndex + 1}");
      _vibrationService.vibrate();

      if (mounted) {
        setState(() {
          _answers[_currentQuestionIndex] = selectedOption;
          _selectedAnswer = selectedOption;
        });
      }
      _canStartListeningAfterTTS = true;
      _ttsService.speak("Opção ${selectedOption + 1} selecionada.").then((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;

            print(
                "QuizScreen: Voice Answer - Processando após TTS. CurrentIndex: $_currentQuestionIndex, TotalQuestions: ${_currentQuizQuestions.length}");

            if (_currentQuestionIndex < _currentQuizQuestions.length - 1) {
              print("QuizScreen: Voice Answer - Avançando para próxima pergunta.");
              _processAnswerAndAdvance();
            } else {
              print(
                  "QuizScreen: Voice Answer - Última pergunta respondida (Q${_currentQuestionIndex + 1}). Mostrando resultados.");
              _processAnswerAndShowResults();
            }
          });
        }
      });
      return;
    }

    final navigationCommand = Question.matchNavigationCommand(lowerCommand);
    print("QuizScreen: Resultado de matchNavigationCommand: $navigationCommand");

    if (navigationCommand['recognized'] == true) {
      _canStartListeningAfterTTS = true;
      print(
          "QuizScreen: Comando de navegação por voz '${navigationCommand['value']}' reconhecido para Q${_currentQuestionIndex + 1}.");
      switch (navigationCommand['value']) {
        case 'próxima pergunta':
          if (_answers[_currentQuestionIndex] != null) {
            if (_currentQuestionIndex < _currentQuizQuestions.length - 1) {
              _nextQuestion();
            } else {
              _ttsService.speak("Você já está na última pergunta. Diga finalizar para ver os resultados.");
            }
          } else {
            _ttsService.speak("Por favor, responda a pergunta atual antes de avançar.");
          }
          break;
        case 'voltar pergunta':
          _previousQuestion();
          break;
        case 'finalizar':
          print("QuizScreen: Comando de voz 'finalizar'.");
          if (_answers.every((answer) => answer != null)) {
            _showResultDialog();
          } else {
            _ttsService.speak("Responda todas as perguntas antes de finalizar.");
          }
          break;
      }
      return;
    }

    print("QuizScreen: Comando de voz '$lowerCommand' não reconhecido como opção ou navegação para Q${_currentQuestionIndex + 1}.");
    _canStartListeningAfterTTS = true;
    _ttsService.speak("Não entendi sua resposta. Por favor, diga o número da opção.");
  }

  void _processAnswerAndAdvance() {
    if (!mounted || _answers[_currentQuestionIndex] == null) return;
    print("QuizScreen: _processAnswerAndAdvance - Avançando da pergunta ${_currentQuestionIndex + 1}.");
    _nextQuestion();
  }

  void _processAnswerAndShowResults() {
    if (!mounted || _answers[_currentQuestionIndex] == null) return;
    print("QuizScreen: _processAnswerAndShowResults - Preparando para mostrar resultados após Q${_currentQuestionIndex + 1}.");
    _showResultDialog();
  }

  void _nextQuestion() {
    if (!mounted) return;

    if (_answers[_currentQuestionIndex] == null) {
      print("QuizScreen: _nextQuestion - Tentando avançar, mas pergunta atual ($_currentQuestionIndex) não respondida.");
      _canStartListeningAfterTTS = true;
      _ttsService.speak("Por favor, responda a pergunta atual antes de avançar.");
      return;
    }

    if (_currentQuestionIndex < _currentQuizQuestions.length - 1) {
      _vibrationService.vibrate();
      print("QuizScreen: _nextQuestion - Avançando do índice $_currentQuestionIndex para o próximo.");
      if (mounted && _pageController.hasClients) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    } else {
      print("QuizScreen: _nextQuestion - Chamado na última pergunta ($_currentQuestionIndex). Deveria mostrar resultados.");
      _showResultDialog();
    }
  }

  void _previousQuestion() {
    if (!mounted || _currentQuestionIndex <= 0) return;
    _vibrationService.vibrate();
    print("QuizScreen: _previousQuestion - Voltando do índice $_currentQuestionIndex para o anterior.");
    if (mounted && _pageController.hasClients) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  void _showResultDialog() {
    if (!mounted || _isResultDialogOpen) {
      print("QuizScreen: _showResultDialog - Já aberto ou não montado. Retornando.");
      return;
    }
    _stopAllServices();

    _score = 0;
    for (int i = 0; i < _currentQuizQuestions.length; i++) {
      if (_answers[i] != null && _answers[i] == _currentQuizQuestions[i].correctIndex) {
        _score++;
      }
    }
    print("QuizScreen: Mostrando diálogo de resultados. Pontuação FINAL RECALCULADA: $_score / ${_answers.length}");

    setState(() => _isResultDialogOpen = true);
    _resultPageController = PageController();

    _canStartListeningAfterTTS = true;
    _ttsService.speak("Quiz finalizado! Você acertou $_score de ${_answers.length} perguntas. Veja a correção.").then((_) {
      if (mounted && _isResultDialogOpen) {
        _speakResultPage(0);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          print("QuizScreen: WillPopScope no diálogo de resultados - chamando _closeResultDialogButtonPressed");
          _closeResultDialogButtonPressed();
          return false;
        },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: SizedBox(
            height: 450,
            width: double.maxFinite,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Resultado: $_score / ${_answers.length} corretas",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _resultPageController,
                    onPageChanged: (index) {
                      _ttsService.stop();
                      _canStartListeningAfterTTS = true;
                      _speakResultPage(index);
                    },
                    itemCount: _currentQuizQuestions.length,
                    itemBuilder: (context, index) {
                      final question = _currentQuizQuestions[index];
                      final userAnswer = _answers[index];
                      final correctAnswer = question.correctIndex;
                      final bool isCorrect = userAnswer == correctAnswer;
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Pergunta ${index + 1}:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(question.question, style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 16),
                              Text('Sua Resposta:',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: isCorrect ? Colors.green : Colors.red)),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isCorrect ? Colors.green : Colors.red, width: 1),
                                ),
                                child: Text(userAnswer != null ? question.options[userAnswer] : "Não respondida",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCorrect ? Colors.green[800] : Colors.red[800])),
                              ),
                              if (!isCorrect) ...[
                                const SizedBox(height: 8),
                                const Text('Resposta Correta:',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green, width: 1),
                                  ),
                                  child: Text(question.options[correctAnswer],
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800])),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: (_resultPageController?.hasClients ?? false) && (_resultPageController!.page?.round() ?? 0) > 0
                            ? () {
                                _vibrationService.vibrate();
                                if (mounted) setState(() => _isResultPageNavigating = true);
                                _resultPageController!
                                    .previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                              }
                            : null,
                      ),
                      ElevatedButton(
                        onPressed: _closeResultDialogButtonPressed,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAB08A)),
                        child: const Text('Fechar Correção', style: TextStyle(color: Colors.black)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: (_resultPageController?.hasClients ?? false) &&
                                ((_resultPageController!.page?.round() ?? 0) < _currentQuizQuestions.length - 1)
                            ? () {
                                _vibrationService.vibrate();
                                if (mounted) setState(() => _isResultPageNavigating = true);
                                _resultPageController!
                                    .nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (_isResultDialogOpen && mounted) {
        _closeResultDialogCleanup(popQuizScreen: true);
      }
    });
  }

  void _closeResultDialogCleanup({bool popQuizScreen = true}) {
    print("QuizScreen: _closeResultDialogCleanup - popQuizScreen: $popQuizScreen");
    if (mounted) {
      setState(() {
        _isResultDialogOpen = false;
        _isResultPageNavigating = false;
      });
    }
    _resultPageController?.dispose();
    _resultPageController = null;

    if (popQuizScreen && mounted && Navigator.canPop(context)) {
      print("QuizScreen: Saindo da tela de Quiz (voltando para tela anterior).");
      Navigator.of(context).pop();
    } else if (popQuizScreen && mounted) {
      print("QuizScreen: Não pode fazer pop da QuizScreen (talvez seja a raiz).");
    }
  }

  // Chamado pelo botão "Fechar Correção" no diálogo
  void _closeResultDialogButtonPressed() {
    if (!mounted) return;
    print("QuizScreen: Botão 'Fechar Correção' pressionado.");
    _vibrationService.vibrate();
    _stopAllServices();

    if (_isResultDialogOpen && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      // O .then() do showDialog chamará _closeResultDialogCleanup,
      // que fará o pop da QuizScreen, retornando para InsectDetailsScreen.
    } else if (mounted) {
      _closeResultDialogCleanup(popQuizScreen: true);
    }
  }

  // Chamado pelo comando de voz "fechar correção"
  Future<void> _closeResultDialogAndGoToList() async {
    print("QuizScreen: Comando de voz 'fechar correção' - preparando para voltar à lista de insetos.");
    await _stopAllServices();
    if (mounted) {
      // Primeiro, fecha o diálogo de resultados, se estiver aberto.
      if (_isResultDialogOpen && Navigator.of(context, rootNavigator: true).canPop()) {
        print("QuizScreen: Fechando diálogo de resultados...");
        Navigator.of(context, rootNavigator: true).pop();
      }
      // Em seguida, faz pop da QuizScreen, retornando o sinalizador.
      if (mounted && Navigator.canPop(context)) {
        print("QuizScreen: Fazendo Pop da QuizScreen com sinalizador: $POP_TO_INSECT_LIST_SIGNAL");
        Navigator.of(context).pop(POP_TO_INSECT_LIST_SIGNAL);
      } else if (mounted) {
        // Se não puder fazer pop (ex: QuizScreen é a primeira tela), navega diretamente para a lista.
        // Isto é um fallback e pode não ser o comportamento ideal em todos os cenários.
        print("QuizScreen: Não foi possível fazer pop da QuizScreen. Navegando diretamente para InsectListScreen.");
        // Para garantir que volte para a lista e ela reinicie, usamos pushAndRemoveUntil
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => const InsectListScreen(),
                settings: const RouteSettings(name: '/insectList')), // Dê um nome à rota se precisar identificá-la
            (route) => route.isFirst); // Remove todas as rotas até a primeira (que geralmente é a home ou a lista)
        // Se a InsectListScreen não for a primeira, ajuste o predicado de remoção.
        // Ou, se a InsectListScreen sempre deve ser a base após este comando:
        // (route) => route.settings.name == '/insectList' || route.isFirst (se InsectList for a primeira)
        // Ou, mais simples se você sabe que a lista é a raiz:
        // (route) => false (remove tudo e push a nova) - mas isso perde o estado da HomePage se ela for a raiz.
        // A melhor abordagem depende da sua estrutura de navegação global.
        // Para o seu pedido, voltar para a lista e ela reiniciar,
        // Navigator.of(context).pop(POP_TO_INSECT_LIST_SIGNAL) é o ideal se a pilha estiver correta.
        // O fallback abaixo é mais agressivo.
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const InsectListScreen()),
        //   (Route<dynamic> route) => false, // Remove todas as rotas anteriores
        // );
      }
    }
  }

  Future<void> _speakResultPage(int index) async {
    if (!mounted || !_isResultDialogOpen || index < 0 || index >= _currentQuizQuestions.length) {
      print("QuizScreen: Condições não atendidas para falar a página de resultado $index.");
      if (mounted && _isResultDialogOpen && _isResultPageNavigating) {
        setState(() => _isResultPageNavigating = false);
        print("QuizScreen: _speakResultPage - _isResultPageNavigating resetado (condição não atendida).");
      }
      return;
    }
    print("QuizScreen: Falando resultado da pergunta ${index + 1}.");

    await _ttsService.stop();
    _canStartListeningAfterTTS = true;

    final question = _currentQuizQuestions[index];
    final userAnswerIndex = _answers[index];
    final correctAnswerIndex = question.correctIndex;
    final totalPages = _currentQuizQuestions.length;

    String message = "Correção da pergunta ${index + 1} de $totalPages: ${question.question}. ";
    if (userAnswerIndex != null) {
      message += "Sua resposta foi ${question.options[userAnswerIndex]}. ";
      if (userAnswerIndex == correctAnswerIndex) {
        message += "Resposta correta! ";
      } else {
        message += "Resposta incorreta. A resposta correta é: ${question.options[correctAnswerIndex]}. ";
      }
    } else {
      message += "Você não respondeu esta pergunta. A resposta correta é: ${question.options[correctAnswerIndex]}.";
    }

    if (totalPages > 1) {
      message += " Diga 'próxima correção', 'voltar pergunta', ou 'fechar correção'.";
    } else {
      message += " Diga 'fechar correção'.";
    }

    await _ttsService.speak(message);
  }

  Future<void> _startListeningForResultCommands() async {
    if (!mounted || _isSpeaking || _isListening || !_speechService.isInitialized || !_isResultDialogOpen) {
      print(
          "QuizScreen: Não pode iniciar escuta (resultados): s:$_isSpeaking, l:$_isListening, speechInit:${_speechService.isInitialized}, dialogOpen:$_isResultDialogOpen");
      if (mounted && _isResultDialogOpen && _isResultPageNavigating) {
        setState(() => _isResultPageNavigating = false);
        print(
            "QuizScreen: _startListeningForResultCommands - _isResultPageNavigating resetado (condição não atendida para escuta).");
      }
      return;
    }
    print("QuizScreen: Iniciando escuta para comandos do diálogo de resultados...");
    if (mounted) setState(() => _isListening = true);
    try {
      await _speechService.listen(
        onResult: (command) {
          if (mounted && command.trim().isNotEmpty) {
            _handleResultDialogCommand(command);
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        autoRestartOnNoMatch: true,
      );
    } catch (e) {
      print("QuizScreen: Erro ao iniciar escuta para resultados: $e");
      if (mounted) {
        setState(() => _isListening = false);
        if (_isResultPageNavigating) setState(() => _isResultPageNavigating = false);
        _canStartListeningAfterTTS = true;
        await _restartListening(isForResultDialog: true, delayMs: 500);
      }
    }
  }

  void _handleResultDialogCommand(String command) async {
    if (!mounted || !_isResultDialogOpen) return;
    if (_isResultPageNavigating) {
      print("QuizScreen: ResultDialog - Navegação já em progresso. Ignorando comando: $command");
      return;
    }

    _speechService.stop();
    if (mounted) setState(() => _isListening = false);
    _ttsService.stop();
    if (mounted) setState(() => _isSpeaking = false);

    final lowerCommand = command.toLowerCase().trim();
    print("QuizScreen: Comando no diálogo de resultado: '$lowerCommand'");

    final currentPage = _resultPageController?.page?.round() ?? 0;
    final totalPages = _currentQuizQuestions.length;

    if (_matchesCommandForResultDialog(lowerCommand, 'fechar correcao')) {
      await _closeResultDialogAndGoToList();
    } else if (_matchesCommandForResultDialog(lowerCommand, 'voltar pergunta')) {
      if (currentPage > 0 && _resultPageController != null && _resultPageController!.hasClients) {
        print("QuizScreen: ResultDialog - Comando 'voltar pergunta'. Setando lock de navegação.");
        setState(() => _isResultPageNavigating = true);
        await _resultPageController!.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        _canStartListeningAfterTTS = true;
        await _ttsService.speak("Você já está na primeira pergunta da correção.");
        if (mounted) setState(() => _isResultPageNavigating = false);
      }
    } else if (_matchesCommandForResultDialog(lowerCommand, 'proxima correcao')) {
      if (currentPage < totalPages - 1 && _resultPageController != null && _resultPageController!.hasClients) {
        print("QuizScreen: ResultDialog - Comando 'próxima correção'. Setando lock de navegação.");
        setState(() => _isResultPageNavigating = true);
        await _resultPageController!.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        _canStartListeningAfterTTS = true;
        await _ttsService.speak("Você já está na última pergunta da correção.");
        if (mounted) setState(() => _isResultPageNavigating = false);
      }
    } else {
      _canStartListeningAfterTTS = true;
      await _ttsService.speak("Comando não reconhecido. Diga 'próxima correção', 'voltar pergunta' ou 'fechar correção'.");
      if (mounted) setState(() => _isResultPageNavigating = false);
    }
  }

  bool _matchesCommandForResultDialog(String input, String commandKey) {
    final variations = <String, Set<String>>{
      'fechar correcao': {
        'fechar correção',
        'fechar correcao',
        'fechar',
        'sair',
        'terminar correção',
        'finalizar correção',
        'fechar resultado',
        'lista de insetos',
        'ir para lista',
        'voltar para lista'
      },
      'voltar pergunta': {'voltar pergunta', 'anterior', 'voltar correção', 'correção anterior', 'pergunta anterior'},
      'proxima correcao': {'próxima correção', 'proxima correcao', 'seguinte', 'avançar correção', 'próxima', 'próxima pergunta'},
    };
    String normalize(String text) => removeDiacritics(text).toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final normalizedInput = normalize(input);
    bool matched = variations[commandKey]?.any((variant) => normalizedInput.contains(normalize(variant))) ?? false;
    print("QuizScreen (Result Dialog): Match for '$commandKey' with input '$input' (normalized '$normalizedInput'): $matched");
    return matched;
  }

  Future<void> _stopAllServices() async {
    print("QuizScreen: Parando todos os serviços...");
    _canStartListeningAfterTTS = false;
    await _ttsService.stop();
    await _speechService.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isListening = false;
        _isResultPageNavigating = false;
      });
    }
  }

  @override
  void dispose() {
    print("QuizScreen: Dispose");
    WidgetsBinding.instance.removeObserver(this);
    _stopAllServices();
    _pageController.dispose();
    _resultPageController?.dispose();
    _servicesInitialized = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("QuizScreen: AppLifecycleState: $state");
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted && !_servicesInitialized) {
          print("QuizScreen: App resumido, _servicesInitialized é false. Chamando _initializePage()");
          _initializePage();
        } else if (mounted && _servicesInitialized && !_isSpeaking && !_isListening) {
          if (_isResultDialogOpen && !_isResultPageNavigating) {
            print("QuizScreen: App resumido. Reiniciando escuta para diálogo de resultados.");
            _canStartListeningAfterTTS = true;
            _restartListening(isForResultDialog: true, delayMs: 500);
          } else if (!_isResultDialogOpen &&
              (_currentQuizQuestions.isNotEmpty &&
                  _currentQuestionIndex < _currentQuizQuestions.length &&
                  _answers[_currentQuestionIndex] == null)) {
            print("QuizScreen: App resumido. Reiniciando escuta para perguntas.");
            _canStartListeningAfterTTS = true;
            _restartListening(isForResultDialog: false, delayMs: 500);
          }
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print("QuizScreen: App pausado/inativo.");
        _stopAllServices();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz sobre ${widget.insectName}'),
          backgroundColor: const Color(0xFFEAB08A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
            onPressed: () {
              _vibrationService.vibrate();
              _stopAllServices();
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(child: Text('Nenhuma pergunta disponível para este inseto.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        title: Text('Quiz: ${widget.insectName}'),
        backgroundColor: const Color(0xFFEAB08A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrationService.vibrate();
            _stopAllServices();
            Navigator.pop(context);
          },
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _currentQuizQuestions.length,
        onPageChanged: (index) {
          if (mounted) {
            print("QuizScreen: PageView onPageChanged para índice $index");
            setState(() {
              _currentQuestionIndex = index;
              _selectedAnswer = _answers[index];
            });
            _ttsService.stop();
            _speechService.stop();
            if (mounted) setState(() => _isListening = false);
            _speakCurrentQuestion();
          }
        },
        itemBuilder: (context, index) {
          if (index >= _currentQuizQuestions.length) {
            print(
                "QuizScreen: itemBuilder - index $index fora dos limites (${_currentQuizQuestions.length}). Retornando Container vazio.");
            return Container();
          }
          final currentQuestion = _currentQuizQuestions[index];
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pergunta ${index + 1}/${_currentQuizQuestions.length}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))
                  ]),
                  child: Text(currentQuestion.question, style: const TextStyle(fontSize: 22, color: Colors.black, height: 1.4)),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, optionIndex) {
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: RadioListTile<int>(
                          title: Text(currentQuestion.options[optionIndex], style: const TextStyle(fontSize: 18)),
                          value: optionIndex,
                          groupValue: _answers[index],
                          activeColor: const Color(0xFFD9804E),
                          onChanged: (_answers[index] != null)
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  _vibrationService.vibrate();
                                  setState(() {
                                    _answers[index] = value;
                                    _selectedAnswer = value;
                                  });
                                  _canStartListeningAfterTTS = true;
                                  _ttsService.speak("Opção ${value + 1} selecionada.").then((_) {
                                    if (mounted) {
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        if (!mounted) return;
                                        print(
                                            "QuizScreen: Tap Answer - Processando. CurrentIndex (do PageView): $index, _currentQuestionIndex (do estado): $_currentQuestionIndex");
                                        if (index < _currentQuizQuestions.length - 1) {
                                          _processAnswerAndAdvance();
                                        } else {
                                          print(
                                              "QuizScreen: Tap Answer - Última pergunta (idx $index) respondida. Mostrando resultados.");
                                          _processAnswerAndShowResults();
                                        }
                                      });
                                    }
                                  });
                                },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                      onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _currentQuestionIndex > 0 ? const Color(0xFFEAB08A) : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(_currentQuestionIndex == _currentQuizQuestions.length - 1 ? 'Ver Resultado' : 'Próxima'),
                      onPressed: _answers[_currentQuestionIndex] != null
                          ? () {
                              print(
                                  "QuizScreen: Botão Próxima/Resultado - CurrentIndex: $_currentQuestionIndex, TotalQuestions: ${_currentQuizQuestions.length}");
                              if (_currentQuestionIndex == _currentQuizQuestions.length - 1) {
                                print("QuizScreen: Botão Próxima/Resultado - Última pergunta. Mostrando resultados.");
                                _processAnswerAndShowResults();
                              } else {
                                _processAnswerAndAdvance();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _answers[_currentQuestionIndex] != null ? const Color(0xFFEAB08A) : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
