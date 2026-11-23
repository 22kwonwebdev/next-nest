import 'package:flutter/material.dart';

/// Central color tokens for the quotation app.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFDFDFD);
  static const Color surface = Color(0xFFFDFDFD);
  static const Color primary = Color(0xFF1978D0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF000000);
  static const Color accent = Color(0xFF1978D0);
  static const Color border = Color(0xFFE5E7EB);
  static const Color surfaceVariant = surface;
  static const Color primaryDark = primary;
  static const Color secondary = accent;
  static const Color leaf = accent;
  static const Color info = accent;
  static const Color success = Color(0xFF047857);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFDC2626);

  static const Color draftBackground = Color(0xFFF3F4F6);
  static const Color draftText = Color(0xFF4B5563);
  static const Color pendingBackground = Color(0xFFFFF8E7);
  static const Color pendingText = Color(0xFFB45309);
  static const Color pendingIndicator = Color(0xFFF5B400);
  static const Color approvedBackground = Color(0xFFECFDF5);
  static const Color approvedText = Color(0xFF047857);
  static const Color rejectedBackground = Color(0xFFFEF2F2);
  static const Color rejectedText = Color(0xFFDC2626);

  // Compatibility aliases for shared widgets that previously supported dark mode.
  static const Color lightBackground = background;
  static const Color lightSurface = surface;
  static const Color lightSurfaceVariant = surface;
  static const Color lightBackdropEnd = background;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightBorder = border;
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkSurfaceVariant = surface;
  static const Color darkBackdropEnd = background;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;
  static const Color darkBorder = border;
}
