import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFFF8FAF9);
  static const ink = Color(0xFF182522);
  static const accent = Color(0xFF167D63);
  static const muted = Color(0xFF66756F);
  static const line = Color(0xFFE1E9E5);
  static const softGreen = Color(0xFFEAF4EF);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
      surface: background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: ink,
          fontSize: 30,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: ink,
          fontSize: 23,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: ink, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: muted, fontSize: 14, height: 1.45),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
