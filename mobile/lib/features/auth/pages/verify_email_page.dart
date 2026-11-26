import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/button_widget.dart';
import '../providers/authenticated_user_navigator.dart';
import '../providers/current_user_provider.dart';

/// Tela exibida a familiares e cuidadores até confirmarem o e-mail.
/// Garante que o cadastro só seja liberado com um e-mail real.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage>
    with WidgetsBindingObserver {
  static const _resendDelay = 60;

  Timer? _timer;
  bool _isChecking = false;
  bool _isResending = false;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Quando a pessoa volta do app de e-mail, confere sozinho.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check(silent: true));
    }
  }

  Future<void> _check({bool silent = false}) async {
    if (_isChecking) return;

    setState(() => _isChecking = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final verified = await AuthService.instance.isCurrentEmailVerified();
      if (!mounted) return;

      if (!verified) {
        if (!silent) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Ainda não recebemos a confirmação do e-mail.'),
            ),
          );
        }
        return;
      }

      await AuthService.instance.completePendingEmailRegistration();
      final session = await ref.read(currentUserProvider.notifier).refresh();
      if (!mounted) return;

      if (session == null) {
        throw StateError('Não foi possível concluir o cadastro verificado.');
      }

      await AuthenticatedUserNavigator.open(context, session);
    } catch (error) {
      if (!silent) {
        final message = error is StateError || error is FormatException
            ? error.toString().replaceFirst('Bad state: ', '')
            : 'Não foi possível verificar agora. Tente de novo.';
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    if (_isResending || _secondsLeft > 0) return;

    setState(() => _isResending = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AuthService.instance.resendVerificationEmail();
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('E-mail de confirmação reenviado.')),
      );
      _startCooldown();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível reenviar agora. Tente mais tarde.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendDelay);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _signOut() async {
    try {
      await ref.read(currentUserProvider.notifier).signOut();
    } catch (_) {
      // Mesmo com falha, volta para o início.
    }

    if (mounted) context.go(RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sizes = context.appSizes;
    final email = AuthService.instance.currentUserEmail ?? 'seu e-mail';

    final resendLabel = _isResending
        ? 'Reenviando...'
        : _secondsLeft > 0
        ? 'Reenviar em ${_secondsLeft}s'
        : 'Reenviar e-mail';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(sizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_unread_rounded,
                  size: sizes.icon(sizes.xxl * 2),
                  color: colorScheme.primary,
                ),
                SizedBox(height: sizes.lg),
                Text(
                  'Confirme seu e-mail',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                SizedBox(height: sizes.md),
                Text(
                  'Enviamos um link de confirmação para\n$email.\n'
                  'Abra o e-mail e toque no link para liberar sua conta. '
                  'Confira também a caixa de spam.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: sizes.xl),
                ButtonWidget(
                  label: _isChecking ? 'Verificando...' : 'Já confirmei',
                  variant: ButtonVariant.primary,
                  onPressed: _isChecking ? null : _check,
                ),
                SizedBox(height: sizes.md),
                ButtonWidget(
                  label: resendLabel,
                  variant: ButtonVariant.outlined,
                  onPressed: (_isResending || _secondsLeft > 0)
                      ? null
                      : _resend,
                ),
                SizedBox(height: sizes.md),
                TextButton(onPressed: _signOut, child: const Text('Sair')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
