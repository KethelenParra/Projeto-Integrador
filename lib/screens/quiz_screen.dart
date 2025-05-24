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
  List<int?> _answers = List.filled(5, null);
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;

  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _configureTts();
    _initializeSpeech();
    _speakCurrentQuestion(); // Chama diretamente sem delay inicial
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechService.stop();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize(context: context);
    _startListening();
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    try {
      await _speechService.listen(
        onResult: (command) {
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
    } catch (e) {
      print("Error initializing speech recognition: $e");
      _restartListening();
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isListening) {
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
      switch (navigationCommand) {
        case 'próximo':
          if (_isAnswered) _nextQuestion();
          break;
        case 'anterior':
          _previousQuestion();
          break;
        case 'confirmar':
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
    _flutterTts.setLanguage("pt-BR");
    _flutterTts.setSpeechRate(0.6);

    _flutterTts.setStartHandler(() {
      // Não para o SpeechService aqui, apenas atualiza o estado
      setState(() => _isListening = true); // Garante que o microfone fique ativo
    });

    _flutterTts.setCompletionHandler(() async {
      print("TTS completed");
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isAnswered) {
        _startListening();
      }
    });

    _flutterTts.setErrorHandler((msg) async {
      print("Erro TTS: $msg");
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isAnswered) {
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
    await _flutterTts.stop();
    await _flutterTts.speak(ttsMessage);
    // Inicia a escuta imediatamente após falar
    if (mounted && !_isListening) {
      _startListening();
    }
  }

  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  Future<void> _speakResultPage(int index) async {
    final question = Questions.questionsMap[widget.insectName]![index];
    final userAnswer = _answers[index];
    final correctAnswer = question.correctIndex;
    String resultText = "Pergunta ${index + 1}: ${question.question}. ";
    resultText += "Sua resposta: ${question.options[userAnswer ?? 0]}. ";
    if (userAnswer == correctAnswer) {
      resultText += "Sua resposta está correta. O que você deseja fazer? voltar pergunta, fechar correção ou próxima correção?";
    } else {
      resultText += "Sua resposta está errada, a resposta correta é: ${question.options[correctAnswer]}. O que você deseja fazer? voltar pergunta, fechar correção ou próxima correção?";
    }
    await _flutterTts.speak(resultText);
  }

  void _nextQuestion() {
    _vibrate();
    if (_selectedAnswer == null) return;

    bool finishedQuiz = false;

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
        finishedQuiz = true;
        if (_answers.every((answer) => answer != null)) {
          _flutterTts.stop();
          _speechService.stop();
          _showResultDialog();
        }
      }
    });

    if (!finishedQuiz && mounted) {
      _speechService.stop();
      setState(() => _isListening = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCurrentQuestion();
      });
    }
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
                    final question = Questions.questionsMap[widget.insectName]![index];
                    final userAnswer = _answers[index];
                    final correctAnswer = question.correctIndex;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Pergunta ${index + 1}:', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(question.question, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                          Text('Sua Resposta:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: userAnswer == correctAnswer ? Colors.green : Colors.red)),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: userAnswer == correctAnswer ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: userAnswer == correctAnswer ? Colors.green : Colors.red, width: 2),
                            ),
                            child: Text(question.options[userAnswer ?? 0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: userAnswer == correctAnswer ? Colors.green[800] : Colors.red[800])),
                          ),
                          if (userAnswer != correctAnswer) ...[
                            const SizedBox(height: 10),
                            const Text('Resposta Correta:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green, width: 2)),
                              child: Text(question.options[correctAnswer], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800])),
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
                      onPressed: () {
                        _vibrate();
                        if (_pageController.page! > 0) {
                          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAB08A), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                      child: const Text('Fechar', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16)),
                    ),
                    IconButton(
                      onPressed: () {
                        _vibrate();
                        if (_pageController.page! < Questions.questionsMap[widget.insectName]!.length - 1) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
            Text('Pergunta ${_currentQuestionIndex + 1}/${Questions.questionsMap[widget.insectName]!.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: _currentQuestionIndex > 0 ? Colors.grey : Colors.grey.shade400, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  child: const Text('Voltar', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                ElevatedButton(
                  onPressed: _isAnswered && _currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1 && _answers.every((answer) => answer != null)
                      ? _showResultDialog
                      : (_isAnswered ? _nextQuestion : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnswered && _currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1 && _answers.every((answer) => answer != null)
                        ? const Color(0xFFEAB08A)
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1 ? 'Confirmar Respostas' : 'Próxima Pergunta',
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