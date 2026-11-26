import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/onboarding_page.dart';

/// Model de OnboardingPage
/// 
/// Contém os dados das telas de onboarding.
/// No futuro, pode ser substituído por dados vindos de API.
class OnboardingPageModel extends OnboardingPage {
  const OnboardingPageModel({
    required super.title,
    required super.description,
    required super.imagePath,
  });

  /// Lista de páginas do onboarding
  static List<OnboardingPageModel> getPages() {
    return const [
      OnboardingPageModel(
        title: 'Conviva agora é usar o Conviva',
        description:
            'Um aplicativo para organizar sua rotina, conversas com a família e cuidar da sua saúde',
        imagePath: AppAssets.onboarding1,
      ),
      OnboardingPageModel(
        title: 'Você poderá denunciar maus-tratos de forma fácil, rápida e segura',
        description:
            'Assim, garantimos mais proteção e ajuda para você',
        imagePath: AppAssets.onboarding2,
      ),
      OnboardingPageModel(
        title: 'Crie uma conta e se reconecte com o mundo!',
        description: '',
        imagePath: AppAssets.onboarding3,
      ),
    ];
  }
}
