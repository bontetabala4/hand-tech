import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

Widget buildGoogleSignInAction({
  required bool isLoading,
  required bool isWeb,
  required bool isEnglish,
  required VoidCallback onPressed,
}) {
  if (isLoading) {
    return const SizedBox(
      height: 54,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  if (!isWeb) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.login),
        label: const Text('Continuer avec Google'),
      ),
    );
  }

  return SizedBox(
    width: double.infinity,
    height: 54,
    child: renderButton(
      configuration: GSIButtonConfiguration(
        theme: GSIButtonTheme.filledBlue,
        size: GSIButtonSize.large,
        text: GSIButtonText.continueWith,
        shape: GSIButtonShape.pill,
        locale: isEnglish ? 'en' : 'fr',
      ),
    ),
  );
}
