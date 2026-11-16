import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/assets_paths.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/authenticated_user_navigator.dart';
import '../../auth/providers/current_user_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _isLoading = true;
  bool _startupFailed = false;

  @override
  void initState() {
    super.initState();
    _openInitialDestination();
  }

  Future<void> _openInitialDestination() async {
    // Inicia a recuperação da sessão imediatamente.
    // O resultado captura erros desde o início, evitando
    // que uma falha antecipada fique sem tratamento.
    final sessionFuture = _loadSessionSafely();

    // Preserva o tempo mínimo de apresentação do splash.
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Aguarda a sessão e as preferências já integradas
    // ao CurrentUserNotifier.
    final result = await sessionFuture;

    if (!mounted) return;

    if (result.error != null) {
      _showStartupError();
      return;
    }

    final session = result.session;

    try {
      if (session == null) {
        final authService = AuthService.instance;
        final hasPendingRegistration = await authService
            .hasPendingEmailRegistration();
        if (!mounted) return;

        if (hasPendingRegistration) {
          final isEmailVerified = await authService.isCurrentEmailVerified();
          if (!mounted) return;

          if (isEmailVerified) {
            await authService.completePendingEmailRegistration();
            final completedSession = await ref
                .read(currentUserProvider.notifier)
                .refresh();
            if (!mounted) return;

            if (completedSession == null) {
              throw StateError(
                'Não foi possível concluir o cadastro verificado.',
              );
            }
            await AuthenticatedUserNavigator.open(context, completedSession);
          } else {
            context.go(RouteNames.verifyEmail);
          }
          return;
        }

        context.go(RouteNames.onboarding);
        return;
      }

      // A navegação pode precisar consultar dados adicionais,
      // como o vínculo entre familiar e idoso.
      await AuthenticatedUserNavigator.open(context, session);
    } catch (error, stackTrace) {
      debugPrint('Erro ao abrir o destino inicial: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showStartupError();
    }
  }

  Future<_SessionLoadResult> _loadSessionSafely() async {
    try {
      final session = await ref.read(currentUserProvider.future);

      return _SessionLoadResult.success(session);
    } catch (error, stackTrace) {
      debugPrint('Erro ao recuperar a sessão inicial: $error');
      debugPrintStack(stackTrace: stackTrace);

      return _SessionLoadResult.failure(error);
    }
  }

  void _showStartupError() {
    setState(() {
      _isLoading = false;
      _startupFailed = true;
    });
  }

  void _retryStartup() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _startupFailed = false;
    });

    // Solicita uma nova tentativa de recuperação da sessão.
    ref.invalidate(currentUserProvider);

    _openInitialDestination();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sizes = context.appSizes;

    final logo = Semantics(
      image: true,
      label: 'Conviva',
      child: Image.asset(
        AssetPaths.logo,
        width: sizes.xxl * 3.75,
        excludeFromSemantics: true,
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: _startupFailed
              ? Padding(
                  padding: EdgeInsets.all(sizes.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      logo,
                      SizedBox(height: sizes.lg),
                      Text(
                        'Não foi possível concluir a inicialização.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                      SizedBox(height: sizes.sm),
                      Text(
                        'Confira sua conexão e tente novamente. '
                        'Se o problema continuar, tente mais tarde.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: sizes.lg),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _retryStartup,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : logo,
        ),
      ),
    );
  }
}

class _SessionLoadResult {
  const _SessionLoadResult.success(this.session) : error = null;

  const _SessionLoadResult.failure(this.error) : session = null;

  final UserSession? session;
  final Object? error;
}
