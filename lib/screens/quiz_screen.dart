import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:diacritic/diacritic.dart';
import 'questions.dart';
import 'package:vision_app_3d/service/speechService.dart';
import 'package:vibration/vibration.dart';

class QuizScreen extends StatefulWidget {
  final String insectName;

  const QuizScreen({Key? key, required this.insectName}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _score = 0;
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  List<int?> _answers = List.filled(5, null);
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isResultDialogOpen = false;
  late PageController _pageController;
  PageController? _resultPageController;
  bool _inResultMode = false;
  bool _isSpeaking = false;
  bool _isReadyToListen = false;

  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    if (Questions.questionsMap[widget.insectName] == null || Questions.questionsMap[widget.insectName]!.isEmpty) {
      throw Exception("Nenhuma pergunta encontrada para ${widget.insectName}");
    }

    _flutterTts = FlutterTts();
    _configureTts();
    _initializeSpeech();
    _startQuiz();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMicrophonePermission();
    });
  }

  void _startQuiz() {
    _speakCurrentQuestion();
  }

  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        print("Permissão de microfone negada");
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.setCompletionHandler(() {});
    _flutterTts.setErrorHandler((msg) {});
    _flutterTts.stop();
    _speechService.stop();
    _pageController.dispose();
    if (_resultPageController != null) {
      _resultPageController!.dispose();
    }
    super.dispose();
  }

  void _closeResultDialog() {
    _vibrate();
    _flutterTts.stop();
    _speechService.stop();
    if (_resultPageController != null) {
      _resultPageController!.dispose();
      _resultPageController = null;
    }
    if (mounted) {
      setState(() => _isResultDialogOpen = false);
    }
    Navigator.pop(context);
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechService.initialize(context: context);
      print("SpeechService inicializado com sucesso");
    } catch (e) {
      print("Erro ao inicializar SpeechService: $e");
    }
  }

  void _navigateToPage(int newIndex) {
    if (!_resultPageController!.hasClients) return;

    final currentPage = _resultPageController!.page?.round() ?? 0;
    final totalPages = Questions.questionsMap[widget.insectName]!.length;

    if (newIndex >= 0 && newIndex < totalPages && newIndex != currentPage) {
      _vibrate();
      _resultPageController!.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isSpeaking || !_isReadyToListen) {
      print("Escuta não iniciada: _isListening=$_isListening, _isSpeaking=$_isSpeaking, _isReadyToListen=$_isReadyToListen");
      return;
    }

    try {
      await _speechService.listen(
        onResult: (command) {
          print("Comando detectado: $command");
          if (command.trim().isNotEmpty) {
            _handleVoiceCommand(command);
          } else {
            _restartListening();
          }
          setState(() => _isListening = false);
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) => print("Sound level: $level"),
      );
      setState(() => _isListening = true);
      print("Microfone ativado");
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      _restartListening();
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isListening && !_isSpeaking && _isReadyToListen) {
        print("Escuta parou, reiniciando...");
        _startListening();
      }
    });
  }

  void _restartListening() {
    setState(() => _isListening = false);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        print(_isListening ? "Escuta já ativa" : "Reiniciando escuta...");
        _startListening();
      }
    });
  }

  void _handleVoiceCommand(String command) {
    final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];

    final optionMatch = currentQuestion.matchVoiceCommand(command);
    if (optionMatch['recognized'] == true) {
      final int selectedOption = optionMatch['value'] as int;

      setState(() {
        _selectedAnswer = selectedOption;
        _isAnswered = true;
      });

      _answers[_currentQuestionIndex] = selectedOption;

      _vibrate();
      _flutterTts.speak("Opção ${selectedOption + 1} selecionada");

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          if (_currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1) {
            if (_answers.every((answer) => answer != null)) {
              _showResultDialog();
            } else {
              _nextQuestion();
            }
          } else {
            _nextQuestion();
          }
        }
      });

      return;
    }

    final navigationCommand = Question.matchNavigationCommand(command);
    if (navigationCommand != null) {
      switch (navigationCommand['value']) {
        case 'próxima pergunta':
          if (_isResultDialogOpen) {
            if (_resultPageController!.hasClients &&
                _resultPageController!.page!.round() < Questions.questionsMap[widget.insectName]!.length - 1) {
              _resultPageController!.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              _speakResultPage(_resultPageController!.page!.round() + 1);
            }
          } else if (_isAnswered) {
            _nextQuestion();
          }
          break;
        case 'voltar pergunta':
          if (_isResultDialogOpen) {
            if (_resultPageController!.page! > 0) {
              _resultPageController!.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              _speakResultPage(_resultPageController!.page!.round() - 1);
            }
          } else {
            _previousQuestion();
          }
          break;
        case 'finalizar':
          if (_answers.every((answer) => answer != null)) {
            _showResultDialog();
          } else {
            _flutterTts.speak("Por favor, responda todas as perguntas antes de confirmar.");
          }
          break;
      }
    }
  }

  void _configureTts() {
    print("Configurando TTS...");
    _flutterTts.setLanguage("pt-BR");
    _flutterTts.setSpeechRate(0.6);

    _flutterTts.setStartHandler(() {
      print("TTS iniciado");
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() async {
      print("TTS concluído");
      setState(() {
        _isSpeaking = false;
        _isReadyToListen = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isAnswered && !_isListening && _isReadyToListen) {
        _startListening();
      }
    });

    _flutterTts.setErrorHandler((msg) async {
      print("Erro no TTS: $msg");
      setState(() {
        _isSpeaking = false;
        _isReadyToListen = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isAnswered && !_isListening && _isReadyToListen) {
        _startListening();
      }
    });
  }

  Future<void> _speakCurrentQuestion() async {
    final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];
    String questionText = currentQuestion.question;
    List<String> options = currentQuestion.options;
    String ttsMessage = "Pergunta ${_currentQuestionIndex + 1}: $questionText. ";
    for (int i = 0; i < options.length; i++) {
      ttsMessage += "Opção ${i + 1}: ${options[i]}. ";
    }
    ttsMessage += "Fale a opção desejada.";
    print("Tentando falar: $ttsMessage");
    await _flutterTts.stop();
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(ttsMessage);
    print("Fala iniciada");
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  Future<void> _speakResultPage(int index) async {
    if (!_isResultDialogOpen || !_resultPageController!.hasClients) {
      print("Condições não atendidas para falar a página $index");
      return;
    }

    print("Preparando para falar a página $index");

    await _flutterTts.stop();
    setState(() => _isSpeaking = true);

    _flutterTts.setCompletionHandler(() async {
      print("Fala concluída - ativando microfone");
      setState(() => _isSpeaking = false);
      if (mounted && _isResultDialogOpen) {
        await Future.delayed(const Duration(milliseconds: 500));
        _startListeningForResultCommands();
      }
    });

    final question = Questions.questionsMap[widget.insectName]![index];
    final userAnswer = _answers[index];
    final correctAnswer = question.correctIndex;
    final totalPages = Questions.questionsMap[widget.insectName]!.length;

    String message = "Pergunta ${index + 1} de $totalPages: ${question.question}. ";
    message += "Sua resposta: ${question.options[userAnswer ?? 0]}. ";

    if (userAnswer == correctAnswer) {
      message += "Resposta correta. ";
    } else {
      message += "Resposta incorreta. A resposta correta é: ${question.options[correctAnswer]}. ";
    }

    message += "O que você deseja fazer? ";
    if (index > 0) message += "voltar pergunta, ";
    if (index < totalPages - 1) message += "próxima correção, ";
    message += "ou fechar correção?";

    print("Iniciando fala: $message");
    await _flutterTts.speak(message);
  }

  Future<void> _startListeningForResultCommands() async {
    if (_isSpeaking || !mounted || !_speechService.permissionGranted || !_isResultDialogOpen) {
      print("Não pode iniciar escuta: Speaking=$_isSpeaking, Mounted=$mounted, Permission=${_speechService.permissionGranted}, DialogOpen=$_isResultDialogOpen");
      return;
    }

    try {
      await _speechService.stop();
      await _speechService.listen(
        onResult: (command) {
          print("Comando recebido: $command");
          if (command.trim().isNotEmpty) {
            _handleResultDialogCommand(command.toLowerCase());
          }
        },
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 2),
      );
      print("Microfone ativado com sucesso para comandos de resultado!");
      setState(() => _isListening = true);
    } catch (e) {
      print("Erro ao ativar microfone para comandos de resultado: $e");
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isResultDialogOpen) {
          _startListeningForResultCommands();
        }
      });
    }
  }

  void _restartListeningForResultCommands() {
    setState(() => _isListening = false);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startListeningForResultCommands();
      }
    });
  }

  void _handleResultDialogCommand(String command) {
    setState(() => _isListening = false);

    if (!_resultPageController!.hasClients) {
      _restartListeningForResultCommands();
      return;
    }

    final currentPage = _resultPageController!.page?.round() ?? 0;
    final totalPages = Questions.questionsMap[widget.insectName]!.length;

    Future<void> speakAndRestart(String message) async {
      await _flutterTts.stop();
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(message);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isListening && _isResultDialogOpen) {
        _startListeningForResultCommands();
      }
    }

    if (_matchesCommand(command, 'fechar correcao')) {
      _closeResultDialog();
    } else if (_matchesCommand(command, 'voltar pergunta')) {
      if (currentPage > 0) {
        _navigateToPage(currentPage - 1);
      } else {
        speakAndRestart("Você já está na primeira pergunta.");
      }
    } else if (_matchesCommand(command, 'proxima correcao')) {
      if (_resultPageController!.hasClients && currentPage < Questions.questionsMap[widget.insectName]!.length - 1) {
        _vibrate();
        _resultPageController!.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        speakAndRestart("Você já está na última pergunta.");
      }
    } else {
      speakAndRestart("Comando não reconhecido. Por favor, diga: voltar pergunta, próxima correção ou fechar correção.");
    }
  }

  bool _matchesCommand(String input, String command) {
    final variations = <String, Set<String>>{
      'fechar correcao': {
        'fechar correção',
        'fechar correcao',
        'fechar',
        'fecha correção',
        'fecha correcao',
        'fechar resultado',
        'sair',
        'sair correção',
        'sair correcao',
        'close',
        'fechar corr',
        'fecharcorrecao',
        'fechar cor',
        'fechar quiz',
        'fechar quizz',
        'fechar kwez',
      },
      'voltar pergunta': {
        'voltar pergunta',
        'voltar',
        'volta pergunta',
        'voltar pra pergunta',
        'voltar pergunta anterior',
        'pergunta anterior',
        'anterior',
        'back question',
        'previous question',
        'voltar perg',
        'volt pergunta',
        'voltar per',
        'voltar p',
        'voltarpergunta',
        'voltar pra perg',
        'voltar pra trás',
        'voltar atrás',
        'voltar atras',
      },
      'proxima correcao': {
        'próxima correção',
        'proxima correcao',
        'próxima',
        'proxima',
        'próxima pergunta',
        'proxima pergunta',
        'próxima corr',
        'proxima corr',
        'next correction',
        'next question',
        'próxima corre',
        'proxima corre',
        'próximacorreção',
        'proximacorrecao',
        'próxima pergunta corrigida',
        'proxima pergunta corrigida',
        'avançar',
        'avancar',
        'avançar correção',
        'avancar correcao',
      },
    };

    String normalize(String text) {
      return removeDiacritics(text).toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    final normalizedInput = normalize(input);
    final normalizedCommand = normalize(command);

    final matched = variations[normalizedCommand]?.any((variant) => normalizedInput.contains(normalize(variant))) ?? false;

    print("Verificando comando '$command': input='$input', matched=$matched");
    return matched;
  }

  void _nextQuestion() {
    if (!_isAnswered) return;

    _vibrate();

    setState(() {
      _answers[_currentQuestionIndex] = _selectedAnswer;

      final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];
      if (_selectedAnswer == currentQuestion.correctIndex) {
        _score++;
      }

      if (_currentQuestionIndex < Questions.questionsMap[widget.insectName]!.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
      } else {
        _showResultDialog();
        return;
      }
    });

    _speechService.stop();
    setState(() => _isListening = false);
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCurrentQuestion();
    });
  }

  void _previousQuestion() {
    _vibrate();
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
      });
      _speakCurrentQuestion();
    }
  }

  void _showResultDialog() {
    _inResultMode = true;
    setState(() => _isResultDialogOpen = true);

    _resultPageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakResultPage(0);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          _closeResultDialog();
          return true;
        },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: SizedBox(
            height: 400,
            width: double.maxFinite,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _resultPageController,
                    onPageChanged: (index) {
                      _flutterTts.stop();
                      setState(() => _isSpeaking = true);
                      _speakResultPage(index);
                    },
                    itemCount: Questions.questionsMap[widget.insectName]!.length,
                    itemBuilder: (context, index) {
                      final question = Questions.questionsMap[widget.insectName]![index];
                      final userAnswer = _answers[index];
                      final correctAnswer = question.correctIndex;
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pergunta ${index + 1}:',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              question.question,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Sua Resposta:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: userAnswer == correctAnswer ? Colors.green : Colors.red,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: userAnswer == correctAnswer ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: userAnswer == correctAnswer ? Colors.green : Colors.red,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                question.options[userAnswer ?? 0],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: userAnswer == correctAnswer ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                            if (userAnswer != correctAnswer) ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Resposta Correta:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  question.options[correctAnswer],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _resultPageController!.hasClients && _resultPageController!.page! > 0
                            ? () {
                          _vibrate();
                          _resultPageController!.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                            : null,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _vibrate();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAB08A),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          'Fechar',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _resultPageController!.hasClients && _resultPageController!.page! < Questions.questionsMap[widget.insectName]!.length - 1
                            ? () {
                          _vibrate();
                          _resultPageController!.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        title: Text('Quiz sobre ${widget.insectName}'),
        backgroundColor: const Color(0xFFEAB08A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate();
            _flutterTts.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pergunta ${_currentQuestionIndex + 1}/${Questions.questionsMap[widget.insectName]!.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(currentQuestion.question, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ...List.generate(currentQuestion.options.length, (index) {
              return RadioListTile<int>(
                title: Text(currentQuestion.options[index]),
                value: index,
                groupValue: _selectedAnswer,
                onChanged: (value) {
                  _vibrate();
                  setState(() {
                    _selectedAnswer = value;
                    _isAnswered = true;
                  });
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1) {
                      _showResultDialog();
                    } else {
                      _nextQuestion();
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _currentQuestionIndex > 0 ? Colors.grey : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  child: const Text('Voltar', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: _isAnswered &&
                      _currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1 &&
                      _answers.every((answer) => answer != null)
                      ? _showResultDialog
                      : (_isAnswered ? _nextQuestion : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnswered &&
                        _currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1 &&
                        _answers.every((answer) => answer != null)
                        ? const Color(0xFFEAB08A)
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1
                        ? 'Confirmar Respostas'
                        : 'Próxima Pergunta',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}