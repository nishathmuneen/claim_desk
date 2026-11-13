import 'package:flutter/material.dart';

class AppTheme {
  // Brand Canvas: Clean light modern background (Image 1 reference)
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF); // Crisp Pure White Card
  static const Color surfaceElevated = Color(0xFFF8FAFC); // Subtle Off-White
  static const Color border = Color(0xFFE2E8F0); // Crisp light border
  static const Color borderFocused = Color(0xFFCBD5E1);

  // Corporate Deep Navy (Image 2 reference) for headers, app bars, and high contrast
  static const Color navyDark = Color(0xFF0D1322); // Header & Splash Navy
  static const Color navySurface = Color(0xFF161F33); // Metallic Card Surface
  static const Color navyElevated = Color(0xFF1E2B45);

  // Signature Expertise Orange (matching the 'X' in "expertise")
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFB923C);
  static const Color orangeDark = Color(0xFFEA580C);
  static const Color orangeMuted = Color(0xFFFFF7ED); // Soft warm tinted background

  // Functional & Status Colors
  static const Color successGreen = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color closedPurple = Color(0xFF7C3AED);
  static const Color closedLight = Color(0xFFF5F3FF);

  // Text Colors (High readability on light surface)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightNavyTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        onPrimary: Colors.white,
        secondary: navyDark,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: dangerRed,
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDark, // Deep Navy AppBar from Image 2
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 13.5),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryOrange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dangerRed),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 1.5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navyDark,
          side: const BorderSide(color: border, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 24,
      ),
    );
  }

  static ThemeData get darkTheme => lightNavyTheme;
}
