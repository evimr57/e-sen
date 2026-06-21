import 'package:flutter/material.dart';

/// e-Sen App Theme
/// Light mode with soft blue-white gradient palette, sky blue accent.
class AppTheme {
  // ===== Core Brand Colors (Sky Blue & White) =====
  static const Color primary = Color(0xFF2E9CFF); // Sky Blue - signature color
  static const Color primaryLight = Color(0xFF6CC2FF); // Lighter sky blue
  static const Color secondary = Color(0xFF0B5FB8); // Deeper blue for contrast/headers
  static const Color accent = Color(0xFF2E9CFF); // Accent same as primary

  // ===== Status Colors =====
  static const Color success = Color(0xFF10B981); // Emerald Green (Present / In-Radius)
  static const Color warning = Color(0xFFF59E0B); // Amber (Late / Warning)
  static const Color danger = Color(0xFFEF4444); // Coral Red (Absent / Out-of-Radius)

  // ===== Background & Surface (Light mode, soft blue-white) =====
  static const Color background = Color(0xFFF4F9FF); // Very light blue-tinted white
  static const Color surface = Color(0xFFFFFFFF); // Pure white for cards
  static const Color surfaceTint = Color(0xFFEAF4FF); // Slightly blue surface for variety

  // ===== Text Colors =====
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate (near black)
  static const Color textSecondary = Color(0xFF64748B); // Muted slate gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on blue backgrounds

  // ===== Border =====
  static const Color border = Color(0xFFD7E8FB); // Soft blue-gray border

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: danger,
        surface: surface,
        onPrimary: textOnPrimary,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceTint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.1),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
      ),
    );
  }

  // ===== Gradients =====

  /// Main brand gradient: soft sky blue to white, used for backgrounds/headers.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  /// Soft background gradient: subtle blue fading into white.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDCEEFF), Color(0xFFFFFFFF)],
  );

  /// Accent gradient for highlight elements.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), success],
  );

  // ===== Shadows =====

  /// Soft card shadow for light mode (subtle, blue-tinted).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}