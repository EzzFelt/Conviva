import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Configuração do e-mail interno usado na autenticação do idoso.
///
/// O idoso entra com o código ELD; o Firebase Auth exige um e-mail associado à
/// conta. Este endereço com "+" mantém essas contas na mesma caixa, por
/// exemplo:
///
///   suporte.convia@gmail.com  ->  suporte.convia+eld12345678@gmail.com
///
/// A redefinição de senha do idoso é feita no app depois da aprovação de um
/// familiar vinculado ou cuidador da instituição.
class RecoveryConfig {
  RecoveryConfig._();

  static const String elderSupportMailbox = 'suporte.convia@gmail.com';

  static bool get isElderRecoveryConfigured {
    return RegExp(r'^[^@\s+]+@[^@\s]+\.[^@\s]+$').hasMatch(elderSupportMailbox);
  }

  static String elderRecoveryLookupId(String normalizedElderCode) {
    if (!RegExp(r'^ELD[A-Z0-9]{4,}$').hasMatch(normalizedElderCode)) {
      throw ArgumentError('Informe um código de acesso válido.');
    }

    return sha256.convert(utf8.encode(normalizedElderCode)).toString();
  }

  /// `suporte@gmail.com` + `eld123` -> `suporte+eld123@gmail.com`
  static String elderAuthEmail(String lowerCaseElderCode) {
    final separator = elderSupportMailbox.indexOf('@');
    final local = elderSupportMailbox.substring(0, separator);
    final domain = elderSupportMailbox.substring(separator + 1);

    return '$local+$lowerCaseElderCode@$domain';
  }
}
