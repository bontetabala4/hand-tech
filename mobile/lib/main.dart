import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_settings.dart';
import 'google_oauth_config.dart';
import 'services/app_preferences_service.dart';
import 'screens/nolan_chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/translation_screen.dart';
import 'widgets/google_sign_in_action.dart';

const _primary = Color.fromARGB(255, 158, 176, 204);
const _secondary = Color.fromARGB(255, 0, 104, 122);
const _surface = Color.fromARGB(255, 250, 248, 255);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await AppPreferencesService().load();
  runApp(HandTechApp(preferences: preferences));
}

class HandTechApp extends StatefulWidget {
  const HandTechApp({required this.preferences, super.key});

  final AppPreferences preferences;

  @override
  State<HandTechApp> createState() => _HandTechAppState();
}

class _HandTechAppState extends State<HandTechApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _preferencesService = AppPreferencesService();
  late bool _isEnglish = widget.preferences.isEnglish;
  late bool _isDarkTheme = widget.preferences.isDarkTheme;

  void _setLanguage(bool isEnglish) {
    setState(() => _isEnglish = isEnglish);
    unawaited(
      _persistPreference(() => _preferencesService.saveLanguage(isEnglish)),
    );
  }

  void _setTheme(bool isDarkTheme) {
    setState(() => _isDarkTheme = isDarkTheme);
    unawaited(
      _persistPreference(() => _preferencesService.saveTheme(isDarkTheme)),
    );
  }

  Future<void> _persistPreference(Future<void> Function() save) async {
    try {
      await save();
    } catch (error, stackTrace) {
      debugPrint('Failed to save HandTech preferences: $error\n$stackTrace');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Could not save your settings.'
                : 'Impossible d’enregistrer les réglages.',
          ),
        ),
      );
    }
  }

  ThemeData _buildTheme({required bool dark}) {
    final primary = dark ? const Color(0xFF69F4E5) : _primary;
    final secondary = dark ? const Color(0xFF4B91FF) : _secondary;
    final surface = dark ? const Color(0xFF05080D) : _surface;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: surface,
      primary: primary,
      secondary: secondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: surface,
      colorScheme: scheme,
      textTheme: dark
          ? Typography.material2021().white.apply(
              bodyColor: const Color(0xFF8FF5EA),
              displayColor: const Color(0xFF61A9FF),
            )
          : null,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: dark
            ? const Color(0xFF8FF5EA)
            : const Color(0xFF131B2E),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF111720) : Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark ? const Color(0xFF23465E) : const Color(0xFFC2C6D9),
            width: 0.4,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF101923) : const Color(0xFFF2F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'HandTech',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(dark: false),
      darkTheme: _buildTheme(dark: true),
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: HandTechSettingsScope(
        isEnglish: _isEnglish,
        isDarkTheme: _isDarkTheme,
        onLanguageChanged: _setLanguage,
        onThemeChanged: _setTheme,
        child: const _AuthenticationGate(),
      ),
    );
  }
}

class _AuthenticationGate extends StatefulWidget {
  const _AuthenticationGate();

  @override
  State<_AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<_AuthenticationGate> {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _accountSubscription;
  GoogleSignInAccount? _account;
  bool _isGuest = false;
  bool _isLoading = true;
  String? _error;
  HandTechStrings get _strings =>
      context.getInheritedWidgetOfExactType<HandTechSettingsScope>()!.strings;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        clientId: kIsWeb ? googleWebClientId : null,
        serverClientId: kIsWeb ? null : googleWebClientId,
      );
      _accountSubscription = _googleSignIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: _handleAuthenticationError,
      );

      final restoration = _googleSignIn.attemptLightweightAuthentication();
      final account = restoration == null ? null : await restoration;
      if (!mounted) return;
      setState(() {
        _account = account;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '${_strings.googleSignInInitializationError}: $error';
        _isLoading = false;
      });
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted) return;
    final account = switch (event) {
      GoogleSignInAuthenticationEventSignIn(:final user) => user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };
    setState(() {
      _account = account;
      _isLoading = false;
      _error = null;
    });
  }

  void _handleAuthenticationError(Object error) {
    if (!mounted) return;
    setState(() {
      _error = '${_strings.googleSignInError}: $error';
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isGuest = false;
    });
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email'],
      );
      if (!mounted) return;
      setState(() {
        _account = account;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '${_strings.googleSignInImpossible}: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    if (_account != null) {
      try {
        await _googleSignIn.signOut();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_strings.signOutError}: $error')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _account = null;
      _isGuest = false;
    });
  }

  void _continueAsGuest() {
    setState(() => _isGuest = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('logo.jpeg', width: 180, height: 180),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    final account = _account;
    if (account != null || _isGuest) {
      return _HandTechShell(
        account: account,
        onSignIn: _signIn,
        onSignOut: _signOut,
        isEnglish: HandTechSettingsScope.of(context).isEnglish,
        isDarkTheme: HandTechSettingsScope.of(context).isDarkTheme,
        onLanguageChanged: HandTechSettingsScope.of(context).onLanguageChanged,
        onThemeChanged: HandTechSettingsScope.of(context).onThemeChanged,
      );
    }

    return _SignInScreen(
      error: _error,
      onSignIn: _signIn,
      onContinueAsGuest: _continueAsGuest,
      isLoading: _isLoading,
      isWeb: kIsWeb,
    );
  }
}

class _SignInScreen extends StatelessWidget {
  const _SignInScreen({
    required this.error,
    required this.onSignIn,
    required this.onContinueAsGuest,
    required this.isLoading,
    required this.isWeb,
  });

