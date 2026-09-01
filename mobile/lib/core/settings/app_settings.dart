import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.primaryColor = AppColors.primary,
    this.gradientTop = AppColors.gradientTop,
    this.gradientBottom = AppColors.gradientBottom,
    this.fontScale = 1,
    this.titleFontWeight = FontWeight.w800,
    this.bodyFontWeight = FontWeight.w400,
    this.iconScale = 1,
    this.buttonScale = 1,
    this.spacingScale = 1,
    this.volume = .7,
    this.messageNotifications = true,
    this.reminderNotifications = true,
    this.colorIntensity = .7,
  });

  final Color primaryColor;
  final Color gradientTop;
  final Color gradientBottom;
  final double fontScale;
  final FontWeight titleFontWeight;
  final FontWeight bodyFontWeight;
  final double iconScale;
  final double buttonScale;
  final double spacingScale;
  final double volume;
  final bool messageNotifications;
  final bool reminderNotifications;
  final double colorIntensity;

  Color applyIntensity(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(
          (hsl.saturation * colorIntensity).clamp(0, 1).toDouble(),
        )
        .toColor();
  }

  AppSettings copyWith({
    Color? primaryColor,
    Color? gradientTop,
    Color? gradientBottom,
    double? fontScale,
    FontWeight? titleFontWeight,
    FontWeight? bodyFontWeight,
    double? iconScale,
    double? buttonScale,
    double? spacingScale,
    double? volume,
    bool? messageNotifications,
    bool? reminderNotifications,
    double? colorIntensity,
  }) {
    return AppSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      fontScale: fontScale ?? this.fontScale,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      bodyFontWeight: bodyFontWeight ?? this.bodyFontWeight,
      iconScale: iconScale ?? this.iconScale,
      buttonScale: buttonScale ?? this.buttonScale,
      spacingScale: spacingScale ?? this.spacingScale,
      volume: volume ?? this.volume,
      messageNotifications:
          messageNotifications ?? this.messageNotifications,
      reminderNotifications:
          reminderNotifications ?? this.reminderNotifications,
      colorIntensity: colorIntensity ?? this.colorIntensity,
    );
  }
}
