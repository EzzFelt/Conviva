import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';

import '../../../shared/formatters/brazilian_phone_formatter.dart';
import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../../shared/widgets/password_text_field_widget.dart';
import '../../../shared/widgets/text_field_widget.dart';

import '../../onboarding/models/onboarding_arguments.dart';

import '../models/account_type.dart';
import '../models/auth_arguments.dart';
import '../models/auth_mode.dart';
import '../providers/authenticated_user_navigator.dart';
import '../providers/current_user_provider.dart';

import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_header_widget.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final AuthArguments arguments;

  const RegisterPage({
    super.key,
    required this.arguments,
  });

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

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
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) {
      return;
    }

    final accountType = widget.arguments.accountType;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(currentUserProvider.notifier).register(
        name: _nameController.text,
        email: accountType == AccountType.elder
            ? null
            : _emailController.text,
        phone: _phoneController.text,
        institutionCode: _institutionController.text,
        password: _passwordController.text,
        accountType: accountType,
      );

      if (!mounted) return;

      if (result.elderAccessCode != null) {
        await _showElderAccessCode(result.elderAccessCode!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso.'),
          ),
        );
      }

      if (!mounted) return;

      await AuthenticatedUserNavigator.open(context, result.session);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showElderAccessCode(String code) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Código de acesso do idoso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Guarde este código. Ele será usado para entrar na conta '
                'e para o familiar realizar o vínculo.',
              ),
              SizedBox(height: dialogContext.appSizes.md),
              SelectableText(
                code,
                style: Theme.of(dialogContext).textTheme.headlineSmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
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

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = AuthRegister.normalizePhone(value ?? '');

    if (phone.isEmpty) {
      return 'Informe o número de telefone';
    }

    if (phone.length < 10 || phone.length > 11) {
      return 'Informe um número de telefone válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'Informe a senha';
    }

    if (password.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
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
                    enabled: !_isLoading,
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
                      enabled: !_isLoading,
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
                    enabled: !_isLoading,
                    keyboardType: TextInputType.phone,
                    inputFormatters: const [BrazilianPhoneFormatter()],
                    textInputAction: TextInputAction.next,
                    validator: _validatePhone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),

                  SizedBox(height: sizes.md),
                  TextFieldWidget(
                    controller: _institutionController,
                    hintText: accountType == AccountType.elder
                        ? 'Código da instituição'
                        : 'Instituição (Código)',
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _validateRequired(
                      value,
                      'Informe o código da instituição',
                    ),
                  ),

                  SizedBox(height: sizes.md),
                  PasswordTextFieldWidget(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _register(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),

                  SizedBox(height: sizes.xl),

                  ButtonWidget(
                    label: _isLoading ? 'Cadastrando...' : 'Cadastrar',
                    variant: ButtonVariant.primary,
                    onPressed: _isLoading ? null : _register,
                  ),

                  SizedBox(height: sizes.lg),

                  AuthFooterWidget(
                    text: 'Já possui conta?',
                    actionText: 'Entrar',
                    onTap: () {
                      context.go(
                        accountType == AccountType.elder
                            ? RouteNames.elderLogin
                            : RouteNames.login,
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
