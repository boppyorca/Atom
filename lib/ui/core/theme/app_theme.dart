import 'package:flutter/material.dart';
import 'package:harness_app/ui/core/theme/app_colors.dart';
import 'package:harness_app/ui/core/theme/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      error: AppColors.error,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTap),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
