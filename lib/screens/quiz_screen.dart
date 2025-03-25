import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'questions.dart';

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

  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _configureTts();
    // Aguarda um pequeno delay para garantir que o TTS esteja pronto
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCurrentQuestion();
    });
  }

  void _configureTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
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
    await _flutterTts.speak(ttsMessage);
  }

  /// Método para ler os resultados de cada página do diálogo.
  Future<void> _speakResultPage(int index) async {
    final question = Questions.questionsMap[widget.insectName]![index];
    final userAnswer = _answers[index];
    final correctAnswer = question.correctIndex;
    String resultText = "Pergunta ${index + 1}: ${question.question}. ";
    resultText += "Sua resposta: ${question.options[userAnswer ?? 0]}. ";
    if (userAnswer == correctAnswer) {
      resultText += "Sua resposta está correta.";
    } else {
      resultText += "Sua resposta está errada, a resposta correta é: ${question.options[correctAnswer]}.";
    }
    await _flutterTts.speak(resultText);
  }

  void _nextQuestion() {
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

  void _previousQuestion() {
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

    // Após abrir o diálogo, dispara a leitura da primeira página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakResultPage(0);
    });

    showDialog(
      context: context,
      barrierDismissible:
          false, // O usuário deve clicar no botão "Fechar" para sair
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
                              color: userAnswer == correctAnswer
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
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
  void dispose() {
    _flutterTts.stop();
    super.dispose();
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
                  setState(() {
                    _selectedAnswer = value;
                    _isAnswered = true; // Habilita o botão "Próxima Pergunta"
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


