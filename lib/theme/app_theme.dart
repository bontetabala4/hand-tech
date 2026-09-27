import 'package:flutter/material.dart';

class AppTheme {
  // Primary Background : #808080 (Standard Gray)
  static const Color primaryBackground = Color(0xFF808080);
  
  // Surface / Cards : #666666 à #4D4D4D
  static const Color surfaceColor = Color(0xFF666666);
  static const Color surfaceDarkColor = Color(0xFF4D4D4D);
  
  // Secondary / Accent : #38BDF8 (Bleu Ciel)
  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentBlueLight = Color(0xFF7DD3FC);
  
  // Text Primary : #FFFFFF
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  // Text Secondary : #E0F2FE
  static const Color textSecondary = Color(0xFFE0F2FE);
  
  // Hardware Status
  static const Color statusConnected = Color(0xFF4ADE80);
  static const Color statusWarning = Color(0xFFFBBF24);
  static const Color statusDisconnected = Color(0xFFF87171);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: primaryBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        brightness: Brightness.dark, // Using dark brightness for white text defaults
        surface: surfaceColor,
        primary: accentBlue,
        onPrimary: textPrimary,
        secondary: accentBlueLight,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        displayLarge: TextStyle(color: textPrimary, fontSize: 40, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: textSecondary, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Color(0xFF111827), // Dark icon on light blue
      ),
    );
  }
}
