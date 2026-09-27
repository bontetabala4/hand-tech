import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/haptic_feedback_service.dart';
import '../data/services/tts_service.dart';

// Mock state providers for hardware telemetry

final glassBatteryLevelProvider = StateProvider<int>((ref) => 85);
final isCameraActiveProvider = StateProvider<bool>((ref) => true);
final isBluetoothConnectedProvider = StateProvider<bool>((ref) => true);

// For live transcription, we use a StateProvider for demo purposes
final liveTranscriptionTextProvider = StateProvider<String>(
  (ref) => 'Bonjour, comment allez-vous aujourd\'hui ?',
);

// Gesture detection toggle state
final isGestureDetectionActiveProvider = StateProvider<bool>((ref) => true);

// Audio output toggle (Glasses vs. Phone Speaker)
// true = Glasses, false = Phone Speaker
final isAudioOutputToGlassesProvider = StateProvider<bool>((ref) => true);

final hapticServiceProvider = Provider<HapticFeedbackService>((ref) {
  return FlutterHapticFeedbackService();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return FlutterTtsService();
});
