import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import 'theme.dart';

class VisionApp3D extends StatelessWidget {
  const VisionApp3D({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision App',
      theme: appTheme,
      home: const HomePage(),
    );
  }
}
