import '../entities/user_type.dart';

/// Interface do repositório de onboarding
///
/// Define o contrato que a camada de dados deve implementar.
/// Permite trocar a implementação (SharedPreferences por Hive, etc)
/// sem afetar a camada de domínio.
abstract class OnboardingRepository {
  /// Marca o onboarding como completo
  Future<bool> completeOnboarding();

  /// Verifica se o onboarding foi completo
  Future<bool> isOnboardingCompleted();

  /// Salva o tipo de usuário escolhido
  Future<bool> saveUserType(UserType userType);

  /// Retorna o tipo de usuário salvo (se existir)
  Future<UserType?> getUserType();
}
