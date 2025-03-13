import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final String insectName;

  const QuizScreen({super.key, required this.insectName});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _score = 0;
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _isAnswered = false;
  List<int?> _answers = List.filled(5, null);

  final Map<String, List<Map<String, dynamic>>> _questions = {
    'Escorpião': [
      {
        'question': 'Qual é a principal característica dos escorpiões?',
        'options': [
          'Possuem asas',
          'Têm ferrão venenoso',
          'São mamíferos',
          'Vivem na água'
        ],
        'correctIndex': 1
      },
      {
        'question': 'O que os escorpiões comem?',
        'options': ['Plantas', 'Insetos e aranhas', 'Peixes', 'Frutas'],
        'correctIndex': 1
      },
      {
        'question': 'Qual o habitat natural do escorpião?',
        'options': ['Árvores', 'Desertos e florestas', 'Águas doces', 'Neve'],
        'correctIndex': 1
      },
      {
        'question': 'O escorpião brilha sob luz ultravioleta?',
        'options': ['Sim', 'Não', 'Apenas os filhotes', 'Somente os venenosos'],
        'correctIndex': 0
      },
      {
        'question': 'Como se reproduzem?',
        'options': [
          'Botam ovos',
          'Fazem metamorfose',
          'Dançam antes do acasalamento',
          'Vivem em grupos familiares'
        ],
        'correctIndex': 2
      },
    ],
    'Borboleta': [
      {
        'question': 'Qual é a principal função das borboletas na natureza?',
        'options': [
          'Produzir mel',
          'Ajudar na polinização',
          'Caçar insetos',
          'Comer folhas'
        ],
        'correctIndex': 1
      },
      {
        'question': 'Qual fase NÃO faz parte do ciclo de vida da borboleta?',
        'options': ['Ovo', 'Larva', 'Casulo', 'Peixe'],
        'correctIndex': 3
      },
      {
        'question': 'Como as borboletas se alimentam?',
        'options': [
          'Comem carne',
          'Sugam néctar com a probóscide',
          'Mastigam folhas',
          'Bebem água'
        ],
        'correctIndex': 1
      },
      {
        'question': 'O que acontece na fase da pupa (crisálida)?',
        'options': [
          'A borboleta morre',
          'A borboleta hiberna',
          'A metamorfose acontece',
          'A borboleta põe ovos'
        ],
        'correctIndex': 2
      },
      {
        'question': 'O que as borboletas usam para sentir o gosto?',
        'options': ['Asas', 'Olhos', 'Patas', 'Antenas'],
        'correctIndex': 2
      },
    ],
    'Barbeiro': [
      {
        'question': 'Por que o barbeiro é perigoso?',
        'options': [
          'Ele pica e transmite a Doença de Chagas',
          'Tem veneno mortal',
          'Causa alergias severas',
          'Se alimenta de plantas tóxicas'
        ],
        'correctIndex': 0
      },
      {
        'question': 'O que o barbeiro suga para se alimentar?',
        'options': ['Sangue', 'Seiva de plantas', 'Água', 'Veneno'],
        'correctIndex': 0
      },
      {
        'question': 'Qual é o principal causador da Doença de Chagas?',
        'options': ['Bactéria', 'Fungo', 'Protozoário', 'Vírus'],
        'correctIndex': 2
      },
      {
        'question': 'Onde os barbeiros costumam se esconder?',
        'options': [
          'Embaixo da água',
          'Em frestas e ninhos',
          'Nas árvores',
          'No ar'
        ],
        'correctIndex': 1
      },
      {
        'question': 'Quantas fases tem o ciclo de vida do barbeiro?',
        'options': ['3', '5', '7', '9'],
        'correctIndex': 1
      },
    ],
    'Abelha': [
      {
        'question': 'Qual a principal função das abelhas para o meio ambiente?',
        'options': [
          'Fazer mel',
          'Polinizar plantas',
          'Caçar insetos',
          'Produzir geleia real'
        ],
        'correctIndex': 1
      },
      {
        'question': 'Como as abelhas se comunicam?',
        'options': [
          'Através de danças',
          'Pelo canto',
          'Com sinais de luz',
          'Pelo cheiro'
        ],
        'correctIndex': 0
      },
      {
        'question': 'O que a abelha rainha faz?',
        'options': [
          'Produz mel',
          'Põe ovos',
          'Defende a colmeia',
          'Poliniza flores'
        ],
        'correctIndex': 1
      },
      {
        'question': 'Qual o nome do alimento produzido pelas abelhas?',
        'options': ['Cera', 'Pólen', 'Mel', 'Seiva'],
        'correctIndex': 2
      },
      {
        'question': 'Quantas asas uma abelha tem?',
        'options': ['2', '4', '6', '8'],
        'correctIndex': 1
      },
    ],
    'Aranha': [
      {
        'question': 'As aranhas pertencem a qual grupo de animais?',
        'options': ['Insetos', 'Répteis', 'Aracnídeos', 'Anfíbios'],
        'correctIndex': 2
      },
      {
        'question': 'O que a aranha usa para produzir teia?',
        'options': ['Boca', 'Glândulas abdominais', 'Patas', 'Olhos'],
        'correctIndex': 1
      },
      {
        'question':
            'Qual o nome das partes que a aranha usa para injetar veneno?',
        'options': ['Patas', 'Quelíceras', 'Garras', 'Asas'],
        'correctIndex': 1
      },
      {
        'question': 'Quantos olhos a maioria das aranhas possui?',
        'options': ['2', '4', '6', '8'],
        'correctIndex': 3
      },
      {
        'question': 'Como as caranguejeiras se defendem?',
        'options': [
          'Fugindo',
          'Soltando pelos urticantes',
          'Atacando humanos',
          'Fazendo barulho'
        ],
        'correctIndex': 1
      },
    ],
  };

  void _nextQuestion() {
    if (_selectedAnswer == null) return;

    setState(() {
      _answers[_currentQuestionIndex] = _selectedAnswer;

      if (_selectedAnswer ==
          _questions[widget.insectName]![_currentQuestionIndex]
              ['correctIndex']) {
        _score++;
      }

      if (_currentQuestionIndex < _questions[widget.insectName]!.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
      } else {
        _showResultDialog();
      }
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _answers[_currentQuestionIndex];
        _isAnswered = _selectedAnswer != null;
      });
    }
  }

  void _showResultDialog() {
    PageController _pageController = PageController();

    showDialog(
      context: context,
      barrierDismissible:
          false, // O usuário deve clicar no botão "Fechar" para sair
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SizedBox(
          height: 400, // Define um tamanho fixo para o diálogo
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _questions[widget.insectName]!.length,
                  itemBuilder: (context, index) {
                    final question = _questions[widget.insectName]![index];
                    final userAnswer = _answers[index];
                    final correctAnswer = question['correctIndex'];

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
                            question['question'],
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
                              question['options'][userAnswer ?? 0],
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
                                question['options'][correctAnswer],
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
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_pageController.page! <
                            _questions[widget.insectName]!.length - 1) {
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
    final question = _questions[widget.insectName]![_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz sobre ${widget.insectName}'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pergunta ${_currentQuestionIndex + 1}/${_questions[widget.insectName]!.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ...List.generate(question['options'].length, (index) {
              return RadioListTile<int>(
                title: Text(question['options'][index]),
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
                  onPressed: _currentQuestionIndex > 0
                      ? _previousQuestion
                      : null, // Desativa no início
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
                  onPressed: _isAnswered
                      ? _nextQuestion
                      : null, // Só permite avançar se houver resposta
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnswered ? Colors.orange : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _currentQuestionIndex ==
                            _questions[widget.insectName]!.length - 1
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
