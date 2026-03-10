import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build() {
    const parchment = Color(0xFFF6EAD7);
    const ink = Color(0xFF1B1A18);
    const ember = Color(0xFFBF5A2A);
    const storm = Color(0xFF274B63);
    const blush = Color(0xFFE0B49E);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: ember,
      brightness: Brightness.light,
      primary: ink,
      secondary: storm,
      surface: parchment,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: parchment,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.4,
          height: 0.98,
          color: ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.45,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.78),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: parchment,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: BorderSide(color: ink.withValues(alpha: 0.14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: blush.withValues(alpha: 0.36),
        selectedColor: ember,
        secondarySelectedColor: ember,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
          color: parchment,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ember,
        linearTrackColor: Color(0xFFD5C6B7),
      ),
    );
  }
}
