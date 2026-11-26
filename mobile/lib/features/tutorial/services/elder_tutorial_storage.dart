import 'package:shared_preferences/shared_preferences.dart';

/// Guarda, neste aparelho, se o idoso acabou de se cadastrar e ainda precisa
/// decidir se quer fazer o tutorial.
///
/// Contas criadas antes desta funcionalidade nunca recebem a marcação, então
/// não veem o tutorial. Falhas de leitura ou escrita nunca devem bloquear o
/// acesso ao app.
class ElderTutorialStorage {
  ElderTutorialStorage._();

  static String _key(String uid) => 'elder_tutorial_pending_$uid';

  static Future<void> markPending(String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_key(uid), true);
    } catch (_) {
      // O tutorial é opcional: se não der para salvar, o app segue normal.
    }
  }

  static Future<bool> isPending(String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_key(uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearPending(String uid) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_key(uid));
    } catch (_) {
      // Ignorado pelo mesmo motivo de [markPending].
    }
  }
}
