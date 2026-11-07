
import 'package:conviva/features/auth/models/user_session.dart';
import 'package:conviva/features/auth/providers/current_user_provider.dart';
import 'package:conviva/features/onboarding/pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'exibe opção de tentar novamente quando a sessão falha',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const Scaffold(
              body: Text('Onboarding'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(
              _FailingCurrentUserNotifier.new,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Simula o tempo mínimo de exibição do splash.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(
        find.text('Não foi possível concluir a inicialização.'),
        findsOneWidget,
      );

      expect(
        find.text('Tentar novamente'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    },
  );
}

class _FailingCurrentUserNotifier extends CurrentUserNotifier {
  @override
  Future<UserSession?> build() async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
  }
}
