import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/route_names.dart';
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
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _login() {
    // TODO: Firebase + Provider
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
                title: 'Acesse com seu PIN',
              ),

              const SizedBox(height: AppSizes.xl),

              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                cursorColor: Theme.of(context).primaryColor,
                decoration: InputDecoration(
                  hintText: 'Digite seu PIN de 4 dígitos',
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
                  counterText: '',
                ),
              ),

              const SizedBox(height: AppSizes.xl),

              ButtonWidget(
                label: 'Entrar',
                variant: ButtonVariant.primary,
                onPressed: _login,
              ),

              const SizedBox(height: AppSizes.lg),

              AuthFooterWidget(
                text: 'Ainda não possui conta?',
                actionText: 'Cadastre-se',
                onTap: () {
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
