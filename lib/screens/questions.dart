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

  // Gera variações de comandos de voz para cada opção
  static Map<String, List<String>> _generateOptionCommands(
      List<String> options) {
    Map<String, List<String>> commands = {};

    for (int i = 0; i < options.length; i++) {
      final number = i + 1;
      commands['opção $number'] = [
        // Variações específicas para o número 1
        if (number == 1) ...[
          'um',
          'hum',
          'primeiro',
          'primeira',
          'opção um',
          'opção hum',
          'alternativa um',
          'alternativa hum',
          'número um',
          'número hum',
          'primeira opção',
          'primeira alternativa',
        ],
        // Variações comuns para todos os números
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
      1: [
        'um',
        'hum',
        'primeiro',
        'primeira',
        'primeira opção',
        'primera opção',
        'primeira opição'
      ],
      2: [
        'dois',
        'duas',
        'segundo',
        'segunda',
        'segunda opção',
        'segunda opição'
      ],
      3: [
        'três',
        'tres',
        'terceiro',
        'terceira',
        'terceira opção',
        'terceira opição',
        'tercera opção',
        'tercera opição'
      ],
      4: ['quatro', 'quarta', 'quarto', 'quarta opção', 'quarta opição'],
    };
    return words[number]?.first ??
        number.toString(); // Retorna apenas a primeira variação
  }

  // Verifica se um comando de voz corresponde a uma opção
  int? matchVoiceCommand(String command) {
    command = command.toLowerCase().trim();
    print("Verificando comando: $command"); // Debug

    // Tratamento especial para o número "um"
    if (command == "um" || command == "hum") return 0;

    for (var entry in optionVoiceCommands.entries) {
      if (entry.value.any((variant) {
        // Divide a variante se contiver múltiplas opções (separadas por |)
        final variations = variant.toLowerCase().split('|');
        return variations.any((v) => command.contains(v.trim()));
      })) {
        return int.parse(entry.key.replaceAll('opção ', '')) - 1;
      }
    }
    return null;
  }

  /// Comandos de navegação (“próximo”, “anterior”, “confirmar”)
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
    'voltar pergunta': [
      'anterior',
      'voltar',
      'retornar',
      'questão anterior',
      'pergunta anterior'
    ],
    'finalizar': [
      'confirmar',
      'finalizar',
      'terminar',
      'concluir',
      'pronto',
      'terminei'
    ],
  };

  /// Retorna a chave do comando de navegação identificado, ou null
  static String? matchNavigationCommand(String command) {
    final cmd = command.toLowerCase();
    for (var entry in navigationCommands.entries) {
      if (entry.value.any((variant) => cmd.contains(variant))) {
        return entry.key;
      }
    }
    return null;
  }
}

class Questions {
  /// Mapa de perguntas categorizadas por nome de inseto.
  static final Map<String, List<Question>> questionsMap = {
    'Escorpião': [
      Question(
        question: 'Qual é a principal característica dos escorpiões?',
        options: [
          'Possuem asas',
          'Têm ferrão venenoso',
          'São mamíferos',
          'Vivem na água'
        ],
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
        options: [
          'Botam ovos',
          'Fazem metamorfose',
          'Dançam antes do acasalamento',
          'Vivem em grupos familiares'
        ],
        correctIndex: 2,
      ),
    ],
    'Borboleta': [
      Question(
        question: 'Qual é a principal função das borboletas na natureza?',
        options: [
          'Produzir mel',
          'Ajudar na polinização',
          'Caçar insetos',
          'Comer folhas'
        ],
        correctIndex: 1,
      ),
      Question(
        question: 'Qual fase NÃO faz parte do ciclo de vida da borboleta?',
        options: ['Ovo', 'Larva', 'Casulo', 'Peixe'],
        correctIndex: 3,
      ),
      Question(
        question: 'Como as borboletas se alimentam?',
        options: [
          'Comem carne',
          'Sugam néctar com a probóscide',
          'Mastigam folhas',
          'Bebem água'
        ],
        correctIndex: 1,
      ),
      Question(
        question: 'O que acontece na fase da pupa (crisálida)?',
        options: [
          'A borboleta morre',
          'A borboleta hiberna',
          'A metamorfose acontece',
          'A borboleta põe ovos'
        ],
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
        options: [
          'Embaixo da água',
          'Em frestas e ninhos',
          'Nas árvores',
          'No ar'
        ],
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
        options: [
          'Fazer mel',
          'Polinizar plantas',
          'Caçar insetos',
          'Produzir geleia real'
        ],
        correctIndex: 1,
      ),
      Question(
        question: 'Como as abelhas se comunicam?',
        options: [
          'Através de danças',
          'Pelo canto',
          'Com sinais de luz',
          'Pelo cheiro'
        ],
        correctIndex: 0,
      ),
      Question(
        question: 'O que a abelha rainha faz?',
        options: [
          'Produz mel',
          'Põe ovos',
          'Defende a colmeia',
          'Poliniza flores'
        ],
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
        question:
            'Qual o nome das partes que a aranha usa para injetar veneno?',
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
        options: [
          'Fugindo',
          'Soltando pelos urticantes',
          'Atacando humanos',
          'Fazendo barulho'
        ],
        correctIndex: 1,
      ),
    ],
  };
}
