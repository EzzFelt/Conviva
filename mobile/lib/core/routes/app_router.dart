import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/user_type_selection_page.dart';

/// Configuração de rotas do aplicativo usando GoRouter
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true, // Logs de navegação (remover em produção)

    routes: [
      // Splash (tela inicial)
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SplashPage(),
        ),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const OnboardingPage(),
        ),
      ),

      // Seleção de tipo de usuário
      GoRoute(
        path: '/user-type-selection',
        name: 'user-type-selection',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const UserTypeSelectionPage(),
        ),
      ),

      // TODO: Adicionar rotas de login, cadastro, home, etc
    ],

    // Tratamento de erro (rota não encontrada)
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Página não encontrada: ${state.uri}')),
    ),
  );

  /// Helper para criar transição customizada entre páginas
  static CustomTransitionPage _buildPageWithTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in transition (suave)
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
