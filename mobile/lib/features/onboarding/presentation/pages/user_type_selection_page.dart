import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/user_type.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/user_type_card.dart';

/// Tela de seleção de tipo de usuário
/// 
/// Permite escolher entre:
/// - Idoso
/// - Cuidador
/// - Familiar
class UserTypeSelectionPage extends StatelessWidget {
  const UserTypeSelectionPage({super.key});

  void _onSelectUserType(BuildContext context, UserType userType) {
    context.read<OnboardingBloc>().add(SelectUserTypeEvent(userType));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is UserTypeSelected) {
          // TODO: Navegar para tela de cadastro/login
          // Por enquanto, apenas mostra um snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tipo selecionado: ${state.userType.description}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Escolha o tipo de conta'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Título
                Text(
                  'Escolha qual o tipo de conta:',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: 28,
                  ),
                ),

                const SizedBox(height: 32),

                // Card: Idoso
                UserTypeCard(
                  icon: Icons.elderly,
                  title: 'Para idosos',
                  description: 'Vamos leva tarefa e coisas práticas',
                  onTap: () => _onSelectUserType(context, UserType.idoso),
                ),

                const SizedBox(height: 16),

                // Card: Cuidador
                UserTypeCard(
                  icon: Icons.people,
                  title: 'Para cuidadores',
                  description: 'Gerenciar e auxiliar ao atendimento do idoso',
                  onTap: () => _onSelectUserType(context, UserType.cuidador),
                ),

                const SizedBox(height: 16),

                // Card: Familiar
                UserTypeCard(
                  icon: Icons.family_restroom,
                  title: 'Para familiares',
                  description: 'Acompanhe idoso e envie mensagens e conteúdo',
                  onTap: () => _onSelectUserType(context, UserType.familiar),
                ),

                const Spacer(),

                // Link "Já tem conta?"
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navegar para login
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navegar para login (em desenvolvimento)'),
                        ),
                      );
                    },
                    child: Text(
                      'Já tem uma conta? Entre',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
