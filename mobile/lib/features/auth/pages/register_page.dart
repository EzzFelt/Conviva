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

class RegisterPage extends StatefulWidget {
  final AuthArguments arguments;

  const RegisterPage({
    super.key,
    required this.arguments,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    // TODO Firebase
  }

  @override
  Widget build(BuildContext context) {
    final accountType = widget.arguments.accountType;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.lg,
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
                      authMode: AuthMode.register,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSizes.xl),

              const AuthHeaderWidget(
                title: 'Faça seu\ncadastro aqui!',
              ),

              const SizedBox(height: AppSizes.xl),

              TextFieldWidget(
                controller: _nameController,
                hintText: 'Nome completo',
              ),

              const SizedBox(height: AppSizes.md),

              TextFieldWidget(
                controller: _phoneController,
                hintText: 'Número de telefone',
                keyboardType: TextInputType.phone,
              ),

              if (accountType.hasInstitution) ...[
                const SizedBox(height: AppSizes.md),

                TextFieldWidget(
                  controller: _institutionController,
                  hintText: 'Instituição (Código)',
                ),
              ],

              if (accountType.hasPassword) ...[
                const SizedBox(height: AppSizes.md),

                PasswordTextFieldWidget(
                  controller: _passwordController,
                ),
              ],

              const SizedBox(height: AppSizes.xl),

              ButtonWidget(
                label: 'Cadastrar',
                variant: ButtonVariant.orange,
                onPressed: _register,
              ),

              const SizedBox(height: AppSizes.lg),

              AuthFooterWidget(
                text: 'Já possui conta?',
                actionText: 'Entrar',
                onTap: () {
                  context.go(
                    RouteNames.login,
                    extra: AuthArguments(
                      accountType: accountType,
                      authMode: AuthMode.login,
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