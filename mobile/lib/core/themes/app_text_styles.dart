import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const pageTitle = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const sectionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.30,
  );

  static const actionCardTitle = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const bodyEmphasis = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.30,
  );

  static const button = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.20,
  );

  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      headlineLarge: pageTitle.copyWith(color: textColor),
      headlineSmall: actionCardTitle.copyWith(color: textColor),
      titleLarge: sectionTitle.copyWith(color: textColor),
      titleMedium: bodyEmphasis.copyWith(color: textColor),
      bodyLarge: body.copyWith(color: textColor),
      bodyMedium: body.copyWith(color: textColor),
      bodySmall: caption.copyWith(color: textColor),
      labelLarge: button.copyWith(color: textColor),
    );
  }
}
