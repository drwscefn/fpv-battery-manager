// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const border = Color(0xFF333333);
  static const accent = Color(0xFFFFE500);
  static const warning = Color(0xFFFF4500);
  static const healthy = Color(0xFF4ADE80);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF666666);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    final mono = GoogleFonts.shareTechMonoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accent,
        error: AppColors.warning,
      ),
      textTheme: mono,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.accent,
        elevation: 0,
        titleTextStyle: GoogleFonts.shareTechMono(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(),
          textStyle: GoogleFonts.shareTechMono(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.accent),
        ),
        labelStyle: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.shareTechMono(color: AppColors.textSecondary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(),
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.border,
    );
  }
}
