import 'package:vibration/vibration.dart';

class VibrationService {
  Future<void> vibrate({int duration = 100}) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration);
    }
  }
}