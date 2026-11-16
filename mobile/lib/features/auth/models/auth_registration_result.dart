import 'user_session.dart';

class AuthRegistrationResult {
  const AuthRegistrationResult({
    required this.session,
    this.elderAccessCode,
    this.requiresEmailVerification = false,
  });

  final UserSession? session;
  final String? elderAccessCode;
  final bool requiresEmailVerification;
}
