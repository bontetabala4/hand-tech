import 'package:flutter/widgets.dart';

import 'google_sign_in_action_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_action_web.dart' as platform;

class GoogleSignInAction extends StatelessWidget {
  const GoogleSignInAction({
    required this.isLoading,
    required this.isWeb,
    required this.isEnglish,
    required this.onPressed,
    super.key,
  });

  final bool isLoading;
  final bool isWeb;
  final bool isEnglish;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return platform.buildGoogleSignInAction(
      isLoading: isLoading,
      isWeb: isWeb,
      isEnglish: isEnglish,
      onPressed: onPressed,
    );
  }
}
