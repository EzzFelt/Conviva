import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// Tela de splash (logo inicial)
/// 
/// Exibe o logo do Conviva e verifica se o onboarding já foi completo.
/// - Se SIM: navega para login/home (futura implementação)
/// - Se NÃO: navega para onboarding
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Verificar status do onboarding ao iniciar
    context.read<OnboardingBloc>().add(CheckOnboardingStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingAlreadyCompleted) {
          // TODO: Navegar para tela de login/home
          // Por enquanto, vai para onboarding mesmo
          context.go('/onboarding');
        } else if (state is OnboardingPageChanged) {
          // Onboarding ainda não foi completo
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                AppAssets.logo,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              
              const SizedBox(height: 24),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
