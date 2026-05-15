import 'package:flutter/material.dart';

class AppTheme {
  // Ineffa Aesthetic Colors (Genshin-inspired)
  static const background = Color(0xFF2B4150); // Dark Blue-Gray (Deep background)
  static const sidebarBackground = Color(0xFF1F2F3B); // Slightly darker for depth
  
  static const primary = Color(0xFFD0E8EA); // Pale Cyan (Main highlights/robot shell)
  static const secondary = Color(0xFFCBCFD0); // Light Gray (Neutral/Mechanical)
  static const tertiary = Color(0xFFCABBDF); // Lavender (Soft glow/accent)
  
  static const accent = Color(0xFFCABBDF); // Lavender
  static const error = Color(0xFFFF9A9A); // Soft Red
  static const success = Color(0xFFB5EAD7); // Minty Green

  static const textPrimary = Color(0xFFD0E8EA); 
  static const textSecondary = Color(0xFFCBCFD0);
  static const neutral = Color(0xFF6B8A9E); // Muted Blue-Gray

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
      onPrimary: background,
      onSurface: textPrimary,
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
        foregroundColor: background, // High contrast
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