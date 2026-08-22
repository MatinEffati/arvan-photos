import 'package:arvan_photos/core/theme/app_colors.dart';
import 'package:arvan_photos/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: IconThemeData(color: AppColors.onSurface),
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.darkColorScheme,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: 0,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: IconThemeData(color: AppColors.onSurfaceDark),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.onSurfaceDark),
        headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.onSurfaceDark),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurfaceDark),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceDark),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceDark),
      ),
    );
  }
}
