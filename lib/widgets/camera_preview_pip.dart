import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/camera_provider.dart';

class CameraPreviewPip extends ConsumerStatefulWidget {
  const CameraPreviewPip({super.key});

  @override
  ConsumerState<CameraPreviewPip> createState() => _CameraPreviewPipState();
}

class _CameraPreviewPipState extends ConsumerState<CameraPreviewPip> {
  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    final size = MediaQuery.of(context).size;
    
    final isStreaming = cameraState.status == CameraStatus.streaming;
    
    final targetWidth = cameraState.isExpanded ? (size.width * 0.7) : (size.width * 0.25);
    final targetHeight = targetWidth * 1.5;

    return Semantics(
      button: true,
      label: cameraState.isExpanded
          ? 'Expanded camera preview overlay'
          : 'Collapsed camera preview overlay',
      hint: 'Double tap to toggle picture in picture size',
      child: GestureDetector(
        onTap: () {
          ref.read(cameraProvider.notifier).togglePiP();
        },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: targetWidth,
        height: targetHeight,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDarkColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentBlue,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                isStreaming ? Icons.videocam : Icons.videocam_off,
                color: AppTheme.textSecondary,
                size: cameraState.isExpanded ? 64 : 32,
              ),
            ),
            
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isStreaming)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                    
                  if (isStreaming)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${cameraState.currentFps} FPS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
