class Insect {
  final String name; // Nome do inseto
  final String description; // Descrição do inseto
  final String videoPath; // Caminho do vídeo

  const Insect({
    required this.name,
    required this.videoPath,
    required this.description,
  });
}

final Map<String, Insect> insectData = {
  'https://me-qr.com/0A5HBr4R': Insect(
    name: 'Escorpião',
    description:
    'Os escorpiões, artrópodes da ordem Scorpiones, possuem corpo segmentado, pinças e cauda articulada com aguilhão venenoso. Existindo há mais de 400 milhões de anos, habitam desertos, florestas, savanas e áreas urbanas em todos os continentes, exceto na Antártica.\n'
        '\nMorfologia e Característica\n'
        'Dividem-se em prosoma (cabeça e pinças), mesossoma (abdômen) e metassoma (cauda). As pinças capturam presas e a cauda injeta veneno.\n'
        '\nHábitos e Comportamento\n'
        'Nocturnos e carnívoros, caçam insetos e aranhas. A maioria das espécies não é letal, mas o Tityus serrulatus, comum no Brasil, possui veneno perigoso.\n'
        '\nReprodução e Ciclo de Vida\n'
        'Reproduzem-se via dança do acasalamento. A fêmea dá à luz filhotes vivos, que sobem em seu dorso. Vivem de 3 a 8 anos, passando por mudas até a maturidade.\n'
        '\nImportância Ecológica\n'
        'Controlam populações de insetos e seu veneno é estudado para medicamentos.\n'
        '\nEspécies\n'
        'Tityus serrulatus (Brasil), Pandinus imperator (África), Androctonus australis (Oriente Médio).\n'
        '\nCuriosidades\n'
        ' 1. Escorpiões brilham sob luz ultravioleta devido a substâncias presentes em sua carapaça.\n'
        ' 2. Eles são extremamente resistentes, sendo capazes de sobreviver a radiações que seriam letais para outros seres vivos.\n'
        ' 3. Apesar de serem solitários, podem exibir comportamento parental, especialmente no cuidado com os filhotes.',
    videoPath: 'lib/assets/videos/inseto.mp4',
  ),
  'https://me-qr.com/g6D9jaMj': Insect(
    name: 'Borboleta',
    description:
    'As borboletas são insetos da ordem Lepidoptera, conhecidas por asas coloridas e ciclo de vida fascinante. São encontradas em todos os continentes, exceto na Antártica, habitando florestas, campos e áreas urbanas.\n'
        '\nMorfologia e Características\n'
        'Possuem corpo dividido em cabeça, tórax e abdômen. Suas asas são cobertas por escamas coloridas e antenas sensíveis ao cheiro. A boca adaptada em forma de probóscide suga néctar.\n'
        '\nHábitos e Comportamento\n'
        'Ativas durante o dia, alimentam-se de néctar e ajudam na polinização. Algumas espécies são migratórias, como a borboleta-monarca, que percorre grandes distâncias.\n'
        '\nCiclo de Vida\n'
        'O ciclo é dividido em quatro fases: ovo, lagarta (fase de alimentação), pupa (crisálida, onde ocorre a metamorfose) e adulto. A vida adulta dura dias ou semanas, dependendo da espécie.\n'
        '\nImportância Ecológica\n'
        'As borboletas são fundamentais para a polinização e indicadoras da saúde ambiental.\n'
        '\nEspécies\n'
        'Monarca (Danaus plexippus), Caligo (olho-de-coruja) e Morpho azul, famosa por seu brilho iridescente.\n'
        '\nCuriosidades\n'
        ' 1. Embora pareçam coloridas, as asas das borboletas são na verdade transparentes. As escamas minúsculas que as revestem refletem a luz, criando as cores vibrantes que vemos.\n'
        ' 2. As borboletas sentem o gosto com os pés, elas possuem sensores gustativos em suas patas, permitindo que detectem o sabor das plantas ao pousarem, ajudando-as a identificar locais ideais para colocar ovos.\n'
        ' 3. Borboletas não conseguem ver a cor vermelha, mas possuem uma visão altamente desenvolvida para tons de azul, verde e ultravioleta, essenciais para encontrar flores e parceiros.',
    videoPath: 'lib/assets/videos/inseto2.mp4',
  ),
  'https://me-qr.com/8Mw6s4W6': Insect(
    name: 'Barbeiro',
    description:
    'Os barbeiros são insetos hematófagos da ordem Hemiptera, conhecidos por serem vetores da Doença de Chagas, causada pelo protozoário Trypanosoma cruzi. São encontrados principalmente na América Latina, em ambientes rurais e urbanos.\n'
        '\nMorfologia e Características\n'
        'Dividem-se em cabeça, tórax e abdômen. Possuem um rostro (aparelho bucal) especializado para perfurar a pele e sugar sangue. Seu corpo é achatado e de coloração escura com detalhes alaranjados ou avermelhados.\n'
        '\nHábitos e Comportamento\n'
        'São predominantemente noturnos e vivem em locais escuros, como frestas, ninhos de aves e tocas de animais. Alimentam-se de sangue de mamíferos, aves e répteis. Durante a picada, defecam próximo à área da pele, transmitindo o protozoário Trypanosoma cruzi.\n'
        '\nReprodução e Ciclo de Vida\n'
        'A reprodução é sexuada, com a fêmea depositando ovos após o acasalamento. O ciclo de vida inclui três fases: ovo, ninfa (cinco estágios) e adulto. Podem viver entre 1 e 2 anos dependendo do ambiente e da disponibilidade de alimento.\n'
        '\nImportância Ecológica\n'
        'Embora sejam conhecidos como pragas devido ao risco de transmissão da Doença de Chagas, barbeiros desempenham papel no controle de populações de outros artrópodes e são indicadores de desequilíbrios ambientais.\n'
        '\nEspécies\n'
        '- Triatoma vitticeps (Brasil)\n'
        '- Triatoma infestans (América do Sul)\n'
        '- Rhodnius prolixus (América Central e do Sul)\n'
        '\nCuriosidades\n'
        ' 1. Barbeiros são chamados assim devido à tendência de picar o rosto de suas vítimas.\n'
        ' 2. Apesar da má reputação, nem todas as espécies transmitem a Doença de Chagas.\n'
        ' 3. Seu comportamento discreto e ciclo de vida adaptável dificultam o controle populacional.',
    videoPath: 'lib/assets/videos/inseto3.mp4',
  ),
  'https://qr.me-qr.com/OX4GHmyo': Insect(
    name: 'Abelha',
    description: 'Abelhas (Superfamília Apoidea)\n'
        'As abelhas são insetos himenópteros intimamente ligados à polinização, desempenhando um papel crucial nos ecossistemas e na agricultura. Existem cerca de 20.000 espécies conhecidas, distribuídas por todos os continentes, exceto na Antártica.\n'
        '\nMorfologia e Características\n'
        'O corpo das abelhas é dividido em cabeça, tórax e abdômen. Possuem antenas, olhos compostos e um aparelho bucal adaptado para sugar néctar. No tórax, têm três pares de patas e dois pares de asas membranosas. Muitas espécies possuem ferrão, usado para defesa.\n'
        '\nHábitos e Comportamento\n'
        'As abelhas são diurnas e exibem comportamento social ou solitário. As espécies sociais, como a Apis mellifera (abelha-europeia), vivem em colmeias organizadas em castas: rainha, operárias e zangões. Alimentam-se de néctar e pólen, desempenhando um papel essencial na polinização de plantas.\n'
        '\nReprodução e Ciclo de Vida \n'
        'A rainha é responsável pela reprodução, colocando ovos que se desenvolvem em operárias, zangões ou novas rainhas, dependendo do tipo de cuidado e alimentação. O ciclo de vida varia entre espécies, mas a maioria vive algumas semanas (operárias) a alguns anos (rainhas)._\n'
        '\nImportância Ecológica\n'
        'As abelhas são polinizadoras fundamentais, garantindo a reprodução de inúmeras espécies de plantas e a produção de alimentos. Além disso, produzem mel, cera, própolis e geleia real, utilizados na alimentação e em produtos medicinais.\n'
        '\nEspécies\n'
        '- Apis mellifera (abelha-europeia, utilizada na apicultura) \n'
        '- Bombus terrestris (abelhão, importante polinizador) \n'
        '- Trigona spinipes (abelha-sem-ferrão, nativa do Brasil)\n'
        '\nCuriosidades\n'
        ' 1. Abelhas conseguem comunicar a localização de flores através da dança das abelhas. \n'
        ' 2. Uma colmeia pode abrigar até 60.000 abelhas durante o pico da temporada.  \n'
        ' 3. Abelhas-sem-ferrão, comuns no Brasil, são inofensivas e produzem mel com sabor diferenciado.',
    videoPath: 'lib/assets/videos/inseto4.mp4',
  ),
  'https://qr.me-qr.com/4IggFMux': Insect(
    name: 'Aranha',
    description: 'Aranhas Caranguejeiras (Família Theraphosidae)\n'
        'As aranhas caranguejeiras são aracnídeos de grande porte conhecidos por sua aparência imponente e comportamento geralmente dócil. Encontradas em todo o mundo, são particularmente abundantes em regiões tropicais e subtropicais.\n'
        '\nMorfologia e Características\n'
        'O corpo das caranguejeiras é dividido em cefalotórax (prosoma) e abdômen (opistossoma), cobertos por pelos sensoriais. Possuem quelíceras robustas com presas que inoculam veneno, além de oito patas articuladas e olhos simples (ocelos) que oferecem visão limitada.\n'
        '\nHábitos e Comportamento\n'
        'São predominantemente terrestres, mas algumas espécies vivem em árvores ou escavam tocas no solo. Geralmente noturnas, têm hábitos predadores e alimentam-se de insetos, pequenos répteis e até mamíferos, dependendo da espécie. Apesar de seu tamanho e aparência assustadora, raramente atacam humanos.\n'
        '\nReprodução e Ciclo de Vida\n'
        'O macho realiza uma dança de acasalamento para conquistar a fêmea, que pode atacá-lo após o processo. A fêmea deposita os ovos em um casulo de seda, e os filhotes permanecem protegidos até a primeira muda. A longevidade varia: machos vivem cerca de 5 anos, enquanto fêmeas podem viver até 20 anos.\n'
        '\nImportância Ecológica\n'
        'As caranguejeiras controlam populações de insetos e outros pequenos animais. Além disso, seu veneno está sendo pesquisado para aplicações médicas, como analgésicos.\n'
        '\nEspécies\n'
        '- Lasiodora parahybana (caranguejeira-salmon-pink, Brasil)  \n'
        '- Gammostola rosea (caranguejeira-rosa-do-Chile, América do Sul) \n'
        '- Poecilotheria regalis (caranguejeira-ornamental-indiana, Ásia)\n'
        '\nCuriosidades\n'
        ' 1. Algumas espécies lançam pelos urticantes do abdômen como forma de defesa. \n'
        ' 2. Apesar de possuírem veneno, as caranguejeiras raramente são perigosas para humanos. \n'
        ' 3. Suas presas são capazes de perfurar a pele, mas a mordida geralmente é comparada a uma picada de abelha.',
    videoPath: 'lib/assets/videos/inseto5.mp4',
  ),
};