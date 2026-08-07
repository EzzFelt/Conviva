import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';

import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/password_text_field_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';

import '../../onboarding/models/onboarding_arguments.dart';
import '../../onboarding/pages/onboarding_page.dart';

import '../models/account_type_extensions.dart';
import '../models/auth_arguments.dart';
import '../models/auth_mode.dart';

import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_header_widget.dart';

class LoginPage extends StatefulWidget {
  final AuthArguments arguments;

  const LoginPage({
    super.key,
    required this.arguments,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // TODO: Firebase + Provider
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (phone.isEmpty) {
      return 'Informe o número de telefone';
    }

    if (phone.length < 10) {
      return 'Informe um número de telefone válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe a senha';
    }

    return null;
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
                    controller: _phoneController,
                    hintText: 'Número de telefone',
                    keyboardType: TextInputType.phone,
                    textInputAction: accountType.hasPassword
                        ? TextInputAction.next
                        : TextInputAction.done,
                    validator: _validatePhone,
                    onFieldSubmitted:
                        accountType.hasPassword ? null : (_) => _login(),
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),

                  if (accountType.hasPassword) ...[
                    SizedBox(height: sizes.md),

                    PasswordTextFieldWidget(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _login(),
                    ),
                  ],

                  SizedBox(height: sizes.xl),

                  ButtonWidget(
                    label: accountType.hasPassword
                        ? 'Entrar'
                        : 'Receber código',
                    variant: ButtonVariant.primary,
                    onPressed: _login,
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
