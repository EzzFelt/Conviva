import 'package:conviva/core/settings/app_settings.dart';
import 'package:conviva/core/themes/app_theme.dart';
import 'package:conviva/features/auth/models/account_type.dart';
import 'package:conviva/features/auth/models/auth_arguments.dart';
import 'package:conviva/features/auth/models/auth_mode.dart';
import 'package:conviva/features/onboarding/widgets/account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('login mode shows the support account option', (tester) async {
    AuthArguments? loginArguments;
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, state) =>
              AccountTypePage(authMode: AuthMode.login, onBack: () {}),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            loginArguments = state.extra as AuthArguments?;
            return const Scaffold(body: Text('Login'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(const AppSettings()),
        routerConfig: router,
      ),
    );

    expect(find.text('Equipe de suporte'), findsOneWidget);

    await tester.ensureVisible(find.text('Equipe de suporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipe de suporte'));
    await tester.pumpAndSettle();

    expect(loginArguments?.accountType, AccountType.support);
    expect(loginArguments?.authMode, AuthMode.login);

    router.dispose();
  });

  testWidgets('registration mode hides the support account option', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const AppSettings()),
        home: AccountTypePage(authMode: AuthMode.register, onBack: () {}),
      ),
    );

    expect(find.text('Equipe de suporte'), findsNothing);
  });
}
