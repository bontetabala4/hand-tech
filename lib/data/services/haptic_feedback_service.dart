import 'package:flutter/services.dart';

abstract class HapticFeedbackService {
  Future<void> selectionClick();
  Future<void> successNotification();
  Future<void> warningNotification();
  Future<void> errorNotification();
}

class FlutterHapticFeedbackService implements HapticFeedbackService {
  @override
  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  @override
  Future<void> successNotification() async {
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> warningNotification() async {
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> errorNotification() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
