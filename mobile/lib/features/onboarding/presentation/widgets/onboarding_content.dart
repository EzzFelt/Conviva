import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/onboarding_page.dart';

/// Widget que exibe o conteúdo de uma página de onboarding
/// 
/// Composto por:
/// - Imagem
/// - Título
/// - Descrição
class OnboardingContent extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingContent({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Imagem ilustrativa
          Expanded(
            flex: 3,
            child: Image.asset(
              page.imagePath,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 40),

          // Título
          Text(
            page.title,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Descrição (se existir)
          if (page.description.isNotEmpty)
            Text(
              page.description,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
