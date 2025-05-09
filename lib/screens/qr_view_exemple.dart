// lib/screens/qr_view_example.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../data/data_manager.dart';
import '../data/data_definition.dart';
import 'insect_details_screen.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final MobileScannerController _scannerController = MobileScannerController();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isScanCompleted = false;

  // Mapa de QR code para o `id` do inseto no banco
  static const Map<String, int> _qrToId = {
    'https://me-qr.com/0A5HBr4R': 1,
    'https://me-qr.com/g6D9jaMj': 2,
    'https://me-qr.com/8Mw6s4W6': 3,
    'https://qr.me-qr.com/OX4GHmyo': 4,
    'https://qr.me-qr.com/4IggFMux': 5,
  };

  @override
  void initState() {
    super.initState();
    _speakInstructions();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _speakInstructions() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(
      "Aponte o celular para o QR Code. Coloque o QR Code na área demarcada. A leitura será feita automaticamente.",
    );
  }

  void _resetScanner() {
    _isScanCompleted = false;
    _flutterTts.stop();
    _speakInstructions();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanCompleted) return;

    final code = capture.barcodes.first.rawValue ?? '';
    if (code.isEmpty) return;

    final manager = Provider.of<DataManager>(context, listen: false);

    if (_qrToId.containsKey(code)) {
      _isScanCompleted = true;
      await _flutterTts.stop();
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }

      final inseto = await manager.getInsetoById(_qrToId[code]!);
      if (inseto != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InsectDetailsScreen(inseto: inseto),
          ),
        );
        _resetScanner();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inseto não encontrado no banco!')),
        );
        _resetScanner();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code não reconhecido: $code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE6D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAB08A),
        title: const Text('Escaneie o QR Code', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () async {
            // Marcar como async para usar await aqui
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(duration: 100);
            }
            await _flutterTts.stop();
            Navigator.pop(context);
            _resetScanner();
          },
        ),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                "Coloque o QR Code na área demarcada\nA leitura será feita automaticamente",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 4), borderRadius: BorderRadius.circular(12)),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) => _onDetect(capture),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Developed by Estudantes",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
