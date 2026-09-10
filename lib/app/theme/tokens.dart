import 'package:flutter/material.dart';

/// Enterprise brand color tokens
abstract final class BrandColors {
  static const Color primary = Color(0xFF1B5E20); // Forest Eco Green
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF2E7D32); // Leaf Green
  static const Color accent = Color(0xFF43A047); // Light Green Accent
  static const Color primaryDark = Color(0xFF003300);
}

/// Semantic UI color tokens
abstract final class SemanticColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7FA);
  static const Color text = Color(0xFF1A1F27);
  static const Color textMuted = Color(0xFF5A6472);
  static const Color border = Color(0xFFD8DEE6);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
}

/// Spacing scale (logical pixels)
abstract final class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Corner radii scale (logical pixels)
abstract final class Radii {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double pill = 999.0;
}

/// Typography scale
abstract final class FontSizes {
  static const double caption = 12.0;
  static const double body = 16.0;
  static const double subtitle = 18.0;
  static const double title = 22.0;
  static const double headline = 28.0;
}
