import 'package:flutter/material.dart';

/// Paleta de cores do aplicativo Conviva
class AppColors {
  AppColors._();

  // === CORES PRINCIPAIS ===
  static const Color primary = Color(0xFFFF6B35); // Laranja vibrante
  static const Color secondary = Color(
    0xFF2E7D32,
  ); // Verde (futura implementação)

  // === CORES DE FUNDO ===
  static const Color background = Color(0xFFFFFFFF); // Branco
  static const Color backgroundGrey = Color(0xFFF5F5F5); // Cinza claro

  // === CORES DE TEXTO ===
  static const Color textPrimary = Color(0xFF212121); // Preto (alto contraste)
  static const Color textSecondary = Color(0xFF757575); // Cinza
  static const Color textOnPrimary = Color(
    0xFFFFFFFF,
  ); // Branco em fundo laranja

  // === CORES DE ESTADO ===
  static const Color error = Color(0xFFD32F2F); // Vermelho
  static const Color success = Color(0xFF388E3C); // Verde
  static const Color warning = Color(0xFFF57C00); // Laranja escuro

  // === ACESSIBILIDADE ===
  // Indicador de página ativo/inativo
  static const Color indicatorActive = primary;
  static const Color indicatorInactive = Color(0xFFBDBDBD);
}