  final String? error;
  final VoidCallback onSignIn;
  final VoidCallback onContinueAsGuest;
  final bool isLoading;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('logo.jpeg', width: 92, height: 92),
                  const SizedBox(height: 20),
                  Text(
                    'HandTech',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    HandTechSettingsScope.of(context).strings.signInDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF424656),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (error != null) ...[
                    _ErrorNotice(message: error!),
                    const SizedBox(height: 16),
                  ],
                  GoogleSignInAction(
                    isLoading: isLoading,
                    isWeb: isWeb,
                    isEnglish: HandTechSettingsScope.of(context).isEnglish,
                    onPressed: onSignIn,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isLoading ? null : onContinueAsGuest,
                    child: Text(
                      HandTechSettingsScope.of(
                        context,
                      ).strings.continueWithoutAccount,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    HandTechSettingsScope.of(context).strings.signInOptional,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF424656),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HandTechShell extends StatefulWidget {
  const _HandTechShell({
    required this.account,
    required this.onSignIn,
    required this.onSignOut,
    required this.isEnglish,
    required this.isDarkTheme,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final GoogleSignInAccount? account;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;
  final bool isEnglish;
  final bool isDarkTheme;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<_HandTechShell> createState() => _HandTechShellState();
}

class _HandTechShellState extends State<_HandTechShell> {
  int _selectedIndex = 0;
  double _speechRate = 0.48;

  @override
  Widget build(BuildContext context) {
    final strings = HandTechSettingsScope.of(context).strings;
    final pages = <Widget>[
      TranslationScreen(
        account: widget.account,
        speechRate: _speechRate,
        isEnglish: widget.isEnglish,
      ),
      NolanChatScreen(
        account: widget.account,
        isEnglish: widget.isEnglish,
      ),
      _SensorsScreen(account: widget.account),
      _SettingsScreen(
        account: widget.account,
        speechRate: _speechRate,
        isEnglish: widget.isEnglish,
        isDarkTheme: widget.isDarkTheme,
        onSpeechRateChanged: (rate) => setState(() => _speechRate = rate),
        onLanguageChanged: widget.onLanguageChanged,
        onThemeChanged: widget.onThemeChanged,
        onSignIn: widget.onSignIn,
        onSignOut: widget.onSignOut,
      ),
    ];
    if (widget.account case final account?) {
      pages.add(HistoryScreen(account: account, isEnglish: widget.isEnglish));
    }

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: strings.tabTranslation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: strings.tabNolan,
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: strings.tabSensors,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: strings.tabSettings,
          ),
          if (widget.account != null)
            NavigationDestination(
              icon: const Icon(Icons.history),
              selectedIcon: const Icon(Icons.history_toggle_off),
              label: strings.tabHistory,
            ),
        ],
      ),
    );
  }
}

class _SensorsScreen extends StatelessWidget {
  const _SensorsScreen({required this.account});

  final GoogleSignInAccount? account;

  @override
  Widget build(BuildContext context) {
    final strings = HandTechSettingsScope.of(context).strings;
    return _PageFrame(
      title: strings.tabSensors,
      account: account,
      children: [
        _InfoCard(
          icon: Icons.camera_alt_outlined,
          title: strings.phoneCamera,
          detail: strings.cameraUsedInTranslation,
          color: _primary,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.bluetooth_searching,
          title: strings.handTechSensor,
          detail: strings.noExternalSensor,
          color: _secondary,
        ),
      ],
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    required this.account,
    required this.speechRate,
    required this.isEnglish,
    required this.isDarkTheme,
    required this.onSpeechRateChanged,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.onSignIn,
    required this.onSignOut,
  });

  final GoogleSignInAccount? account;
  final double speechRate;
  final bool isEnglish;
  final bool isDarkTheme;
  final ValueChanged<double> onSpeechRateChanged;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = HandTechSettingsScope.of(context).strings;
    return _PageFrame(
      title: strings.tabSettings,
      account: account,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.speechSynthesis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(strings.speechRate),
                Slider(
                  value: speechRate,
                  min: 0.25,
                  max: 0.75,
                  divisions: 10,
                  label: speechRate.toStringAsFixed(2),
                  onChanged: onSpeechRateChanged,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.translate,
          title: strings.textTranslation,
          detail: strings.mlKitDescription,
          color: _primary,
        ),
        if (account == null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.history,
            title: strings.tabHistory,
            detail: strings.historyRequiresAccount,
            color: _secondary,
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.language,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(strings.french),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(strings.english),
                    ),
                  ],
                  selected: {isEnglish},
                  onSelectionChanged: (selection) =>
                      onLanguageChanged(selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.appearance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(strings.light),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(strings.dark),
                    ),
                  ],
                  selected: {isDarkTheme},
                  onSelectionChanged: (selection) =>
                      onThemeChanged(selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: account == null ? onSignIn : onSignOut,
          icon: Icon(account == null ? Icons.login : Icons.logout),
          label: Text(
            account == null ? strings.signInWithGoogle : strings.signOut,
          ),
        ),
      ],
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.account,
    required this.children,
  });

  final String title;
  final GoogleSignInAccount? account;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
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
                  Text(title),
                ],
              ),
            ),
            if (account case final signedInAccount?)
              _AccountAvatar(account: signedInAccount)
            else
              const CircleAvatar(
                backgroundColor: Color(0xFFDBE1FF),
                child: Icon(Icons.person_outline, color: _primary),
              ),
          ],
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.secondary
                  : color,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.account});

  final GoogleSignInAccount account;

  @override
  Widget build(BuildContext context) {
    final photoUrl = account.photoUrl;
    if (photoUrl != null) {
      return CircleAvatar(
        foregroundImage: NetworkImage(photoUrl),
        child: Text(_initials(account.displayName ?? account.email)),
      );
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFFDBE1FF),
      child: Text(
        _initials(account.displayName ?? account.email),
        style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
      ),
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

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

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
