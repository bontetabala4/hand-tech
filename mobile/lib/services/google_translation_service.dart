import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class GoogleTranslationService {
  GoogleTranslationService({
    http.Client? client,
    String? translationApiUrl,
  }) : _client = client ?? http.Client(),
       _translationApiUrl =
           translationApiUrl ??
           const String.fromEnvironment('TRANSLATION_API_URL');

  final http.Client _client;
  final String _translationApiUrl;

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  bool get isOnDeviceSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isRemoteConfigured => _translationApiUrl.trim().isNotEmpty;

  bool get isSupported => isOnDeviceSupported || isRemoteConfigured;

  bool get usesRemoteTranslation => !isOnDeviceSupported;

  Future<String> translate({
    required String text,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    ValueChanged<String>? onStatusChanged,
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(
        text,
        'text',
        'Le texte ne peut pas être vide.',
      );
    }
    if (sourceLanguage == targetLanguage) return text.trim();
    if (isOnDeviceSupported) {
      return _translateOnDevice(
        text: text.trim(),
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        onStatusChanged: onStatusChanged,
      );
    }
    if (!isRemoteConfigured) {
      throw UnsupportedError(
        'Aucune API de traduction n’est configurée pour cette plateforme.',
      );
    }

    return _translateRemotely(
      text: text.trim(),
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      onStatusChanged: onStatusChanged,
    );
  }

  Future<String> _translateOnDevice({
    required String text,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    ValueChanged<String>? onStatusChanged,
  }) async {
    for (final language in [sourceLanguage, targetLanguage]) {
      final languageCode = language.bcpCode;
      if (!await _modelManager.isModelDownloaded(languageCode)) {
        onStatusChanged?.call('downloading:${language.bcpCode}');
        await _modelManager.downloadModel(languageCode, isWifiRequired: false);
      }
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    try {
      onStatusChanged?.call('translating');
      return await translator.translateText(text.trim());
    } finally {
      await translator.close();
    }
  }

  Future<String> _translateRemotely({
    required String text,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    ValueChanged<String>? onStatusChanged,
  }) async {
    final uri = Uri.tryParse(_translationApiUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' && _isLocalHost(uri.host)))) {
      throw const FormatException(
        'TRANSLATION_API_URL doit être une URL HTTPS valide.',
      );
    }

    onStatusChanged?.call('translating');
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'q': text,
            'source': sourceLanguage.bcpCode,
            'target': targetLanguage.bcpCode,
            'format': 'text',
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Le service de traduction a répondu HTTP ${response.statusCode}.',
        uri,
      );
    }

    final Object? payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'Le service de traduction a renvoyé une réponse invalide.',
      );
    }
    if (payload is! Map<String, dynamic> ||
        payload['translatedText'] is! String ||
        (payload['translatedText'] as String).trim().isEmpty) {
      throw const FormatException(
        'La réponse du service ne contient pas de traduction.',
      );
    }
    return (payload['translatedText'] as String).trim();
  }

  bool _isLocalHost(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';

  void dispose() => _client.close();
}
