import 'package:vision_app_3d/screens/quiz_screen.dart';

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final Map<String, List<String>> optionVoiceCommands;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  }) : optionVoiceCommands = _generateOptionCommands(options);

  static Map<String, List<String>> _generateOptionCommands(List<String> options) {
    Map<String, List<String>> commands = {};

    for (int i = 0; i < options.length; i++) {
      final number = i + 1;
      commands['opção $number'] = [
        if (number == 1) ...[
          'um',
          'hum',
          'primeiro',
          'primeira',
          'alternativa um',
          'alternativa hum',
          'número um',
          'número hum',
          'primeira opção',
          'primeira alternativa',
        ],
        if (number == 2) ...[
          'dois',
          'duas',
          'segundo',
          'segunda',
          'alternativa dois',
          'alternativa duas',
          'número dois',
          'número duas',
          'segunda opção',
          'segunda alternativa',
        ],
        if (number == 3) ...[
          'três',
          'terceiro',
          'terceira',
          'alternativa três',
          'alternativa terceira',
          'número três',
          'terceira opção',
          'terceira alternativa',
        ],
        if (number == 4) ...[
          'quatro',
          'quarta',
          'quarto',
          'alternativa quatro',
          'alternativa quarta',
          'número quatro',
          'quarta opção',
          'quarta alternativa',
        ],
        'opção $number',
        '$number',
        'número $number',
        'opção ${_numberToWord(number)}',
        _numberToWord(number),
        'escolher opção $number',
        'selecionar opção $number',
        'escolher $number',
        'selecionar $number',
        'a opção $number',
        'alternativa $number',
        'escolher alternativa $number',
        'selecionar alternativa $number',
      ];
    }
    return commands;
  }

  static String _numberToWord(int number) {
    const words = {
      1: ['um', 'hum', 'primeiro', 'primeira', 'primeira opção', 'primera opção', 'primeira opição'],
      2: ['dois', 'duas', 'segundo', 'segunda', 'segunda opção', 'segunda opição'],
      3: ['três', 'tres', 'terceiro', 'terceira', 'terceira opção', 'terceira opição', 'tercera opção', 'tercera opição'],
      4: ['quatro', 'quarta', 'quarto', 'quarta opção', 'quarta opição'],
    };
    return words[number]?.first ?? number.toString();
  }

  Map<String, dynamic> matchVoiceCommand(String command) {
    final cmd = command.toLowerCase().trim();
    final optionPatterns = [
      {'pattern': r'primeira\s*(opção)?|opção\s*1|1', 'value': 0},
      {'pattern': r'segunda\s*(opção)?|opção\s*2|2', 'value': 1},
      {'pattern': r'terceira\s*(opção)?|opção\s*3|3', 'value': 2},
      {'pattern': r'quarta\s*(opção)?|opção\s*4|4', 'value': 3},
    ];

    for (var pattern in optionPatterns) {
      if (RegExp(pattern['pattern'] as String).hasMatch(cmd)) {
        return {'recognized': true, 'value': pattern['value']};
      }
    }
    return {'recognized': false, 'value': null};
  }

  static final Map<String, List<String>> navigationCommands = {
    'próxima pergunta': [
      'próximo',
      'próxima',
      'avançar',
      'seguinte',
      'continuar',
      'passar',
      'próxima pergunta',
      'avançar questão'
    ],
    'voltar pergunta': ['anterior', 'voltar', 'retornar', 'questão anterior', 'pergunta anterior'],
    'finalizar': ['confirmar', 'finalizar', 'terminar', 'concluir', 'pronto', 'terminei'],
  };

  static Map<String, dynamic> matchNavigationCommand(String command) {
    final cmd = command.toLowerCase().trim();
    if (cmd.contains('voltar pergunta') || cmd == 'voltar') {
      return {'recognized': true, 'value': 'voltar pergunta'};
    }
    if (cmd.contains('próxima pergunta') || cmd.contains('próxima') || cmd == 'avançar') {
      return {'recognized': true, 'value': 'próxima pergunta'};
    }
    if (cmd.contains('finalizar') || cmd.contains('terminar')) {
      return {'recognized': true, 'value': 'finalizar'};
    }
    return {'recognized': false, 'value': null};
  }
}

