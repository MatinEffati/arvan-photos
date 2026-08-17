import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        titleTextStyle: AppTextStyles.h2,
        iconTheme: IconThemeData(color: AppColors.onBackground),
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }
}
