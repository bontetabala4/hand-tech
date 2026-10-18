import 'package:flutter/material.dart';

class HandTechStrings {
  const HandTechStrings(this.isEnglish);

  final bool isEnglish;

  String get appSubtitle =>
      isEnglish ? 'IA Vision Assistive' : 'IA Vision Assistive';
  String get signInDescription => isEnglish
      ? 'More accessible communication, at your fingertips.'
      : 'Une communication plus accessible, à portée de main.';
  String get continueWithoutAccount =>
      isEnglish ? 'Continue without an account' : 'Continuer sans compte';
  String get signInOptional => isEnglish
      ? 'Google sign-in is optional to try the translation tools.'
      : 'La connexion Google est facultative pour essayer les outils de traduction.';
  String get googleSignInInitializationError => isEnglish
      ? 'Unable to initialize Google sign-in'
      : 'Initialisation de la connexion Google impossible';
  String get googleSignInError =>
      isEnglish ? 'Google sign-in error' : 'Erreur de connexion Google';
  String get googleSignInImpossible => isEnglish
      ? 'Unable to sign in with Google'
      : 'Connexion Google impossible';
  String get signOutError =>
      isEnglish ? 'Unable to sign out' : 'Déconnexion impossible';
  String get tabTranslation => isEnglish ? 'Translate' : 'Traduction';
  String get tabNolan => 'Nolan';
  String get tabSensors => isEnglish ? 'Devices' : 'Capteurs';
  String get tabSettings => isEnglish ? 'Settings' : 'Réglages';
  String get tabHistory => isEnglish ? 'History' : 'Historique';
  String get historyTitle =>
      isEnglish ? 'Translation history' : 'Historique des traductions';
  String get historyEmpty => isEnglish
      ? 'Your translations will appear here.'
      : 'Tes traductions apparaîtront ici.';
  String get historyLocalOnly => isEnglish
      ? 'History is stored only on this device and is linked to your Google account.'
      : 'L’historique est enregistré uniquement sur cet appareil et associé à ton compte Google.';
  String get historyRequiresAccount => isEnglish
      ? 'Sign in with Google to keep a translation history. Guest translations are not saved.'
      : 'Connecte-toi avec Google pour conserver ton historique. Les traductions en mode invité ne sont pas enregistrées.';
  String get historySignRecognitionPending => isEnglish
      ? 'Sign recognition is not connected yet, so there is no recognition history to save.'
      : 'La reconnaissance des signes n’est pas encore connectée : aucun historique de reconnaissance ne peut être enregistré.';
  String get historySaveError => isEnglish
      ? 'Could not save this translation to history.'
      : 'Impossible d’enregistrer cette traduction dans l’historique.';
  String get clearHistory =>
      isEnglish ? 'Clear history' : 'Effacer l’historique';
  String get historyCleared =>
      isEnglish ? 'History cleared.' : 'Historique effacé.';
  String get historyClearError =>
      isEnglish ? 'Could not clear history.' : 'Impossible d’effacer l’historique.';
  String get sourceText => isEnglish ? 'Original' : 'Texte original';
  String get translatedText => isEnglish ? 'Translation' : 'Traduction';
  String get frenchCode => 'FR';
  String get englishCode => 'EN';
  String formatHistoryDate(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
  String get phoneCamera => isEnglish ? 'Phone camera' : 'Caméra du téléphone';
  String get cameraUsedInTranslation => isEnglish
      ? 'The camera is used in the Translate tab.'
      : 'La caméra est utilisée dans l’onglet Traduction.';
  String get handTechSensor =>
      isEnglish ? 'HandTech BLE sensor' : 'Capteur HandTech BLE';
  String get noExternalSensor => isEnglish
      ? 'No external sensor is connected.'
      : 'Aucun capteur externe n’est connecté.';
  String get speechSynthesis =>
      isEnglish ? 'Text-to-speech' : 'Synthèse vocale';
  String get speechRate => isEnglish ? 'Speech rate' : 'Vitesse de lecture';
  String get textTranslation =>
      isEnglish ? 'Text translation' : 'Traduction de texte';
  String get mlKitDescription => isEnglish
      ? 'Google ML Kit on-device. Models download on first use.'
      : 'Google ML Kit sur l’appareil. Les modèles sont téléchargés à la première utilisation.';
  String get signInWithGoogle =>
      isEnglish ? 'Sign in with Google' : 'Se connecter avec Google';
  String get signOut => isEnglish ? 'Sign out' : 'Se déconnecter';
  String get language => isEnglish ? 'App language' : 'Langue de l’application';
  String get french => isEnglish ? 'French' : 'Français';
  String get english => isEnglish ? 'English' : 'Anglais';
  String get appearance => isEnglish ? 'Appearance' : 'Apparence';
  String get theme => isEnglish ? 'Theme' : 'Thème';
  String get light => isEnglish ? 'Light' : 'Clair';
  String get dark => isEnglish ? 'Dark' : 'Sombre';
  String get cameraReady => isEnglish ? 'Camera ready' : 'Caméra active';
  String get cameraOpening =>
      isEnglish ? 'Opening camera…' : 'Ouverture de la caméra…';
  String get cameraUnavailable =>
      isEnglish ? 'Camera unavailable' : 'Caméra indisponible';
  String get cameraStopped => isEnglish ? 'Camera off' : 'Caméra arrêtée';
  String get cameraPermissionDenied => isEnglish
      ? 'Allow camera access in your phone settings.'
      : 'Autorisez l’accès à la caméra dans les réglages du téléphone.';
  String get cameraAccessRestricted => isEnglish
      ? 'Camera access is restricted on this device.'
      : 'L’accès à la caméra est restreint sur cet appareil.';
  String get cameraOffTooltip =>
      isEnglish ? 'Turn camera off' : 'Éteindre la caméra';
  String get cameraOnTooltip =>
      isEnglish ? 'Turn camera on' : 'Allumer la caméra';
  String get switchCamera => isEnglish ? 'Switch camera' : 'Basculer la caméra';
  String get connectSignLanguageApi => isEnglish
      ? 'Sign language AI API not connected'
      : 'API IA LSF à connecter';
  String get framingArea => isEnglish ? 'Framing area' : 'Zone de cadrage';
  String get signRecognition =>
      isEnglish ? 'Sign-language recognition' : 'Reconnaissance LSF';
  String get signRecognitionNotConfigured => isEnglish
      ? 'The camera is ready, but no sign-language AI API is configured. Signs are not interpreted yet. The API transcription will appear here once its connection contract is defined.'
      : 'La caméra est prête, mais aucune API IA LSF n’est configurée. Les signes filmés ne sont pas interprétés. La transcription de l’API apparaîtra ici lorsque son contrat de connexion sera défini.';
  String get apiToConfigure => isEnglish
      ? 'Translation API not configured'
      : 'API de traduction à configurer';
  String get libreTranslate => isEnglish ? 'LibreTranslate' : 'LibreTranslate';
  String get swapLanguages =>
      isEnglish ? 'Swap languages' : 'Inverser les langues';
  String get translationUnavailable => isEnglish
      ? 'The online translation service is not configured. Set TRANSLATION_API_URL to the HTTPS /translate endpoint.'
      : 'Le service de traduction en ligne n’est pas configuré. Définissez TRANSLATION_API_URL avec l’adresse HTTPS de /translate.';
  String get enterText =>
      isEnglish ? 'Enter text to translate' : 'Saisissez le texte à traduire';
  String get clearText => isEnglish ? 'Clear text' : 'Effacer le texte';
  String get translate => isEnglish ? 'Translate' : 'Traduire';
  String get preparingTranslation =>
      isEnglish ? 'Preparing translation…' : 'Préparation de la traduction…';
  String get translating => isEnglish ? 'Translating…' : 'Traduction en cours…';
  String downloadingModel(String language) => isEnglish
      ? 'Downloading $language model…'
      : 'Téléchargement du modèle $language…';
  String get noCameraAvailable =>
      isEnglish ? 'No camera is available.' : 'Aucune caméra disponible.';
  String get result => isEnglish ? 'Result' : 'Résultat';
  String get reading => isEnglish ? 'Speaking…' : 'Lecture…';
  String get readAloud => isEnglish ? 'Read aloud' : 'Lire à voix haute';
  String get copy => isEnglish ? 'Copy' : 'Copier';
  String get translationCopied =>
      isEnglish ? 'Translation copied.' : 'Traduction copiée.';
  String get speechError =>
      isEnglish ? 'Text-to-speech failed' : 'Synthèse vocale impossible';
  String get inputRequired =>
      isEnglish ? 'Enter text to translate.' : 'Saisissez un texte à traduire.';
  String get translationError => isEnglish
      ? 'Translation failed. Check your internet connection and try again.'
      : 'Traduction impossible. Vérifiez votre connexion Internet et réessayez.';
  String get cameraUnavailableError =>
      isEnglish ? 'No camera is available.' : 'Aucune caméra disponible.';
  String get cameraOpenError =>
      isEnglish ? 'Unable to open camera' : 'Ouverture de la caméra impossible';
  String get cameraPermissionError => isEnglish
      ? 'Allow camera access in your phone settings.'
      : 'Autorisez l’accès à la caméra dans les réglages du téléphone.';
  String get cameraRestrictedError => isEnglish
      ? 'Camera access is restricted on this device.'
      : 'L’accès à la caméra est restreint sur cet appareil.';
  String get unknownCause => isEnglish ? 'unknown cause' : 'cause inconnue';
  String get futureSignDetectionHelp => isEnglish
      ? 'For future sign detection, keep your hands in frame and use front lighting.'
      : 'Pour une future détection LSF, gardez les mains dans le cadre et privilégiez une lumière frontale.';
  String get nolanGreeting => isEnglish
      ? 'Hello! I’m Nolan, your accessibility assistant. How can I help you?'
      : 'Bonjour ! Je suis Nolan, ton assistant dédié à l’accessibilité. Comment puis-je t’aider ?';
  String get nolanDescription => isEnglish
      ? 'Ask me about accessibility, disability, or inclusive communication.'
      : 'Pose-moi tes questions sur l’accessibilité, le handicap ou la communication inclusive.';
  String get nolanInputHint =>
      isEnglish ? 'Write a message…' : 'Écris un message…';
  String get nolanHeaderSubtitle =>
      isEnglish ? 'ACCESSIBILITY ASSISTANT' : 'ASSISTANT ACCESSIBILITÉ';
  String get nolanSend => isEnglish ? 'Send' : 'Envoyer';
  String get nolanWorking => isEnglish ? 'Nolan is thinking…' : 'Nolan réfléchit…';
  String get nolanConnectionError => isEnglish
      ? 'Nolan could not answer. Check your connection and try again.'
      : 'Nolan n’a pas pu répondre. Vérifie ta connexion et réessaie.';
  String get nolanSuggestionAccessibility => isEnglish
      ? 'What is digital accessibility?'
      : 'Qu’est-ce que l’accessibilité numérique ?';
  String get nolanSuggestionCommunication => isEnglish
      ? 'How can I communicate inclusively?'
      : 'Comment communiquer de façon inclusive ?';
  String get nolanSuggestionRights => isEnglish
      ? 'What is a reasonable accommodation?'
      : 'Qu’est-ce qu’un aménagement raisonnable ?';

  String cameraError(String code, String? description) => isEnglish
      ? 'Camera error ($code): ${description ?? unknownCause}'
      : 'Erreur caméra ($code) : ${description ?? unknownCause}';

  String cameraOpenFailed(Object error) => '$cameraOpenError: $error';

  String translationFailed(Object error) => '$translationError Details: $error';

  String speechFailed(Object error) => '$speechError: $error';

  String getLanguageName(String code) => switch (code) {
    'fr' => french,
    'en' => english,
    'es' => isEnglish ? 'Spanish' : 'Espagnol',
    'de' => isEnglish ? 'German' : 'Allemand',
    'it' => isEnglish ? 'Italian' : 'Italien',
    'pt' => isEnglish ? 'Portuguese' : 'Portugais',
    _ => code,
  };
}

class HandTechSettingsScope extends InheritedWidget {
  const HandTechSettingsScope({
    required this.isEnglish,
    required this.isDarkTheme,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required super.child,
    super.key,
  });

  final bool isEnglish;
  final bool isDarkTheme;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  HandTechStrings get strings => HandTechStrings(isEnglish);

  static HandTechSettingsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HandTechSettingsScope>()!;

  @override
  bool updateShouldNotify(HandTechSettingsScope oldWidget) =>
      isEnglish != oldWidget.isEnglish || isDarkTheme != oldWidget.isDarkTheme;
}