class Questions {
  static final Map<String, List<Question>> questionsMap = {
    'Escorpião': [
      Question(
        question: 'Qual é a principal característica dos escorpiões?',
        options: ['Possuem asas', 'Têm ferrão venenoso', 'São mamíferos', 'Vivem na água'],
        correctIndex: 1,
      ),
      Question(
        question: 'O que os escorpiões comem?',
        options: ['Plantas', 'Insetos e aranhas', 'Peixes', 'Frutas'],
        correctIndex: 1,
      ),
      Question(
        question: 'Qual o habitat natural do escorpião?',
        options: ['Árvores', 'Desertos e florestas', 'Águas doces', 'Neve'],
        correctIndex: 1,
      ),
      Question(
        question: 'O escorpião brilha sob luz ultravioleta?',
        options: ['Sim', 'Não', 'Apenas os filhotes', 'Somente os venenosos'],
        correctIndex: 0,
      ),
      Question(
        question: 'Como se reproduzem?',
        options: ['Botam ovos', 'Fazem metamorfose', 'Dançam antes do acasalamento', 'Vivem em grupos familiares'],
        correctIndex: 2,
      ),
    ],
    'Borboleta': [
      Question(
        question: 'Qual é a principal função das borboletas na natureza?',
        options: ['Produzir mel', 'Ajudar na polinização', 'Caçar insetos', 'Comer folhas'],
        correctIndex: 1,
      ),
      Question(
        question: 'Qual fase NÃO faz parte do ciclo de vida da borboleta?',
        options: ['Ovo', 'Larva', 'Casulo', 'Peixe'],
        correctIndex: 3,
      ),
      Question(
        question: 'Como as borboletas se alimentam?',
        options: ['Comem carne', 'Sugam néctar com a probóscide', 'Mastigam folhas', 'Bebem água'],
        correctIndex: 1,
      ),
      Question(
        question: 'O que acontece na fase da pupa (crisálida)?',
        options: ['A borboleta morre', 'A borboleta hiberna', 'A metamorfose acontece', 'A borboleta põe ovos'],
        correctIndex: 2,
      ),
      Question(
        question: 'O que as borboletas usam para sentir o gosto?',
        options: ['Asas', 'Olhos', 'Patas', 'Antenas'],
        correctIndex: 2,
      ),
    ],
    'Barbeiro': [
      Question(
        question: 'Por que o barbeiro é perigoso?',
        options: [
          'Ele pica e transmite a Doença de Chagas',
          'Tem veneno mortal',
          'Causa alergias severas',
          'Se alimenta de plantas tóxicas'
        ],
        correctIndex: 0,
      ),
      Question(
        question: 'O que o barbeiro suga para se alimentar?',
        options: ['Sangue', 'Seiva de plantas', 'Água', 'Veneno'],
        correctIndex: 0,
      ),
      Question(
        question: 'Qual é o principal causador da Doença de Chagas?',
        options: ['Bactéria', 'Fungo', 'Protozoário', 'Vírus'],
        correctIndex: 2,
      ),
      Question(
        question: 'Onde os barbeiros costumam se esconder?',
        options: ['Embaixo da água', 'Em frestas e ninhos', 'Nas árvores', 'No ar'],
        correctIndex: 1,
      ),
      Question(
        question: 'Quantas fases tem o ciclo de vida do barbeiro?',
        options: ['3', '5', '7', '9'],
        correctIndex: 1,
      ),
    ],
    'Abelha': [
      Question(
        question: 'Qual a principal função das abelhas para o meio ambiente?',
        options: ['Fazer mel', 'Polinizar plantas', 'Caçar insetos', 'Produzir geleia real'],
        correctIndex: 1,
      ),
      Question(
        question: 'Como as abelhas se comunicam?',
        options: ['Através de danças', 'Pelo canto', 'Com sinais de luz', 'Pelo cheiro'],
        correctIndex: 0,
      ),
      Question(
        question: 'O que a abelha rainha faz?',
        options: ['Produz mel', 'Põe ovos', 'Defende a colmeia', 'Poliniza flores'],
        correctIndex: 1,
      ),
      Question(
        question: 'Qual o nome do alimento produzido pelas abelhas?',
        options: ['Cera', 'Pólen', 'Mel', 'Seiva'],
        correctIndex: 2,
      ),
      Question(
        question: 'Quantas asas uma abelha tem?',
        options: ['2', '4', '6', '8'],
        correctIndex: 1,
      ),
    ],
    'Aranha': [
      Question(
        question: 'As aranhas pertencem a qual grupo de animais?',
        options: ['Insetos', 'Répteis', 'Aracnídeos', 'Anfíbios'],
        correctIndex: 2,
      ),
      Question(
        question: 'O que a aranha usa para produzir teia?',
        options: ['Boca', 'Glândulas abdominais', 'Patas', 'Olhos'],
        correctIndex: 1,
      ),
      Question(
        question: 'Qual o nome das partes que a aranha usa para injetar veneno?',
        options: ['Patas', 'Quelíceras', 'Garras', 'Asas'],
        correctIndex: 1,
      ),
      Question(
        question: 'Quantos olhos a maioria das aranhas possui?',
        options: ['2', '4', '6', '8'],
        correctIndex: 3,
      ),
      Question(
        question: 'Como as caranguejeiras se defendem?',
        options: ['Fugindo', 'Soltando pelos urticantes', 'Atacando humanos', 'Fazendo barulho'],
        correctIndex: 1,
      ),
    ],

    'Cobra': [
      Question(
        question: 'Qual é o nome popular da Subordem Serpentes?',
        options: ['Lagartos', 'Cobras', 'Minhocas', 'Crocodilos'],
        correctIndex: 1,
      ),
      Question(
        question: 'Qual é a característica distintiva da língua das cobras?',
        options: ['Curta e grossa', 'Bífida (dupla)', 'Com dentes', 'Com pelos'],
        correctIndex: 1,
      ),
      Question(
        question: 'Como as cobras se defendem da maioria das pragas?',
        options: ['Pondo ovos', 'Troca periódica da pele (ecdises)', 'Se escondendo', 'Comendo insetos'],
        correctIndex: 1,
      ),
      Question(
        question: 'Que tipo de veneno a cascavel possui?',
        options: ['Citotóxico', 'Hemotóxico', 'Neurotóxico', 'Cardiotóxico'],
        correctIndex: 2,
      ),
      Question(
        question: 'Qual é a maior serpente do mundo em massa, nativa do Brasil?',
        options: ['Jiboia', 'Coral-verdadeira', 'Jararaca', 'Sucuri'],
        correctIndex: 3,
      ),
    ],
    'Camaleão': [
      Question(
        question: 'Qual é a principal característica dos camaleões?',
        options: ['Voar', 'Correr rápido', 'Mudar de cor', 'Cavar túneis'],
        correctIndex: 2,
      ),
      Question(
        question: 'O que permite que os olhos do camaleão se movam independentemente?',
        options: ['Músculos fracos', 'Articulações especiais', 'Visão monocular', 'Flexibilidade das pálpebras'],
        correctIndex: 2,
      ),
      Question(
        question: 'Qual o comprimento da língua do camaleão em relação ao seu corpo?',
        options: ['Metade do corpo', 'Igual ao corpo', 'Até 1.5 vezes o corpo', 'Duas vezes o corpo'],
        correctIndex: 2,
      ),
      Question(
        question: 'Além da camuflagem, para que mais os camaleões mudam de cor?',
        options: ['Para caçar', 'Para se esconder de predadores', 'Para regulação da temperatura e comunicação social', 'Para beber água'],
        correctIndex: 2,
      ),
      Question(
        question: 'Qual é o principal item da dieta dos camaleões?',
        options: ['Plantas', 'Frutas', 'Pequenos mamíferos', 'Insetos'],
        correctIndex: 3,
      ),
    ],
    'Mosca': [
      Question(
        question: 'O que significa o nome da ordem das moscas, "Diptera"?',
        options: ['Quatro asas', 'Duas patas', 'Duas asas', 'Seis patas'],
        correctIndex: 2,
      ),
      Question(
        question: 'Qual é a função dos halteres nas moscas?',
        options: ['Capturar presas', 'Ajudar no equilíbrio', 'Produzir som', 'Sentir o cheiro'],
        correctIndex: 1,
      ),
      Question(
        question: 'Como é o aparelho bucal da mosca?',
        options: ['Com presas', 'Adaptado para morder', 'Adaptado para sugar ou lamber', 'Com garras'],
        correctIndex: 2,
      ),
      Question(
        question: 'Qual das seguintes espécies de mosca é amplamente utilizada em pesquisas científicas?',
        options: ['Mosca-doméstica', 'Mosca-varejeira', 'Mosca-da-fruta', 'Mosca-dos-cavalos'],
        correctIndex: 2,
      ),
      Question(
        question: 'Além de decompositoras, qual outro papel ecológico importante muitas moscas desempenham?',
        options: ['Predadoras de mamíferos', 'Polinizadoras', 'Produtoras de seda', 'Construtoras de ninhos'],
        correctIndex: 1,
      ),
    ],
  };
}
