import '../../domain/entities/user_type.dart';

/// Estados do Bloc de onboarding
sealed class OnboardingState {}

/// Estado inicial
class OnboardingInitial extends OnboardingState {}

/// Estado: Página mudou
class OnboardingPageChanged extends OnboardingState {
  final int currentPage;
  final int totalPages;

  OnboardingPageChanged({required this.currentPage, required this.totalPages});

  /// Verifica se é a última página
  bool get isLastPage => currentPage == totalPages - 1;

  /// Verifica se é a primeira página
  bool get isFirstPage => currentPage == 0;
}

/// Estado: Onboarding completo (navegar para seleção de tipo)
class OnboardingCompleted extends OnboardingState {}

/// Estado: Tipo de usuário selecionado (navegar para próxima tela)
class UserTypeSelected extends OnboardingState {
  final UserType userType;

  UserTypeSelected(this.userType);
}

/// Estado: Onboarding já foi completo anteriormente (pular)
class OnboardingAlreadyCompleted extends OnboardingState {}

/// Estado: Carregando
class OnboardingLoading extends OnboardingState {}

/// Estado: Erro
class OnboardingError extends OnboardingState {
  final String message;

  OnboardingError(this.message);
}
