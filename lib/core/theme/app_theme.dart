import 'package:flutter/material.dart';

class AppTheme {
  // Genius Aesthetic Colors
  static const background = Color(0xFF0D0B14); // Deep space purple-black
  static const sidebarBackground = Color(0xFF16121E); // Slightly lighter purple-black
  
  static const primary = Color(0xFF6B4EE0); // Royal Purple
  static const secondary = Color(0xFFD4AF37); // Classic Gold
  static const tertiary = Color(0xFFB8C0D2); // Silver/Platinum
  
  static const accent = Color(0xFF9F7AEA); // Light Purple/Lavender
  static const error = Color(0xFFF56565);
  static const success = Color(0xFF48BB78);

  static const textPrimary = Color(0xFFF7FAFC); 
  static const textSecondary = Color(0xFFA0AEC0);
  static const neutral = Color(0xFF4A5568);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Segoe UI', // Clean, professional system font for Windows

    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: sidebarBackground,
      error: error,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
      bodySmall: TextStyle(color: textSecondary, fontSize: 12),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: sidebarBackground,
      hintStyle: const TextStyle(color: neutral),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
  );
}