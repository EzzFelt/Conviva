import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/onboarding_page_model.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/page_indicator.dart';
import '../widgets/primary_button.dart';

/// Tela de onboarding com PageView
/// 
/// Exibe as 3 telas de introdução ao aplicativo.
/// Permite navegação por swipe ou botão "Continuar".
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final List<OnboardingPageModel> _pages = OnboardingPageModel.getPages();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    // Atualizar página no Bloc ao fazer swipe
    // (O Bloc já controla internamente, mas sincronizamos aqui)
  }

  void _onContinue(OnboardingPageChanged state) {
    if (state.isLastPage) {
      // Última página: completar onboarding e ir para seleção de tipo
      context.read<OnboardingBloc>().add(CompleteOnboardingEvent());
    } else {
      // Próxima página
      context.read<OnboardingBloc>().add(NextPageEvent());
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          // Navegar para seleção de tipo de usuário
          context.go('/user-type-selection');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              if (state is OnboardingPageChanged) {
                return Column(
                  children: [
                    // PageView com conteúdo
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return OnboardingContent(
                            page: _pages[index],
                          );
                        },
                      ),
                    ),

                    // Indicador de páginas
                    PageIndicator(
                      currentPage: state.currentPage,
                      pageCount: state.totalPages,
                    ),

                    const SizedBox(height: 32),

                    // Botão "Continuar" ou "Comece Agora"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: PrimaryButton(
                        text: state.isLastPage ? 'Comece Agora!' : 'Continuar',
                        onPressed: () => _onContinue(state),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                );
              }

              // Estado de loading
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
