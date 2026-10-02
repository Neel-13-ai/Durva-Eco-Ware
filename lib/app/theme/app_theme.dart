import 'package:flutter/material.dart';
import 'tokens.dart';

ThemeData buildAppTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.primary,
    primary: BrandColors.primary,
    onPrimary: BrandColors.onPrimary,
    secondary: BrandColors.secondary,
    brightness: Brightness.light,
  );

  // Eliminate muddy M3 tonal container tints by enforcing crisp white surfaces & neutral slate backgrounds
  final colorScheme = baseScheme.copyWith(
    surface: Colors.white,
    onSurface: SemanticColors.text,
    surfaceTint: Colors.transparent, // Disable M3 green overlay tint on surfaces
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: const Color(0xFFF1F5F9), // Slate-100 for subtle contrast
    outline: SemanticColors.border,
    outlineVariant: const Color(0xFFF1F5F9),
    secondaryContainer: const Color(0xFFE8F5E9), // Crisp light emerald instead of muddy khaki
    onSecondaryContainer: BrandColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    primaryColor: BrandColors.primary,
    scaffoldBackgroundColor: SemanticColors.background,
    cardColor: Colors.white,

    // Dialog Theme: Clean white background, no green tint, rounded corners & subtle shadow
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
    ),

    // Card Theme: Crisp white card with subtle slate border
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // Bottom Sheet Theme: Clean white surface
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Navigation Bar Theme: White background with crisp active indicators
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      indicatorColor: const Color(0xFFE8F5E9),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: BrandColors.primary);
        }
        return const IconThemeData(color: Color(0xFF64748B));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: BrandColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          );
        }
        return const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
        );
      }),
    ),

    // Segmented Button Theme: Clean modern styling
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE8F5E9);
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BrandColors.primary;
          }
          return const Color(0xFF475569);
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
    ),

    // Input Decoration Theme: Clean white text fields with subtle borders
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      focusColor: BrandColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: BrandColors.primary, fontWeight: FontWeight.w600),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: BrandColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: SemanticColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: SemanticColors.danger, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),

    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: FontSizes.headline, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
      titleLarge: TextStyle(fontSize: FontSizes.title, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
      titleMedium: TextStyle(fontSize: FontSizes.subtitle, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      bodyLarge: TextStyle(fontSize: FontSizes.body, color: Color(0xFF334155)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF475569)),
      bodySmall: TextStyle(fontSize: FontSizes.caption, color: Color(0xFF64748B)),
    ),
  );
}
