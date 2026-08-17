import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';

import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/password_text_field_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';

import '../../onboarding/models/onboarding_arguments.dart';
import '../../onboarding/pages/onboarding_page.dart';

import '../models/account_type.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final accountType = widget.arguments.accountType;

    try {
      await AuthRegister().register(
        name: _nameController.text,
        email: accountType == AccountType.elder ? null : _emailController.text,
        phone: _phoneController.text,
        institutionCode: accountType.hasInstitution
            ? _institutionController.text
            : null,
        password: _passwordController.text,
        pin: null,
        accountType: accountType == AccountType.elder ? 'idoso' : accountType.name,
      );

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

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este e-mail já está cadastrado.';
          break;
        case 'invalid-email':
          message = 'Digite um e-mail válido.';
          break;
        case 'weak-password':
          message = 'A senha deve ser mais forte.';
          break;
        default:
          message = 'Erro ao cadastrar usuário: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido';
    }

    return null;
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
                          authMode: AuthMode.register,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: sizes.xl),

                  const AuthHeaderWidget(
                    title: 'Faça seu\ncadastro aqui!',
                  ),

                  SizedBox(height: sizes.xl),

                  TextFieldWidget(
                    controller: _nameController,
                    hintText: 'Nome completo',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _validateRequired(
                      value,
                      'Informe o nome completo',
                    ),
                    autofillHints: const [AutofillHints.name],
                  ),

                  SizedBox(height: sizes.md),

                  if (accountType != AccountType.elder) ...[
                    TextFieldWidget(
                      controller: _emailController,
                      hintText: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      autofillHints: const [AutofillHints.email],
                    ),

                    SizedBox(height: sizes.md),
                  ],

                  TextFieldWidget(
                    controller: _phoneController,
                    hintText: 'Número de telefone',
                    keyboardType: TextInputType.phone,
                    textInputAction: accountType.hasPassword ||
                            accountType.hasInstitution ||
                            accountType == AccountType.elder
                        ? TextInputAction.next
                        : TextInputAction.done,
                    validator: _validatePhone,
                    onFieldSubmitted:
                        accountType.hasPassword || accountType.hasInstitution || accountType == AccountType.elder
                            ? null
                            : (_) => _register(),
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),

                  if (accountType.hasInstitution) ...[
                    SizedBox(height: sizes.md),
                    TextFieldWidget(
                      controller: _institutionController,
                      hintText: accountType == AccountType.elder
                          ? 'Código da instituição'
                          : 'Instituição (Código)',
                      textInputAction: TextInputAction.next,
                      validator: (value) => _validateRequired(
                        value,
                        'Informe o código da instituição',
                      ),
                    ),
                  ],

                  SizedBox(height: sizes.md),
                  PasswordTextFieldWidget(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    validator: (value) => _validateRequired(
                      value,
                      'Informe a senha',
                    ),
                    onFieldSubmitted: (_) => _register(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),

                  SizedBox(height: sizes.xl),

                  ButtonWidget(
                    label: 'Cadastrar',
                    variant: ButtonVariant.primary,
                    onPressed: _register,
                  ),

                  SizedBox(height: sizes.lg),

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
        ),
      ),
    );
  }
}
