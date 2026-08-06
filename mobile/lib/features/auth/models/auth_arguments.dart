import 'account_type.dart';
import 'auth_mode.dart';

class AuthArguments {
  final AccountType accountType;
  final AuthMode authMode;

  const AuthArguments({
    required this.accountType,
    required this.authMode,
  });
}