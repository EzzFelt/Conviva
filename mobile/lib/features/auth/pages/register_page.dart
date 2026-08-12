import 'package:firebase_auth/firebase_auth.dart';
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

import '../models/account_type.dart';
import '../models/auth_arguments.dart';
import '../models/auth_mode.dart';

import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_header_widget.dart';

import '../../../core/services/auth_service.dart';

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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 Future<void> _register() async {
  final accountType = widget.arguments.accountType;

  try {
    await AuthRegister().register(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      institutionCode: accountType == AccountType.caregiver ? _institutionController.text : null,
      password: _passwordController.text,
      accountType: accountType.name,
    );

    // Se registro funcionar, mostra cadastro com sucesso
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastro realizado com Sucesso'),
       ),
    );

    context.go(
      RouteNames.login,
      extra: AuthArguments(
        accountType: accountType,
        authMode: AuthMode.login,
      ),
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message;

    switch(e.code) {
      case 'email-already-in-use':
       message = 'Este e-mail já está cadastrado.';
       break;

      case 'invalid-email':
       message = 'Digite um e-mail válido.';
       break;

      case 'weak-password':
       message = "A senha deve ser mais forte.";
       break;

      default:
       message = "Erro ao cadastrar usuário: ${e.message}";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }
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
                controller: _emailController,
                hintText: 'E-mail',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppSizes.md),

              TextFieldWidget(
                controller: _phoneController,
                hintText: 'Número de telefone',
                keyboardType: TextInputType.phone,
              ),

              if (accountType == AccountType.caregiver) ...[
                const SizedBox(height: AppSizes.md),

                TextFieldWidget(
                  controller: _institutionController,
                  hintText: 'Instituição (Código)',
                ),
              ],

              if (accountType != AccountType.elder) ...[
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