import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData dark() {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.green,
      secondary: AppColors.greenLight,
      surface: AppColors.surface,
      error: AppColors.red,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.text,
      onError: Colors.black,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
      useMaterial3: true,
      textTheme: const TextTheme().copyWith(
        titleLarge: AppTypography.serifAmount(size: 22, color: AppColors.text),
        titleMedium: AppTypography.serifAmount(size: 16, color: AppColors.text),
        bodyMedium: AppTypography.monoLabel(size: 12, color: AppColors.text, letterSpacing: 0.2),
        labelSmall: AppTypography.monoLabel(size: 10, color: AppColors.muted, weight: FontWeight.w400),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.serifAmount(size: 16, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.7),
        ),
      ),
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.green, width: 1.0),
        ),
        hintStyle: AppTypography.monoLabel(size: 12, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
        labelStyle: AppTypography.monoLabel(size: 12, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
      ),
    );
  }
}

