import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_wrapper.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HandTechApp(),
    ),
  );
}

class HandTechApp extends StatelessWidget {
  const HandTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hand Tech',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
