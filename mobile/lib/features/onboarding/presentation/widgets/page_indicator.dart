import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Indicador de páginas (bolinhas)
/// 
/// Mostra visualmente em qual página do onboarding o usuário está.
/// Bolinhas grandes (12px) para melhor visualização.
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => _buildDot(index),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 12,
      width: isActive ? 24 : 12, // Bolinha ativa é oval
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.indicatorActive
            : AppColors.indicatorInactive,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
