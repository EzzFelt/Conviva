import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto otimizados para acessibilidade (idosos)
/// Fontes maiores que o padrão Material Design
class AppTextStyles {
  AppTextStyles._();

  // === HEADLINES (Títulos) ===

  /// Usado em títulos principais de telas (ex: "Bem-vindo ao Conviva")
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32, // Material padrão: 24
    fontWeight: FontWeight.bold,
    height: 1.3, // Espaçamento entre linhas
    color: AppColors.textPrimary,
    letterSpacing: 0.25,
  );

  /// Usado em subtítulos de seções
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24, // Material padrão: 20
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // === BODY (Corpo de texto) ===

  /// Texto principal de descrições e parágrafos
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18, // Material padrão: 16
    fontWeight: FontWeight.normal,
    height: 1.5, // Espaçamento generoso para leitura
    color: AppColors.textPrimary,
  );

  /// Texto secundário (labels, hints)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16, // Material padrão: 14
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // === BOTÕES ===

  /// Texto de botões principais
  static const TextStyle button = TextStyle(
    fontSize: 18, // Maior para fácil leitura
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.5,
  );

  /// Texto de botões secundários/texto
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  // === VARIAÇÕES COM COR CUSTOMIZADA ===

  /// Cria variação do bodyLarge com cor específica
  static TextStyle bodyLargeWith({required Color color}) {
    return bodyLarge.copyWith(color: color);
  }

  /// Cria variação do headlineLarge com cor específica
  static TextStyle headlineLargeWith({required Color color}) {
    return headlineLarge.copyWith(color: color);
  }
}
