import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../models/auth_error_message.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/elder_recovery_request_service.dart';
import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/password_text_field_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';
import '../../onboarding/models/onboarding_arguments.dart';
import '../models/auth_arguments.dart';
import '../models/auth_mode.dart';
import '../providers/authenticated_user_navigator.dart';
import '../providers/current_user_provider.dart';
import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_header_widget.dart';

class ElderLoginPage extends ConsumerStatefulWidget {
  final AuthArguments arguments;

  const ElderLoginPage({super.key, required this.arguments});

  @override
  ConsumerState<ElderLoginPage> createState() => _ElderLoginPageState();
}

class _ElderLoginPageState extends ConsumerState<ElderLoginPage> {
  final _elderCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _elderCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final elderCode = _elderCodeController.text.trim().toUpperCase();
    final password = _passwordController.text.trim();

    if (elderCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o código de acesso do idoso.')),
      );
      return;
    }

    if (password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe a senha.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final session = await ref.read(currentUserProvider.notifier).loginElder(
            elderCode: elderCode,
            password: password,
          );

      if (!mounted) return;
      var recoveryCleanupFailed = false;
      try {
        await ElderRecoveryRequestService.instance
            .completeForwardedRequestsAfterElderLogin();
      } catch (error, stackTrace) {
        debugPrint('Falha ao concluir os pedidos de recuperação: $error');
        debugPrintStack(stackTrace: stackTrace);
        recoveryCleanupFailed = true;
      }

      if (!mounted) return;
      if (recoveryCleanupFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A senha foi aceita, mas não foi possível limpar os dados '
              'temporários. Tente novamente ou contate o suporte.',
            ),
          ),
        );
      }
      await AuthenticatedUserNavigator.open(context, session);
    }  catch (error) {
      if (!mounted) return;

      final message = AuthErrorMessage.from(
        error,
        context: AuthErrorContext.elderLogin,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: sizes.lg,
            vertical: sizes.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackButtonWidget(
                onPressed: () {
                  context.go(
                    RouteNames.onboarding,
                    extra: const OnboardingArguments(
                      initialPage: OnboardingPages.accountType,
                      authMode: AuthMode.login,
                    ),
                  );
                },
              ),

              SizedBox(height: sizes.xl),

              const AuthHeaderWidget(title: 'Entre na\nsua conta!',),

              SizedBox(height: sizes.xl),

              TextFieldWidget(
                controller: _elderCodeController,
                hintText: 'Código de acesso (ELD...)',
                enabled: !_isLoading,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  TextInputFormatter.withFunction(
                    (_, newValue) => newValue.copyWith(
                      text: newValue.text.toUpperCase(),
                    ),
                  ),
                ],
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
              ),

              SizedBox(height: sizes.md),

              PasswordTextFieldWidget(
                controller: _passwordController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(
                          RouteNames.forgotPassword,
                          extra: widget.arguments,
                        ),
                  child: const Text('Esqueci minha senha'),
                ),
              ),

              SizedBox(height: sizes.lg),

              ButtonWidget(
                label: _isLoading ? 'Entrando...' : 'Entrar',
                variant: ButtonVariant.primary,
                onPressed: _isLoading ? null : _login,
              ),

              SizedBox(height: sizes.lg),

              AuthFooterWidget(
                text: 'Ainda não possui conta?',
                actionText: 'Cadastre-se',
                onTap: _isLoading
                    ? () {}
                    : () {
                        context.go(
                          RouteNames.register,
                          extra: AuthArguments(
                            accountType: widget.arguments.accountType,
                            authMode: AuthMode.register,
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
