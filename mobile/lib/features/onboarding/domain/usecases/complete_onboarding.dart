import '../repositories/onboarding_repository.dart';

/// Use Case: Marcar onboarding como completo
///
/// Responsabilidade única: executar a lógica de marcar o onboarding
/// como visualizado pelo usuário.
class CompleteOnboarding {
  final OnboardingRepository repository;

  CompleteOnboarding(this.repository);

  /// Executa o caso de uso
  Future<bool> call() async {
    return await repository.completeOnboarding();
  }
}
