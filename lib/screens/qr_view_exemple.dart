import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Importar o pacote para leitura de texto
import 'insect_details_screen.dart';
import 'package:vision_app_3d/screens/inserct.dart'; // Importar a classe Insect e o mapeamento insectData

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final MobileScannerController controller = MobileScannerController();
  final FlutterTts _flutterTts = FlutterTts(); // Instância do TTS
  bool isScanCompleted = false;

  @override
  void initState() {
    super.initState();
    _speakInstructions(); // Lê o texto assim que a tela é aberta
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Para o TTS ao sair da tela
    super.dispose();
  }

  Future<void> _speakInstructions() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(
      "Aponte o celular para o QR Code. Coloque o QR Code na área demarcada. A leitura será feita automaticamente.",
    );
  }

  void closeScreen() {
    isScanCompleted = false;
    _flutterTts.stop(); // Para o TTS caso um código seja detectado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text(
          'Escaneie o QR Code',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _flutterTts.stop(); // Interrompe qualquer leitura
            Navigator.pop(context); // Volta para a tela anterior
            _speakInstructions(); // Reproduz as instruções ao retornar
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Coloque o QR Code na área demarcada",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "A leitura será feita automaticamente",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (barcodeCapture) {
                        if (!isScanCompleted) {
                          final String code = barcodeCapture.barcodes.first.rawValue ?? '';
                          print('Código escaneado: $code'); // Log para depuração
                          if (insectData.containsKey(code)) {
                            final insect = insectData[code]!;
                            isScanCompleted = true;
                            _flutterTts.stop(); // Para o TTS ao navegar para outra tela
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InsectDetailsScreen(
                                  insect: insect,
                                ),
                              ),
                            ).then((_) {
                              closeScreen(); // Reseta a tela após a navegação
                              _speakInstructions(); // Reproduz as instruções novamente
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('QR Code não reconhecido: $code')),
                            );
                          }
                        }
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                "Developed by Estudantes",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
