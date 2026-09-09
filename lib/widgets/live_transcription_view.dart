import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/translation_provider.dart';

class LiveTranscriptionView extends ConsumerWidget {
  const LiveTranscriptionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider);
    final text = translationState.liveText;
    final isUncertain = translationState.lastConfidence < 0.8 || !translationState.isFinal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: SingleChildScrollView(
        reverse: true, // Auto-scroll to bottom
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Inter', // Fallback to system sans-serif if not loaded
              fontSize: 34,
              color: AppTheme.textPrimary,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            children: _buildTranscriptionSpans(text, isUncertain),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildTranscriptionSpans(String text, bool isUncertain) {
    if (text.isEmpty) return [];
    
    final words = text.split(' ');
    if (words.length == 1) {
      return [
        TextSpan(
          text: text, 
          style: TextStyle(color: isUncertain ? AppTheme.accentBlue : AppTheme.textPrimary)
        )
      ];
    }
    
    final previousWords = words.sublist(0, words.length - 1).join(' ');
    final lastWord = words.last;
    
    return [
      TextSpan(text: '$previousWords '),
      TextSpan(
        text: lastWord,
        style: TextStyle(color: isUncertain ? AppTheme.accentBlue : AppTheme.textPrimary),
      ),
    ];
  }
}
