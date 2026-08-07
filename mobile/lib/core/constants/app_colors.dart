import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFFF54C04);

  // Gradient
  static const gradientTop = Color(0xFFF54C04);
  static const gradientBottom = Color(0xFFF1B041);

  // Neutral
  static const white = Colors.white;
  static const black = Color(0xFF212121);

  static const background = Color(0xFFF5F5F5);

  static const textPrimary = Color(0xFF212121);
  static const textHint = Color(0xFF9E9E9E);

  static const border = Color(0xFFE0E0E0);

  static const card = Colors.white;

  static const shadow = Color(0x14000000);

  static const disabled = Color(0xFFBDBDBD);
}

/// Cores que podem variar de acordo com a preferência do usuário.
@immutable
class AppGradientColors extends ThemeExtension<AppGradientColors> {
  const AppGradientColors({
    required this.top,
    required this.bottom,
  });

  static const standard = AppGradientColors(
    top: AppColors.gradientTop,
    bottom: AppColors.gradientBottom,
  );

  final Color top;
  final Color bottom;

  @override
  AppGradientColors copyWith({
    Color? top,
    Color? bottom,
  }) {
    return AppGradientColors(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
    );
  }

  @override
  AppGradientColors lerp(
    covariant AppGradientColors? other,
    double t,
  ) {
    if (other == null) return this;

    return AppGradientColors(
      top: Color.lerp(top, other.top, t)!,
      bottom: Color.lerp(bottom, other.bottom, t)!,
    );
  }
}

extension AppGradientColorsContext on BuildContext {
  AppGradientColors get appGradientColors {
    return Theme.of(this).extension<AppGradientColors>() ??
        AppGradientColors.standard;
  }
}
