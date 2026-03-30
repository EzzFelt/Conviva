import '../../../../core/storage/local_storage.dart';

/// Data Source local para onboarding
/// 
/// Responsável por acessar o SharedPreferences através do wrapper LocalStorage.
/// Não contém lógica de negócio, apenas acessa/salva dados.
class OnboardingLocalDataSource {
  /// Marca o onboarding como completo
  Future<bool> setOnboardingCompleted() async {
    return await LocalStorage.setOnboardingCompleted(true);
  }

  /// Verifica se o onboarding foi completo
  Future<bool> getOnboardingStatus() async {
    return await LocalStorage.isOnboardingCompleted();
  }

  /// Salva o tipo de usuário escolhido
  Future<bool> saveUserType(String userType) async {
    return await LocalStorage.setUserType(userType);
  }

  /// Retorna o tipo de usuário salvo
  Future<String?> getUserType() async {
    return await LocalStorage.getUserType();
  }
}
