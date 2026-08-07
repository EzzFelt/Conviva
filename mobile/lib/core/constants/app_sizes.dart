import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const radiusSm = 8.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;
  static const radiusFull = 75.0;
}

/// Versão escalável dos tamanhos base de [AppSizes].
@immutable
class AppSizesTheme extends ThemeExtension<AppSizesTheme> {
  const AppSizesTheme({
    this.spacingScale = 1,
    this.buttonScale = 1,
  });

  static const standard = AppSizesTheme();

  final double spacingScale;
  final double buttonScale;

  double get xs => AppSizes.xs * spacingScale;
  double get sm => AppSizes.sm * spacingScale;
  double get md => AppSizes.md * spacingScale;
  double get lg => AppSizes.lg * spacingScale;
  double get xl => AppSizes.xl * spacingScale;
  double get xxl => AppSizes.xxl * spacingScale;

  double get radiusSm => AppSizes.radiusSm * spacingScale;
  double get radiusMd => AppSizes.radiusMd * spacingScale;
  double get radiusLg => AppSizes.radiusLg * spacingScale;
  double get radiusFull => AppSizes.radiusFull * spacingScale;

  double get buttonSmall => 42 * buttonScale;
  double get buttonMedium => 50 * buttonScale;
  double get buttonLarge => 56 * buttonScale;

  @override
  AppSizesTheme copyWith({
    double? spacingScale,
    double? buttonScale,
  }) {
    return AppSizesTheme(
      spacingScale: spacingScale ?? this.spacingScale,
      buttonScale: buttonScale ?? this.buttonScale,
    );
  }

  @override
  AppSizesTheme lerp(
    covariant AppSizesTheme? other,
    double t,
  ) {
    if (other == null) return this;

    return AppSizesTheme(
      spacingScale: spacingScale +
          (other.spacingScale - spacingScale) * t,
      buttonScale: buttonScale + (other.buttonScale - buttonScale) * t,
    );
  }
}

extension AppSizesThemeContext on BuildContext {
  AppSizesTheme get appSizes {
    return Theme.of(this).extension<AppSizesTheme>() ?? AppSizesTheme.standard;
  }
}
