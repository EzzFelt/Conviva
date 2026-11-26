
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

@immutable
class AppSettings {
  /// Intensidade padrão (70%): nela as cores aparecem exatamente como no
  /// Figma. Acima disso ficam mais vivas; abaixo, mais suaves.
  static const defaultColorIntensity = .7;

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
    this.colorIntensity = defaultColorIntensity,
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

  /// Converte as preferências da conta para um mapa
  /// que poderá ser salvo no Firestore e no cache local.
  ///
  /// O volume fica de fora porque pertence ao dispositivo.
  Map<String, dynamic> toCloudMap() {
    return {
      'primaryColor': primaryColor.toARGB32(),
      'gradientTop': gradientTop.toARGB32(),
      'gradientBottom': gradientBottom.toARGB32(),
      'fontScale': fontScale,
      'titleFontWeight': titleFontWeight.value,
      'bodyFontWeight': bodyFontWeight.value,
      'iconScale': iconScale,
      'buttonScale': buttonScale,
      'spacingScale': spacingScale,
      'messageNotifications': messageNotifications,
      'reminderNotifications': reminderNotifications,
      'colorIntensity': colorIntensity,
    };
  }

  /// Reconstrói as configurações a partir dos dados salvos.
  /// Se algum campo estiver ausente ou inválido, usa o padrão.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    const defaults = AppSettings();

    return AppSettings(
      primaryColor: _migratePrimary(
        _readColor(map['primaryColor'], defaults.primaryColor),
      ),
      gradientTop: _readColor(
        map['gradientTop'],
        defaults.gradientTop,
      ),
      gradientBottom: _readColor(
        map['gradientBottom'],
        defaults.gradientBottom,
      ),
      fontScale: _readDouble(
        map['fontScale'],
        defaults.fontScale,
        min: 0.85,
        max: 1.40,
      ),
      titleFontWeight: _readFontWeight(
        map['titleFontWeight'],
        defaults.titleFontWeight,
      ),
      bodyFontWeight: _readFontWeight(
        map['bodyFontWeight'],
        defaults.bodyFontWeight,
      ),
      iconScale: _readDouble(
        map['iconScale'],
        defaults.iconScale,
        min: 0.85,
        max: 1.40,
      ),
      buttonScale: _readDouble(
        map['buttonScale'],
        defaults.buttonScale,
        min: 0.90,
        max: 1.30,
      ),
      spacingScale: _readDouble(
        map['spacingScale'],
        defaults.spacingScale,
        min: 0.90,
        max: 1.20,
      ),
      volume: _readDouble(
        map['volume'],
        defaults.volume,
        min: 0,
        max: 1,
      ),
      messageNotifications:
          map['messageNotifications'] is bool
              ? map['messageNotifications'] as bool
              : defaults.messageNotifications,
      reminderNotifications:
          map['reminderNotifications'] is bool
              ? map['reminderNotifications'] as bool
              : defaults.reminderNotifications,
      colorIntensity: _readDouble(
        map['colorIntensity'],
        defaults.colorIntensity,
        min: 0.5,
        max: 1,
      ),
    );
  }

  /// Quem salvou as configurações com o laranja antigo passa a usar o novo.
  static Color _migratePrimary(Color color) {
    return color.toARGB32() == AppColors.legacyPrimary.toARGB32()
        ? AppColors.primary
        : color;
  }

  static Color _readColor(Object? value, Color fallback) {
    if (value is! num) return fallback;

    return Color(value.toInt());
  }

  static double _readDouble(
    Object? value,
    double fallback, {
    required double min,
    required double max,
  }) {
    if (value is! num) return fallback;

    return value.toDouble().clamp(min, max).toDouble();
  }

  static FontWeight _readFontWeight(
    Object? value,
    FontWeight fallback,
  ) {
    if (value is! num) return fallback;

    for (final weight in FontWeight.values) {
      if (weight.value == value.toInt()) {
        return weight;
      }
    }

    return fallback;
  }

  Color applyIntensity(Color color) {
    final hsl = HSLColor.fromColor(color);

    final factor = colorIntensity / defaultColorIntensity;

    return hsl
        .withSaturation((hsl.saturation * factor).clamp(0, 1).toDouble())
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
