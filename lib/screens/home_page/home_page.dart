import 'package:flutter/material.dart';
import 'package:vision_app_3d/screens/home_page/home_page_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomePageController _ctrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = HomePageController(context);
    _ctrl.init(); // primeira vez: prompt curto
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ctrl.init();
    } else if (state == AppLifecycleState.paused) {
      _ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFEAB08A),
                child: const Icon(Icons.bug_report,
                    size: 50, color: Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 15),
              const Text(
                'Vision App',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bem-vindo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Obrigado por utilizar o Vision App, um aplicativo dedicado a promover o aprendizado sobre o mundo dos insetos de forma inclusiva, para explorar e descobrir informações sobre diferentes espécies de insetos, com recursos em áudio, vídeos e através da experiência com as mãos. Viva uma experiência interessante.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) {
          final cmd = (i == 0) ? 'escanear' : 'lista';
          _ctrl.handleVoiceCommand(cmd);
        },
        backgroundColor: const Color(0xFFEAB08A),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
        ],
      ),
    );
  }
}
