/// Configuração da recuperação de senha do idoso no plano gratuito.
///
/// A conta do idoso precisa de um e-mail interno (o idoso entra com o código
/// ELD). Para que o link de redefinição chegue a alguém, esse e-mail é um
/// "endereço com +" da caixa abaixo, por exemplo:
///
///   suporte.convia@gmail.com  ->  suporte.convia+eld12345678@gmail.com
///
/// O Gmail entrega todos esses endereços na MESMA caixa. A pessoa
/// responsável (instituição, cuidador ou familiar) abre o link e define a
/// nova senha junto com o idoso.
///
/// A recuperação por e-mail vale para novos cadastros. Contas já criadas
/// continuam usando o endereço legado e precisam de suporte administrativo.
class RecoveryConfig {
  RecoveryConfig._();

  static const String elderSupportMailbox = 'suporte.convia@gmail.com';

  static bool get isElderRecoveryConfigured {
    return RegExp(r'^[^@\s+]+@[^@\s]+\.[^@\s]+$').hasMatch(elderSupportMailbox);
  }

  /// `suporte@gmail.com` + `eld123` -> `suporte+eld123@gmail.com`
  static String elderAuthEmail(String lowerCaseElderCode) {
    final separator = elderSupportMailbox.indexOf('@');
    final local = elderSupportMailbox.substring(0, separator);
    final domain = elderSupportMailbox.substring(separator + 1);

    return '$local+$lowerCaseElderCode@$domain';
  }
}
