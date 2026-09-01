import 'user_session.dart';

class AuthRegistrationResult {
  const AuthRegistrationResult({
    required this.session,
    this.elderAccessCode,
  });

  final UserSession session;
  final String? elderAccessCode;
}
