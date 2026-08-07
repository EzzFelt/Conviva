import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.primaryColor = AppColors.primary,
    this.gradientTop = AppColors.gradientTop,
    this.gradientBottom = AppColors.gradientBottom,
    this.fontScale = 1,
    this.buttonScale = 1,
    this.spacingScale = 1,
  });

  final Color primaryColor;
  final Color gradientTop;
  final Color gradientBottom;
  final double fontScale;
  final double buttonScale;
  final double spacingScale;

  AppSettings copyWith({
    Color? primaryColor,
    Color? gradientTop,
    Color? gradientBottom,
    double? fontScale,
    double? buttonScale,
    double? spacingScale,
  }) {
    return AppSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      fontScale: fontScale ?? this.fontScale,
      buttonScale: buttonScale ?? this.buttonScale,
      spacingScale: spacingScale ?? this.spacingScale,
    );
  }
}
