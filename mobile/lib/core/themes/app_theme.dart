import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../settings/app_settings.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(AppSettings settings) {
    final primaryColor = settings.applyIntensity(settings.primaryColor);
    final gradientTop = settings.applyIntensity(settings.gradientTop);
    final gradientBottom = settings.applyIntensity(settings.gradientBottom);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      onPrimary: AppColors.white,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: AppColors.background,
      iconTheme: IconThemeData(
        size: 24 * settings.iconScale,
        color: AppColors.textPrimary,
      ),
      textTheme: AppTextStyles.textTheme(
        AppColors.textPrimary,
        titleWeight: settings.titleFontWeight,
        bodyWeight: settings.bodyFontWeight,
      ),
      extensions: [
        AppGradientColors(
          top: gradientTop,
          bottom: gradientBottom,
        ),
        AppSizesTheme(
          spacingScale: settings.spacingScale,
          buttonScale: settings.buttonScale,
          iconScale: settings.iconScale,
        ),
      ],
    );
  }
}
