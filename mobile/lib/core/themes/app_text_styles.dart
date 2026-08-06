import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // Título grande
  static const heading = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Color(0xFF3C3C3C),
  );

  // Subtítulo
  static const subtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Color(0xFF3C3C3C),
  );

  // Texto padrão
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF3C3C3C),
  );

  // Texto pequeno
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF3C3C3C),
  );

  // Botões
  static const button = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}