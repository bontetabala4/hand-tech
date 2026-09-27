import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/hardware_providers.dart';
import '../providers/translation_provider.dart';

class AudioControlBar extends ConsumerWidget {
  const AudioControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider);
    final isAudioToGlasses = ref.watch(isAudioOutputToGlassesProvider);
    
    final isListening = translationState.status == TranslationStatus.listening || 
                        translationState.status == TranslationStatus.translating;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Audio Output Toggle
          Semantics(
            label: isAudioToGlasses ? 'Audio output set to Smart Glasses' : 'Audio output set to Phone Speaker',
            hint: 'Double tap to toggle audio destination',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAudioToGlasses ? Icons.headphones : Icons.speaker_phone,
                  color: AppTheme.textSecondary,
                ),
                Switch(
                  value: isAudioToGlasses,
                  activeThumbColor: AppTheme.accentBlue,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(isAudioOutputToGlassesProvider.notifier).state = val;
                  },
                ),
              ],
            ),
          ),
          
          // Central FAB (Translation Toggle)
          Semantics(
            button: true,
            label: isListening ? 'Pause translation stream' : 'Start real-time sign language translation',
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(translationProvider.notifier).toggleTranslation();
              },
              child: Icon(
                isListening ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
          
          // Replay / Speech synthesis Button
          Semantics(
            button: true,
            label: 'Read out translation using text to speech',
            hint: 'Synthesizes audio speech of the current translation text',
            child: IconButton(
              icon: const Icon(Icons.volume_up),
              color: AppTheme.textSecondary,
              iconSize: 28,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(translationProvider.notifier).speakCurrentText();
              },
            ),
          ),
        ],
      ),
    );
  }
}
