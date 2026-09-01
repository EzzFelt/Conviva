import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

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

class LoginPage extends ConsumerStatefulWidget {
  final AuthArguments arguments;

  const LoginPage({
    super.key,
    required this.arguments,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final session = await ref
          .read(currentUserProvider.notifier)
          .loginWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            accountType: widget.arguments.accountType,
          );

      if (!mounted) return;
      await AuthenticatedUserNavigator.open(context, session);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = switch (error.code) {
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'E-mail ou senha incorretos.',
        'invalid-email' => 'Informe um e-mail válido.',
        'user-disabled' => 'Esta conta foi desativada.',
        'too-many-requests' =>
          'Muitas tentativas. Aguarde um pouco e tente novamente.',
        _ => 'Não foi possível entrar. Tente novamente.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe a senha';
    }

    return null;
  }

  String _errorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final accountType = widget.arguments.accountType;
    final colorScheme = Theme.of(context).colorScheme;
    final sizes = context.appSizes;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
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

                  const AuthHeaderWidget(
                    title: 'Entre na\nsua conta!',
                  ),

                  SizedBox(height: sizes.xl),

                  TextFieldWidget(
                    controller: _emailController,
                    hintText: 'E-mail',
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    autofillHints: const [AutofillHints.email],
                  ),

                  SizedBox(height: sizes.md),

                  PasswordTextFieldWidget(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _login(),
                  ),

                  SizedBox(height: sizes.xl),

                  ButtonWidget(
                    label: _isLoading ? 'Entrando...' : 'Entrar',
                    variant: ButtonVariant.primary,
                    onPressed: _isLoading ? null : _login,
                  ),

                  SizedBox(height: sizes.lg),

                  AuthFooterWidget(
                    text: 'Ainda não possui conta?',
                    actionText: 'Cadastre-se',
                    onTap: () {
                      context.go(
                        RouteNames.register,
                        extra: AuthArguments(
                          accountType: accountType,
                          authMode: AuthMode.register,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
