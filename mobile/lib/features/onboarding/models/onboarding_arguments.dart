import '../../auth/models/auth_mode.dart';

class OnboardingPages {
  OnboardingPages._();

  static const intro = 0;
  static const protection = 1;
  static const welcome = 2;
  static const accountType = 3;
}

class OnboardingArguments {
  final int initialPage;
  final AuthMode authMode;

  const OnboardingArguments({
    this.initialPage = 0,
    this.authMode = AuthMode.register,
  });
}
