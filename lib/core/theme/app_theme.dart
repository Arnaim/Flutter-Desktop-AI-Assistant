import 'package:flutter/material.dart';
import '../models/mood.dart';

class AppTheme {
  // Base Ineffa Colors
 // static const background = Color(0xFF2B4150); // Dark Blue-Gray
  static const sidebarBackground = Color(0xFF1F2F3B); // Slightly darker
  static const textPrimary = Color(0xFFFFFFFF); // Pure White
  static const textSecondary = Color(0xFFE0E0E0); // Off-White
  static const neutral = Color(0xFF90A4AE); // Muted Blue-Gray
  static const error = Color(0xFFFF9A9A);
  static const success = Color(0xFFB5EAD7);
  
  // Static references for existing UI components
  static const primary = Color(0xFFD0E8EA); // Pale Cyan
  static const secondary = Color(0xFFCBCFD0); // Light Gray
  static const tertiary = Color(0xFFCABBDF); // Lavender

  static ThemeData getThemeData(Mood mood) {
    Color background;
  //  Color bgColor;
    Color surfaceColor;

    switch (mood) {
      case Mood.happy:
        background = const Color(0xFF81C784); // Soft Green
    //    bgColor = const Color(0xFF263326); // Dark Greenish-Gray
        surfaceColor = const Color(0xFF1B261B);
        break;
      case Mood.affectionate:
        background = const Color(0xFFF06292); // Soft Pink
      //  bgColor = const Color(0xFF33252A); // Dark Pinkish-Gray
        surfaceColor = const Color(0xFF261B20);
        break;
      case Mood.focused:
        background = const Color(0xFF64B5F6); // Calm Blue
      //  bgColor = const Color(0xFF252C33); // Dark Bluish-Gray
        surfaceColor = const Color(0xFF1A2026);
        break;
      case Mood.annoyed:
        background = const Color(0xFFE57373); // Soft Red
       // bgColor = const Color(0xFF332626); // Dark Reddish-Gray
        surfaceColor = const Color(0xFF261B1B);
        break;
      case Mood.neutral:
      default:
        background = const Color(0xFFCABBDF); // Lavender default
        //bgColor = const Color(0xFF2B4150); // Original Deep Blue-Gray
        surfaceColor = const Color(0xFF1F2F3B);
        break;
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceColor,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme.dark(
        primary: background,
        secondary: secondary,
        tertiary: tertiary,
        surface: surfaceColor,
        error: error,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: const TextStyle(color: neutral),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: background.withOpacity(0.5)),
        ),
      ),
    );
  }
}
