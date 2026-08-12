import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTextStyles.textTheme(AppColors.textPrimary),
    );
  }
}
