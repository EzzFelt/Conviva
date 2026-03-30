import '../../domain/entities/user_type.dart';

/// Eventos do Bloc de onboarding
sealed class OnboardingEvent {}

/// Evento: Navegar para próxima página
class NextPageEvent extends OnboardingEvent {}

/// Evento: Navegar para página anterior
class PreviousPageEvent extends OnboardingEvent {}

/// Evento: Completar onboarding (última tela)
class CompleteOnboardingEvent extends OnboardingEvent {}

/// Evento: Selecionar tipo de usuário
class SelectUserTypeEvent extends OnboardingEvent {
  final UserType userType;

  SelectUserTypeEvent(this.userType);
}

/// Evento: Verificar se onboarding já foi completo (ao iniciar app)
class CheckOnboardingStatusEvent extends OnboardingEvent {}
