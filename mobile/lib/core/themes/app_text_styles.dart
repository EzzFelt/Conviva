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

  static TextTheme textTheme(
    Color textColor, {
    FontWeight titleWeight = FontWeight.w600,
    FontWeight bodyWeight = FontWeight.w400,
  }) {
    return TextTheme(
      headlineLarge: pageTitle.copyWith(
        color: textColor,
        fontWeight: titleWeight,
      ),
      headlineSmall: actionCardTitle.copyWith(
        color: textColor,
        fontWeight: titleWeight,
      ),
      titleLarge: sectionTitle.copyWith(
        color: textColor,
        fontWeight: titleWeight,
      ),
      titleMedium: bodyEmphasis.copyWith(
        color: textColor,
        fontWeight: titleWeight,
      ),
      bodyLarge: body.copyWith(
        color: textColor,
        fontWeight: bodyWeight,
      ),
      bodyMedium: body.copyWith(
        color: textColor,
        fontWeight: bodyWeight,
      ),
      bodySmall: caption.copyWith(
        color: textColor,
        fontWeight: bodyWeight,
      ),
      labelLarge: button.copyWith(color: textColor),
    );
  }
}
