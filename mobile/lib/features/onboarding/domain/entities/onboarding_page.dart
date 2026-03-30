/// Representa uma página do fluxo de onboarding
///
/// Essa entidade é pura (sem dependências do Flutter) e contém apenas
/// os dados necessários para exibir cada tela do onboarding.
class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
