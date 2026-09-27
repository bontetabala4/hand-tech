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
    return const Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                HardwareHeader(),
                Expanded(
                  child: LiveTranscriptionView(),
                ),
                AudioControlBar(),
              ],
            ),
            // Floating Overlay (Camera Preview PiP)
            Positioned(
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
