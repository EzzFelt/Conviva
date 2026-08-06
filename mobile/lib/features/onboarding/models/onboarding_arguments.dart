import 'package:conviva/features/auth/models/auth_mode.dart';

class OnboardingArguments {
  final int initialPage;
  final AuthMode authMode;

  const OnboardingArguments({
    this.initialPage = 0,
    this.authMode = AuthMode.register,
  });
}