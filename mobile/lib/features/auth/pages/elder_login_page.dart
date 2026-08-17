import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/back_button_widget.dart';
import '../../../shared/widgets/button_widget.dart';
import '../../onboarding/models/onboarding_arguments.dart';
import '../../onboarding/pages/onboarding_page.dart';
import '../models/auth_arguments.dart';
import '../models/auth_mode.dart';
import '../widgets/auth_footer_widget.dart';
import '../widgets/auth_header_widget.dart';

class ElderLoginPage extends StatefulWidget {
  final AuthArguments arguments;

  const ElderLoginPage({
    super.key,
    required this.arguments,
  });

  @override
  State<ElderLoginPage> createState() => _ElderLoginPageState();
}

class _ElderLoginPageState extends State<ElderLoginPage> {
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _institutionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final institutionId = _institutionController.text.trim();
    final password = _passwordController.text.trim();

    if (institutionId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o código da instituição.')),
      );
      return;
    }

    if (password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a senha.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final elderUser = await ElderAuthService.instance.loginWithInstitutionAndPassword(
        institutionId: institutionId,
        password: password,
      );

      if (!mounted) return;

      final data = elderUser.data() ?? {};
      final userType = data['type']?.toString() ?? '';

      if (userType != 'idoso') {
        throw Exception('Este usuário não está autorizado para entrar como idoso.');
      }

      context.go(RouteNames.elderHome, extra: data);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is Exception
                ? error.toString().replaceFirst('Exception: ', '')
                : 'Dados de acesso inválidos. Tente novamente.',
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

  @override
  Widget build(BuildContext context) {
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
                      authMode: AuthMode.login,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSizes.xl),

              const AuthHeaderWidget(
                title: 'Acesse com sua conta',
              ),

              const SizedBox(height: AppSizes.xl),

              TextField(
                controller: _institutionController,
                enabled: !_isLoading,
                keyboardType: TextInputType.text,
                obscureText: false,
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  hintText: 'Código da instituição',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.md),

              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  hintText: 'Senha',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(45),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              ButtonWidget(
                label: _isLoading ? 'Entrando...' : 'Entrar',
                variant: ButtonVariant.primary,
                onPressed: _isLoading ? null : _login,
              ),

              const SizedBox(height: AppSizes.lg),

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
