import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  late List<int?> _answers;

  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  late FlutterTts _flutterTts;

  late PageController _resultPageController;
  bool _inResultMode = false;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _answers = List<int?>.filled(
      Questions.questionsMap[widget.insectName]!.length,
      null,
    );
    _resultPageController = PageController();
    _configureTts();
    _initializeSpeech();
    Future.delayed(const Duration(milliseconds: 500), _speakCurrentQuestion);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechService.stop();
    _resultPageController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize(context: context);
    _startListening();
  }

  Future<void> _startListening() async {
    if (_isListening) {
      print("Já está escutando, parando antes de reiniciar...");
      await _speechService.stop();
      setState(() => _isListening = false);
    }
    if (!_speechService.isInitialized) {
      print("SpeechService não inicializado, inicializando...");
      await _speechService.initialize(context: context);
    }
    try {
      await _speechService.listen(
        onResult: (command) => _handleVoiceCommand(command),
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) {
          if (level > 0) print("Nível de som: $level");
        },
      );
      setState(() => _isListening = true);
      print("Reconhecimento de voz iniciado");
    } catch (e) {
      print("Erro ao iniciar escuta: $e");
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Problema ao ativar microfone")),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && !_inResultMode) {
        if (e.toString().contains('Error 7')) {
          print("Erro 7 detectado, reiniciando SpeechService...");
          await _speechService.reset();
          await _speechService.initialize(context: context);
        }
        _startListening();
      }
    }
  }

  void _handleVoiceCommand(String command) async {
    final cmd = command.toLowerCase().trim();

    if (_inResultMode) {
      if (cmd.contains('voltar pergunta') || cmd.contains('voltar correção')) {
        _vibrate();
        await _flutterTts.stop();
        if (_resultPageController.page! > 0) {
          _resultPageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else if (cmd.contains('próxima pergunta') ||
          cmd.contains('próxima correção')) {
        _vibrate();
        await _flutterTts.stop();
        final total = Questions.questionsMap[widget.insectName]!.length;
        if (_resultPageController.page! < total - 1) {
          _resultPageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else if (cmd.contains('fechar correção')) {
        _vibrate();
        await _flutterTts.stop();
        Navigator.pop(context);
        _inResultMode = false;
        await _startListening();
      } else {
        print("Comando não reconhecido no modo de resultados: $cmd");
        await _flutterTts.stop();
        await _flutterTts.speak(
            "Comando não reconhecido. Diga 'voltar correção', 'próxima correção' ou 'fechar correção'.");
        _vibrate(duration: 100);
        // Escuta será reativada pelo setCompletionHandler do TTS
      }
      return;
    }

    // Comandos gerais: sair do quiz
    if (cmd.contains('voltar tela') ||
        cmd.contains('sair quiz') ||
        cmd == 'sair') {
      _vibrate();
      await _speechService.stop();
      await _flutterTts.stop();
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 300), () async {
        await _flutterTts.speak(
            "Você voltou para a tela de detalhes. Diga 'Iniciar quiz', 'Ler descrição' ou 'Voltar'.");
        await _startListening();
      });
      return;
    }

    // Seleção de opção
    final currentQuestion =
    Questions.questionsMap[widget.insectName]![_currentQuestionIndex];
    final optionMatch = currentQuestion.matchVoiceCommand(command);
    if (optionMatch['recognized'] == true) {
      setState(() {
        _selectedAnswer = optionMatch['value'] as int;
        _isAnswered = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_currentQuestionIndex ==
            Questions.questionsMap[widget.insectName]!.length - 1) {
          _showResultDialog();
        } else {
          _nextQuestion();
        }
      });
      return;
    }

    // Navegação por pergunta
    final navMatch = Question.matchNavigationCommand(command);
    if (navMatch['recognized'] == true) {
      switch (navMatch['value'] as String) {
        case 'voltar pergunta':
          print("Comando 'voltar pergunta' reconhecido. Índice atual: $_currentQuestionIndex");
          _previousQuestion();
          break;
        case 'próxima pergunta':
          if (_isAnswered) _nextQuestion();
          break;
        case 'finalizar':
          if (_isAnswered) _showResultDialog();
          break;
      }
      return;
    }

    // Caso padrão: comando não reconhecido ou vazio
    print("Comando não reconhecido ou vazio: $cmd, estado _isListening: $_isListening");
    await _flutterTts.stop();
    await _flutterTts.speak(
        "Comando não reconhecido. Diga o número da opção, 'próxima pergunta', 'voltar pergunta' ou 'sair'.");
    _vibrate(duration: 100);
    // Escuta será reativada pelo setCompletionHandler do TTS
  }

  void _configureTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);

    _flutterTts.setStartHandler(() {
      setState(() => _isListening = false);
      _speechService.stop();
      print("TTS iniciado, escuta parada");
    });

    _flutterTts.setCompletionHandler(() async {
      print("TTS concluído, tentando reativar escuta...");
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && !_inResultMode) {
        await _startListening();
      }
    });

    _flutterTts.setErrorHandler((msg) async {
      print("Erro TTS: $msg");
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && !_inResultMode) {
        await _startListening();
      }
    });
  }

  Future<void> _speakCurrentQuestion() async {
    final questions = Questions.questionsMap[widget.insectName]!;
    final total = questions.length;
    final idx = _currentQuestionIndex;
    final question = questions[idx];

    print("Lendo pergunta: índice $idx, pergunta: ${question.question}");
    String ttsMessage = "Pergunta ${idx + 1} de $total: ${question.question}. ";
    for (int i = 0; i < question.options.length; i++) {
      ttsMessage += "Opção ${i + 1}: ${question.options[i]}. ";
    }
    ttsMessage += "Fale a opção desejada.";

    if (idx > 0) {
      ttsMessage += " Para voltar à pergunta anterior, diga 'voltar pergunta'.";
    }

    if (_isAnswered && idx < total - 1) {
      ttsMessage +=
      " Quando quiser ir para a próxima pergunta, diga 'próxima pergunta'.";
    }

    ttsMessage +=
    " Para sair do quiz e voltar aos detalhes do inseto, diga 'voltar tela'.";

    await _flutterTts.speak(ttsMessage);
  }

  void _vibrate({int duration = 200}) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }

  Future<void> _speakResultPage(int index) async {
    final question = Questions.questionsMap[widget.insectName]![index];
    final userAnswer = _answers[index];
    final correctAnswer = question.correctIndex;
    String resultText = "Pergunta ${index + 1}: ${question.question}. ";
    resultText += "Sua resposta: ${question.options[userAnswer ?? 0]}. ";
    if (userAnswer == correctAnswer) {
      resultText +=
      "Sua resposta está correta. Diga 'voltar correção', 'próxima correção' ou 'fechar correção'.";
    } else {
      resultText +=
      "Sua resposta está errada, a resposta correta é: ${question.options[correctAnswer]}. Diga 'voltar correção', 'próxima correção' ou 'fechar correção'.";
    }
    await _flutterTts.speak(resultText);
  }

  void _nextQuestion() {
    _vibrate();
    if (_selectedAnswer == null) return;

    bool finishedQuiz = false;

    setState(() {
      _answers[_currentQuestionIndex] = _selectedAnswer;
      final currentQuestion =
      Questions.questionsMap[widget.insectName]![_currentQuestionIndex];
      if (_selectedAnswer == currentQuestion.correctIndex) {
        _score++;
      }

      if (_currentQuestionIndex <
          Questions.questionsMap[widget.insectName]!.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
        print("Avançando para pergunta: índice $_currentQuestionIndex");
      } else {
        finishedQuiz = true;
        _flutterTts.stop();
        _showResultDialog();
      }
    });

    if (!finishedQuiz) {
      _speakCurrentQuestion();
    }
  }

  void _previousQuestion() {
    _vibrate();
    print("Antes de voltar: índice atual = $_currentQuestionIndex");
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
        print("Depois de voltar: índice atual = $_currentQuestionIndex, resposta selecionada = $_selectedAnswer");
      });
      _speakCurrentQuestion();
    } else {
      print("Não é possível voltar: já na primeira pergunta (índice 0)");
    }
  }

  void _showResultDialog() {
    _inResultMode = true;
    PageController _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakResultPage(0);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SizedBox(
          height: 400,
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _flutterTts.stop();
                    _speakResultPage(index);
                  },
                  itemCount: Questions.questionsMap[widget.insectName]!.length,
                  itemBuilder: (context, index) {
                    final question =
                    Questions.questionsMap[widget.insectName]![index];
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
                              color: userAnswer == correctAnswer
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: userAnswer == correctAnswer
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: userAnswer == correctAnswer
                                    ? Colors.green
                                    : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              question.options[userAnswer ?? 0],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: userAnswer == correctAnswer
                                    ? Colors.green[800]
                                    : Colors.red[800],
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        _vibrate();
                        if (_pageController.page! > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
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
                      onPressed: () {
                        _vibrate();
                        if (_pageController.page! <
                            Questions.questionsMap[widget.insectName]!.length -
                                1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion =
    Questions.questionsMap[widget.insectName]![_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        title: Text('Quiz sobre ${widget.insectName}'),
        backgroundColor: const Color(0xFFEAB08A),
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
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
            Text(
              'Pergunta ${_currentQuestionIndex + 1}/${Questions.questionsMap[widget.insectName]!.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              currentQuestion.question,
              style: const TextStyle(fontSize: 20),
            ),
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
                    if (_currentQuestionIndex ==
                        Questions.questionsMap[widget.insectName]!.length - 1) {
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
                  onPressed:
                  _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentQuestionIndex > 0
                        ? Colors.grey
                        : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isAnswered ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isAnswered ? const Color(0xFFEAB08A) : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _currentQuestionIndex ==
                        Questions.questionsMap[widget.insectName]!.length -
                            1
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