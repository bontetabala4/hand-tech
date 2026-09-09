import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/hardware_header.dart';
import '../widgets/live_transcription_view.dart';
import '../widgets/camera_preview_pip.dart';
import '../widgets/audio_control_bar.dart';

class GlassesDashboardScreen extends ConsumerWidget {
  const GlassesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const HardwareHeader(),
                const Expanded(
                  child: LiveTranscriptionView(),
                ),
                const AudioControlBar(),
              ],
            ),
            // Floating Overlay (Camera Preview PiP)
            const Positioned(
              top: 100,
              right: 16,
              child: CameraPreviewPip(),
            ),
          ],
        ),
      ),
    );
  }
}
