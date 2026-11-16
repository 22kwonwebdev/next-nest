import 'package:flutter/material.dart';

/// Shared palette derived from the supplied reference design.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF185A41);
  static const Color primaryDark = Color(0xFF124432);
  static const Color secondary = Color(0xFF4F7659);
  static const Color leaf = Color(0xFF88A95E);
  static const Color info = Color(0xFF4E9E86);
  static const Color success = Color(0xFF4F8F55);
  static const Color warning = Color(0xFFD39A37);
  static const Color error = Color(0xFFC94F4F);

  static const Color lightBackground = Color(0xFFF3F7F1);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE8F0E8);
  static const Color lightBackdropEnd = Color(0xFFF9FAF4);
  static const Color lightTextPrimary = Color(0xFF203228);
  static const Color lightTextSecondary = Color(0xFF65746A);
  static const Color lightBorder = Color(0xFFDDE7DE);

  static const Color darkBackground = Color(0xFF101914);
  static const Color darkSurface = Color(0xFF1A261F);
  static const Color darkSurfaceVariant = Color(0xFF26372C);
  static const Color darkBackdropEnd = Color(0xFF142019);
  static const Color darkTextPrimary = Color(0xFFF0F5F1);
  static const Color darkTextSecondary = Color(0xFFA8B8AB);
  static const Color darkBorder = Color(0xFF34483A);

  // Existing screen widgets use these brightness-aware accessors.
  static Brightness _brightness = Brightness.light;

  static void updateBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get _isDark => _brightness == Brightness.dark;

  static Color get background => _isDark ? darkBackground : lightBackground;
  static Color get surface => _isDark ? darkSurface : lightSurface;
  static Color get surfaceVariant =>
      _isDark ? darkSurfaceVariant : lightSurfaceVariant;
  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? darkTextSecondary : lightTextSecondary;
  static Color get border => _isDark ? darkBorder : lightBorder;
}
