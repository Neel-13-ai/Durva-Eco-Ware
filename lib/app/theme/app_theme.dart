import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.primary,
    primary: BrandColors.primary,
    onPrimary: BrandColors.onPrimary,
    secondary: BrandColors.secondary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: BrandColors.primary,
    scaffoldBackgroundColor: SemanticColors.background,
    inputDecorationTheme: InputDecorationTheme(
      focusColor: BrandColors.primary,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrandColors.primary, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: SemanticColors.border),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: FontSizes.title, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: FontSizes.body),
    ),
  );
}
