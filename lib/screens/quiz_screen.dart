import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'questions.dart';
import 'package:vision_app_3d/service/speechService.dart';
import 'package:vibration/vibration.dart'; // Import para vibração personalizada

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
    _initializeSpeech(); // Adicione esta linha
    // Aguarda um pequeno delay para garantir que o TTS esteja pronto
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCurrentQuestion();
    });
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

    await _speechService.listen(
      onResult: (command) {
        if (command.trim().isNotEmpty) {
          _handleVoiceCommand(command);
        }
      },
      localeId: 'pt_BR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3), onSoundLevelChange: (level) {  },
    );

    setState(() => _isListening = true);
  }

  void _handleVoiceCommand(String command) {
    final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];

    // Tenta encontrar uma opção correspondente
    final optionIndex = currentQuestion.matchVoiceCommand(command);
    if (optionIndex != null) {
      setState(() {
        _selectedAnswer = optionIndex;
        _isAnswered = true;
      });
      return;
    }

    // Verifica comandos de navegação
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
          if (_isAnswered) _showResultDialog();
          break;
      }
    }
  }

  // Configura o TTS
  void _configureTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    
    _flutterTts.setStartHandler(() {
      setState(() => _isListening = false);
      _speechService.stop();
    });

    _flutterTts.setCompletionHandler(() async {
      print("TTS completed");
      setState(() => _isListening = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _startListening();
      }
    });

    _flutterTts.setErrorHandler((msg) async {
      print("Erro TTS: $msg");
      setState(() => _isListening = false);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _startListening();
      }
    });
  }

  // Faz o TTS ler a pergunta atual e as opções
  Future<void> _speakCurrentQuestion() async {
    final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];
    String questionText = currentQuestion.question;
    List<String> options = currentQuestion.options;
    String ttsMessage = "Pergunta ${_currentQuestionIndex + 1}: $questionText. ";
    for (int i = 0; i < options.length; i++) {
      ttsMessage += "Opção ${i + 1}: ${options[i]}. ";
    }
    ttsMessage += "Fale a opção desejada.";
    await _flutterTts.speak(ttsMessage);
  }

  // Função para acionar a vibração personalizada
  void _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200); // vibração de 200ms
    }
  }

  /// Método para ler os resultados de cada página do diálogo.
  Future<void> _speakResultPage(int index) async {
    final question = Questions.questionsMap[widget.insectName]![index];
    final userAnswer = _answers[index];
    final correctAnswer = question.correctIndex;
    String resultText = "Pergunta ${index + 1}: ${question.question}. ";
    resultText += "Sua resposta: ${question.options[userAnswer ?? 0]}. ";
    if (userAnswer == correctAnswer) {
      resultText += "Sua resposta está correta. O que você deseja fazer? voltar pergunta, fechar correção ou próxima correção?";
    } else {
      resultText +=
          "Sua resposta está errada, a resposta correta é: ${question.options[correctAnswer]}. O que você deseja fazer? voltar pergunta, fechar correção ou próxima correção?";
    }
    await _flutterTts.speak(resultText);
  }

  void _nextQuestion() {
    _vibrate(); // Vibração ao avançar
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
        _flutterTts.stop(); // Para o TTS ao finalizar o quiz
        _showResultDialog();
      }
    });

    if (!finishedQuiz) {
      _speakCurrentQuestion();
    }
  }

  // Retrocede para a pergunta anterior, com vibração
  void _previousQuestion() {
    _vibrate(); // Vibração ao voltar
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
      });
      _speakCurrentQuestion();
    }
  }

  // Exibe o diálogo com os resultados do quiz, adicionando vibração aos botões
  void _showResultDialog() {
    PageController _pageController = PageController();

    // Após abrir o diálogo, dispara a leitura da primeira página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakResultPage(0);
    });

    showDialog(
      context: context,
      barrierDismissible: false, // O usuário deve clicar no botão "Fechar" para sair
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SizedBox(
          height: 400, // Tamanho fixo para o diálogo
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    // Quando a página muda, o TTS lê o conteúdo correspondente
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
                      onPressed: () {
                        _vibrate(); // Vibração ao clicar no botão de voltar do diálogo
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
                        _vibrate(); // Vibração ao clicar no botão "Fechar"
                        Navigator.pop(context); // Fecha o diálogo
                        Navigator.pop(context); // Volta para a tela anterior
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
                      onPressed: () {
                        _vibrate(); // Vibração ao clicar no botão de avançar do diálogo
                        if (_pageController.page! < Questions.questionsMap[widget.insectName]!.length - 1) {
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
    final currentQuestion = Questions.questionsMap[widget.insectName]![_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        title: Text('Quiz sobre ${widget.insectName}'),
        backgroundColor: const Color(0xFFEAB08A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _vibrate(); // Vibração ao clicar no botão de voltar
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
                  _vibrate(); // Vibração ao selecionar uma opção
                  setState(() {
                    _selectedAnswer = value;
                    _isAnswered = true; // Habilita o botão "Próxima Pergunta"
                  });

                  // Pequeno delay para dar feedback visual da seleção

                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_currentQuestionIndex == Questions.questionsMap[widget.insectName]!.length - 1) {
                      _showResultDialog(); // Se for a última pergunta, mostra o resultado
                    } else {
                      _nextQuestion(); // Se não for a última, vai para a próxima
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isAnswered ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnswered ? const Color(0xFFEAB08A) : Colors.grey,
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