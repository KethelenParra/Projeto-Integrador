import 'package:flutter/material.dart';
import 'package:vision_app_3d/screens/insect.dart';
import 'insect_list_controller.dart';

class InsectListScreen extends StatefulWidget {
  const InsectListScreen({Key? key}) : super(key: key);

  @override
  _InsectListScreenState createState() => _InsectListScreenState();
}

class _InsectListScreenState extends State<InsectListScreen>
    with WidgetsBindingObserver {
  late final InsectListController _ctrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = InsectListController(context);
    _ctrl.init();
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text('Lista de Insetos',
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => _ctrl.handleVoiceCommand('voltar'),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Fale ou toque em um inseto para ver mais informações.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: insectData.length,
              itemBuilder: (context, i) {
                final ins = insectData.values.elementAt(i);
                return Card(
                  color: Colors.white,
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(ins.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onTap: () =>
                        _ctrl.handleVoiceCommand(ins.name.toLowerCase()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
