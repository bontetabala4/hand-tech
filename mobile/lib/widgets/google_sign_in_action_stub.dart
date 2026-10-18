import 'package:flutter/material.dart';

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

  return SizedBox(
    width: double.infinity,
    height: 54,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.login),
      label: Text(
        isEnglish ? 'Continue with Google' : 'Continuer avec Google',
      ),
    ),
  );
}
