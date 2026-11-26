import 'package:firebase_auth/firebase_auth.dart';

enum AuthErrorContext {
  login,
  elderLogin,
  register,
}

class AuthErrorMessage {
  AuthErrorMessage._();

  static String from(
    Object error, {
    required AuthErrorContext context,
  }) {
    if (error is FirebaseAuthException) {
      return _fromAuthException(error, context);
    }

    if (error is FirebaseException) {
      return _fromFirebaseException(error, context);
    }

    final knownMessage = _fromApplicationException(error);
    if (knownMessage != null) {
      return knownMessage;
    }

    return _fallback(context);
  }

  static String _fromAuthException(
    FirebaseAuthException error,
    AuthErrorContext context,
  ) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        if (context == AuthErrorContext.login) {
          return 'E-mail ou senha incorretos.';
        }

        if (context == AuthErrorContext.elderLogin) {
          return 'Código de acesso ou senha incorretos.';
        }

        return _fallback(context);

      case 'email-already-in-use':
        return context == AuthErrorContext.register
            ? 'Este e-mail já está cadastrado.'
            : _fallback(context);

      case 'invalid-email':
        return 'Informe um e-mail válido.';

      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';

      case 'user-disabled':
        return 'Esta conta foi desativada.';

      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente novamente.';

      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';

      case 'operation-not-allowed':
        return 'Este método de autenticação não está disponível no momento.';

      default:
        return _fallback(context);
    }
  }

  static String _fromFirebaseException(
    FirebaseException error,
    AuthErrorContext context,
  ) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return 'Não foi possível conectar ao serviço. Verifique sua conexão e tente novamente.';

      case 'permission-denied':
        return 'Não foi possível concluir a operação. Tente novamente mais tarde.';

      case 'resource-exhausted':
        return 'O serviço está temporariamente indisponível. Tente novamente mais tarde.';

      default:
        return _fallback(context);
    }
  }

  /// Preserva mensagens conhecidas da aplicação, sem exibir
  /// indiscriminadamente o conteúdo de qualquer exceção.
  static String? _fromApplicationException(Object error) {
    final rawMessage = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '')
        .trim();

    const messages = <String, String>{
      'Perfil do usuário não encontrado.':
          'Não foi possível encontrar o perfil desta conta.',
      'Tipo de conta inválido para este login.':
          'Esta conta não corresponde ao tipo de acesso selecionado.',
      'Esta conta não está ativa.':
          'Esta conta não está ativa. Entre em contato com a instituição.',
      'Código da instituição inválido.':
          'Código da instituição inválido. Confira o código informado.',
      'Informe um código de acesso válido.':
          'Informe um código de acesso válido.',
      'Informe o código da instituição.':
          'Informe o código da instituição.',
      'Não foi possível gerar o código do idoso.':
          'Não foi possível gerar o código de acesso. Tente novamente.',
      'Falha ao criar o acesso do idoso.':
          'Não foi possível criar a conta do idoso. Tente novamente.',
    };

    return messages[rawMessage];
  }

  static String _fallback(AuthErrorContext context) {
    return switch (context) {
      AuthErrorContext.login =>
        'Não foi possível entrar. Tente novamente.',
      AuthErrorContext.elderLogin =>
        'Não foi possível entrar. Confira seus dados e tente novamente.',
      AuthErrorContext.register =>
        'Não foi possível concluir o cadastro. Tente novamente.',
    };
  }
}
