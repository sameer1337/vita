import 'package:flutter/material.dart';

/// Calm, minimal Vita theme — a sage / blue-green palette with generous
/// spacing and soft, rounded surfaces. No bright neon (per design rules).
class AppTheme {
  AppTheme._();

  static const Color sage = Color(0xFF6B9080);
  static const Color deepSage = Color(0xFF2E3D38);
  static const Color softBackground = Color(0xFFF6F8F7);

  // Dark + sage surfaces used by the home experience (dashboard / coach / plan).
  static const Color darkBg = Color(0xFF14201B);
  static const Color darkSurface = Color(0xFF1E2C26);
  static const Color darkSurfaceAlt = Color(0xFF263A32);
  static const Color sageLight = Color(0xFF9CC3B2);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: softBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: deepSage,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: sage,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
