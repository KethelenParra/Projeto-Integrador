import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../screens/qr_view_exemple.dart';
import '../screens/insect_list_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late FlutterTts _flutterTts;
  int _selectedIndex = 0; // Exibe a tela de boas-vindas por padrão

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _speakFallbackText();
  }

  Future<void> _speakFallbackText() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(
      "Obrigado por utilizar o Vision App, um aplicativo dedicado a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descubrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante. Na parte inferior da tela haverá duas opções de comandos de voz para navegar. Basta dizer: lista, para acessar a tela com todas as opções de insetos ou: escanear, para abrir a tela de QR Code e obter informações detalhadas sobre o inseto escaneado.",
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Ao tocar em "Escanear", navega para a tela QRViewExample
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRViewExample(),
        ),
      ).then((_) {
        _speakFallbackText(); // Reproduz novamente a mensagem ao retornar
      });
    } else if (index == 1) {
      // Ao tocar em "Lista", atualiza o estado para exibir a tela de lista de insetos
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define as duas telas:
    // 1. Tela de boas-vindas (sem o botão "Iniciar")
    // 2. Tela com a lista de insetos
    final List<Widget> _screens = [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFEAB08A),
                child: Icon(
                  Icons.bug_report,
                  size: 50,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Vision App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Obrigado por utilizar o Vision App, um aplicativo dedicado a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descubrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      const InsectListScreen(), // Tela de lista de insetos
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFEAB08A),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Escanear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lista',
          ),
        ],
      ),
    );
  }
}

