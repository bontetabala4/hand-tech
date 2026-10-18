import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_settings.dart';
import '../services/google_translation_service.dart';
import '../services/speech_service.dart';
import '../services/translation_history_service.dart';

const _primary = Color(0xFF004CCA);
const _secondary = Color(0xFF00687A);
const _surfaceLow = Color(0xFFF2F3FF);

class _LanguageOption {
  const _LanguageOption(this.name, this.language, this.speechCode);

  final String name;
  final TranslateLanguage language;
  final String speechCode;
}

const _languages = <_LanguageOption>[
  _LanguageOption('Français', TranslateLanguage.french, 'fr-FR'),
  _LanguageOption('Anglais', TranslateLanguage.english, 'en-US'),
  _LanguageOption('Espagnol', TranslateLanguage.spanish, 'es-ES'),
  _LanguageOption('Allemand', TranslateLanguage.german, 'de-DE'),
  _LanguageOption('Italien', TranslateLanguage.italian, 'it-IT'),
  _LanguageOption('Portugais', TranslateLanguage.portuguese, 'pt-PT'),
];

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({
    required this.account,
    required this.speechRate,
    required this.isEnglish,
    super.key,
  });

  final GoogleSignInAccount? account;
  final double speechRate;
  final bool isEnglish;

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen>
    with WidgetsBindingObserver {
  final _inputController = TextEditingController();
  final _translationService = GoogleTranslationService();
  final _speechService = SpeechService();
  final _historyService = TranslationHistoryService();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  _LanguageOption _source = _languages.first;
  _LanguageOption _target = _languages[1];
  String? _translatedText;
  String? _cameraError;
  String? _translationError;
  String? _translationStatus;
  bool _isTranslating = false;
  bool _isSpeaking = false;
  bool _useFrontCamera = false;
  bool _isCameraEnabled = true;
  bool _isOpeningCamera = false;

  HandTechStrings get _strings => HandTechStrings(widget.isEnglish);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputController.dispose();
    _cameraController?.dispose();
    _translationService.dispose();
    _speechService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _cameraController;
      _cameraController = null;
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_isCameraEnabled) _startCamera();
    }
  }

  Future<void> _startCamera() async {
    if (!_isCameraEnabled || _isOpeningCamera) return;
    _isOpeningCamera = true;
    try {
      final cameras = await availableCameras();
      if (!mounted || !_isCameraEnabled) return;
      if (cameras.isEmpty) {
        setState(() => _cameraError = _strings.noCameraAvailable);
        return;
      }
      _cameras = cameras;
      await _openSelectedCamera();
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = _cameraErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _cameraError = _strings.cameraOpenFailed(error),
      );
    } finally {
      _isOpeningCamera = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openSelectedCamera() async {
    if (!_isCameraEnabled || _cameras.isEmpty) return;
    final direction = _useFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final camera = _cameras.firstWhere(
      (candidate) => candidate.lensDirection == direction,
      orElse: () => _cameras.first,
    );
    final oldController = _cameraController;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _cameraController = controller;
    await oldController?.dispose();

    try {
      await controller.initialize();
      if (!mounted || !_isCameraEnabled || _cameraController != controller) {
        return;
      }
      setState(() => _cameraError = null);
    } on CameraException catch (error) {
      if (_cameraController != controller) return;
      _cameraController = null;
      if (mounted) setState(() => _cameraError = _cameraErrorMessage(error));
      await controller.dispose();
    } catch (error) {
      if (_cameraController != controller) return;
      _cameraController = null;
      if (mounted) {
        setState(
          () => _cameraError = _strings.cameraOpenFailed(error),
        );
      }
      await controller.dispose();
    }
  }

  Future<void> _toggleCamera() async {
    if (_isOpeningCamera) return;
    setState(() => _useFrontCamera = !_useFrontCamera);
    await _openSelectedCamera();
  }

  Future<void> _toggleCameraPower() async {
    if (_isOpeningCamera && !_isCameraEnabled) return;
    if (_isCameraEnabled) {
      final controller = _cameraController;
      setState(() {
        _isCameraEnabled = false;
        _cameraController = null;
        _cameraError = null;
      });
      await controller?.dispose();
      return;
    }

    setState(() {
      _isCameraEnabled = true;
      _cameraError = null;
    });
    await _startCamera();
  }

  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _translationError = _strings.inputRequired);
      return;
    }

    setState(() {
      _isTranslating = true;
      _translationError = null;
      _translationStatus = _strings.preparingTranslation;
      _translatedText = null;
    });
    try {
      final result = await _translationService.translate(
        text: text,
        sourceLanguage: _source.language,
        targetLanguage: _target.language,
        onStatusChanged: (status) {
          if (!mounted) return;
          setState(
            () => _translationStatus = status == 'translating'
                ? _strings.translating
                : _strings.downloadingModel(
                    _strings.getLanguageName(status.split(':').last),
                  ),
          );
        },
      );
      if (!mounted) return;
      setState(() => _translatedText = result);
      final account = widget.account;
      if (account != null) {
        try {
          await _historyService.add(
            account.email,
            TranslationHistoryEntry(
              text: text,
              translatedText: result,
              sourceLanguage: _source.language.bcpCode,
              targetLanguage: _target.language.bcpCode,
              createdAt: DateTime.now(),
            ),
          );
        } catch (error) {
          if (mounted) {
            _showMessage('${_strings.historySaveError} $error');
          }
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _translationError = error is UnsupportedError
            ? _strings.translationUnavailable
            : _strings.translationFailed(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationStatus = null;
        });
      }
    }
  }

  Future<void> _speak() async {
    final text = _translatedText;
    if (text == null || text.isEmpty) return;
    setState(() => _isSpeaking = true);
    try {
      await _speechService.speak(
        text: text,
        languageCode: _target.speechCode,
        rate: widget.speechRate,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_strings.speechFailed(error));
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _swapLanguages() {
    setState(() {
      final previousSource = _source;
      _source = _target;
      _target = previousSource;
      _translatedText = null;
      _translationError = null;
    });
  }

  Future<void> _copyTranslation() async {
    final text = _translatedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showMessage(_strings.translationCopied);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildHeader(context),
        const SizedBox(height: 14),
        _buildCameraCard(context),
        const SizedBox(height: 12),
        _buildRecognitionNotice(context),
        const SizedBox(height: 12),
        _buildTextTranslationCard(context),
        const SizedBox(height: 12),
        _buildHelpNote(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Image.asset('logo.jpeg', width: 40, height: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HandTech',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(_strings.appSubtitle),
            ],
          ),
        ),
        if (widget.account case final account?)
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFDBE1FF),
            foregroundImage: account.photoUrl == null
                ? null
                : NetworkImage(account.photoUrl!),
            child: account.photoUrl == null
                ? Text(_initials(account.displayName ?? account.email))
                : null,
          )
        else
          const CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFFDBE1FF),
            child: Icon(Icons.person_outline, color: _primary),
          ),
      ],
    );
  }

  Widget _buildCameraCard(BuildContext context) {
    final controller = _cameraController;
    final ready = controller?.value.isInitialized ?? false;
    final String framingMessage;
    if (_cameraError != null) {
      framingMessage = _cameraError!;
    } else if (!_isCameraEnabled) {
      framingMessage = _strings.cameraStopped;
    } else if (_isOpeningCamera) {
      framingMessage = _strings.cameraOpening;
    } else {
      framingMessage = '${_strings.framingArea}\n${_strings.connectSignLanguageApi}';
    }
    final cameraStatus = ready
        ? _strings.cameraReady
        : _isOpeningCamera
        ? _strings.cameraOpening
        : _isCameraEnabled
        ? _strings.cameraUnavailable
        : _strings.cameraStopped;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: const Color(0xFF283044),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              CameraPreview(controller!)
            else
              const Center(
                child: Icon(Icons.videocam, color: Colors.white54, size: 54),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.48),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.60),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _StatusChip(
                    icon: ready
                        ? Icons.circle
                        : _isCameraEnabled
                        ? Icons.info_outline
                        : Icons.videocam_off,
                    text: cameraStatus,
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        onPressed:
                            ready && _cameras.length > 1 && !_isOpeningCamera
                            ? _toggleCamera
                            : null,
                        tooltip: _strings.switchCamera,
                        icon: const Icon(Icons.flip_camera_android),
                      ),
                      const SizedBox(height: 4),
                      IconButton.filledTonal(
                        onPressed: _isOpeningCamera
                            ? null
                            : _toggleCameraPower,
                        tooltip: _isCameraEnabled
                            ? _strings.cameraOffTooltip
                            : _strings.cameraOnTooltip,
                        icon: Icon(
                          _isCameraEnabled
                              ? Icons.videocam_off
                              : Icons.videocam,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF57DFFE).withValues(alpha: 0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Text(
                  framingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: _StatusChip(
                icon: Icons.auto_awesome,
                text: _strings.connectSignLanguageApi,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecognitionNotice(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _strings.signRecognition,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_strings.signRecognitionNotConfigured),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTranslationCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _strings.textTranslation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _translationService.isOnDeviceSupported
                      ? 'Google ML Kit'
                      : _translationService.isRemoteConfigured
                      ? _strings.libreTranslate
                      : _strings.apiToConfigure,
                  style: const TextStyle(color: _secondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _languageDropdown(
                    value: _source,
                    isEnabled: !_isTranslating,
                    onChanged: (language) {
                      if (language != null) {
                        setState(() {
                          _source = language;
                          _translatedText = null;
                          _translationError = null;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: _isTranslating ? null : _swapLanguages,
                  tooltip: _strings.swapLanguages,
                  icon: const Icon(Icons.swap_horiz, color: _primary),
                ),
                Expanded(
                  child: _languageDropdown(
                    value: _target,
                    isEnabled: !_isTranslating,
                    onChanged: (language) {
                      if (language != null) {
                        setState(() {
                          _target = language;
                          _translatedText = null;
                          _translationError = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_translationService.isSupported) ...[
              _InlineError(message: _strings.translationUnavailable),
              const SizedBox(height: 12),
            ],
            if (widget.account == null) ...[
              Text(
                _strings.historyRequiresAccount,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _inputController,
              enabled: !_isTranslating,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _strings.enterText,
                suffixIcon: IconButton(
                  tooltip: _strings.clearText,
                  onPressed: _isTranslating
                      ? null
                      : () {
                          _inputController.clear();
                          setState(() {
                            _translatedText = null;
                            _translationError = null;
                          });
                        },
                  icon: const Icon(Icons.close),
                ),
              ),
              onChanged: (_) => setState(() {
                _translatedText = null;
                _translationError = null;
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isTranslating || !_translationService.isSupported
                    ? null
                    : _translate,
                icon: _isTranslating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate),
                label: Text(
                  _isTranslating
                      ? _translationStatus ?? _strings.translating
                      : _strings.translate,
                ),
              ),
            ),
            if (_translationError != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: _translationError!),
            ],
            if (_translatedText != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text(
                _strings.result,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _translatedText!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isSpeaking ? null : _speak,
                    icon: Icon(
                      _isSpeaking ? Icons.volume_up : Icons.play_arrow,
                    ),
                    label: Text(
                      _isSpeaking ? _strings.reading : _strings.readAloud,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyTranslation,
                    icon: const Icon(Icons.content_copy),
                    label: Text(_strings.copy),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _languageDropdown({
    required _LanguageOption value,
    required bool isEnabled,
    required ValueChanged<_LanguageOption?> onChanged,
  }) {
    return DropdownButtonFormField<_LanguageOption>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _languages
          .map(
            (language) => DropdownMenuItem(
              value: language,
              child: Text(
                _strings.getLanguageName(language.language.bcpCode),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isEnabled ? onChanged : null,
    );
  }

  Widget _buildHelpNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF101923)
            : _surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.accessibility_new, color: _primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(_strings.futureSignDetectionHelp),
          ),
        ],
      ),
    );
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
        return _strings.cameraPermissionDenied;
      case 'CameraAccessRestricted':
        return _strings.cameraAccessRestricted;
      default:
        return _strings.cameraError(error.code, error.description);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF283044).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFACEDFF), size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF93000A))),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
  return name.isEmpty ? '?' : name.characters.first.toUpperCase();
}
