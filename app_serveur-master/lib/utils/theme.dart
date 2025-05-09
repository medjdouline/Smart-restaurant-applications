// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFFE9B975); // Beige/doré
  static const Color secondaryColor = Color(0xFF245536); // Vert
  static const Color accentColor = Color(0xFFAA2C10); // Rouge/marron
  static const Color inputBgColor = Color(0xFFDB9051); // Marron clair

  // Thème global
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: secondaryColor,
        secondary: accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: accentColor.withAlpha(179)), // Fixed deprecated withOpacity(0.7)
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: accentColor,
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: accentColor,
          fontSize: 18,
        ),
      ),
    );
  }
}