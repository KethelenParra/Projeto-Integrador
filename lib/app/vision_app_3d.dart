import 'package:flutter/material.dart';
import '../screens/home_page/home_page.dart';
import 'package:vision_app_3d/main.dart';

class VisionApp3D extends StatelessWidget {
  const VisionApp3D({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vision App',
      navigatorObservers: [routeObserver],
      home: const HomePage(),
    );
  }
}
