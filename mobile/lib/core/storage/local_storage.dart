import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper para SharedPreferences com métodos específicos do app
/// Facilita testes e centraliza acesso ao storage local
class LocalStorage {
  LocalStorage._();

  // === KEYS ===
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userTypeKey = 'user_type';

  // === ONBOARDING ===

  /// Marca o onboarding como completo
  static Future<bool> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_onboardingCompletedKey, completed);
  }

  /// Verifica se o onboarding foi completo
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // === USER TYPE ===

  /// Salva o tipo de usuário escolhido (IDOSO, CUIDADOR, FAMILIAR)
  static Future<bool> setUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userTypeKey, userType);
  }

  /// Retorna o tipo de usuário salvo
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  // === UTILITÁRIOS ===

  /// Limpa TODOS os dados (útil para logout completo ou reset)
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}
