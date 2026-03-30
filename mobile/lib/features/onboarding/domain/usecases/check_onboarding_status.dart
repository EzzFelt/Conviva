import '../repositories/onboarding_repository.dart';

/// Use Case: Verificar se o onboarding foi completo
///
/// Usado para decidir se o usuário deve ver o onboarding ou
/// ir direto para a tela de login/home.
class CheckOnboardingStatus {
  final OnboardingRepository repository;

  CheckOnboardingStatus(this.repository);

  /// Executa o caso de uso
  Future<bool> call() async {
    return await repository.isOnboardingCompleted();
  }
}
