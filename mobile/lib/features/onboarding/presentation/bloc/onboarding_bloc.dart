import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_onboarding_status.dart';
import '../../domain/usecases/complete_onboarding.dart';
import '../../data/models/onboarding_page_model.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Bloc de onboarding
///
/// Gerencia o estado do fluxo de onboarding:
/// - Navegação entre páginas
/// - Marcação de onboarding completo
/// - Seleção de tipo de usuário
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final CompleteOnboarding completeOnboardingUseCase;
  final CheckOnboardingStatus checkOnboardingStatusUseCase;

  int _currentPage = 0;
  final int _totalPages = OnboardingPageModel.getPages().length;

  OnboardingBloc({
    required this.completeOnboardingUseCase,
    required this.checkOnboardingStatusUseCase,
  }) : super(OnboardingInitial()) {
    // Registrar handlers de eventos
    on<CheckOnboardingStatusEvent>(_onCheckOnboardingStatus);
    on<NextPageEvent>(_onNextPage);
    on<PreviousPageEvent>(_onPreviousPage);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
    on<SelectUserTypeEvent>(_onSelectUserType);
  }

  /// Handler: Verificar se onboarding já foi completo
  Future<void> _onCheckOnboardingStatus(
    CheckOnboardingStatusEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());

    try {
      final isCompleted = await checkOnboardingStatusUseCase();

      if (isCompleted) {
        emit(OnboardingAlreadyCompleted());
      } else {
        // Inicia na primeira página
        emit(OnboardingPageChanged(currentPage: 0, totalPages: _totalPages));
      }
    } catch (e) {
      emit(OnboardingError('Erro ao verificar status do onboarding'));
    }
  }

  /// Handler: Próxima página
  void _onNextPage(NextPageEvent event, Emitter<OnboardingState> emit) {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      emit(
        OnboardingPageChanged(
          currentPage: _currentPage,
          totalPages: _totalPages,
        ),
      );
    }
  }

  /// Handler: Página anterior
  void _onPreviousPage(PreviousPageEvent event, Emitter<OnboardingState> emit) {
    if (_currentPage > 0) {
      _currentPage--;
      emit(
        OnboardingPageChanged(
          currentPage: _currentPage,
          totalPages: _totalPages,
        ),
      );
    }
  }

  /// Handler: Completar onboarding
  Future<void> _onCompleteOnboarding(
    CompleteOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(OnboardingLoading());

    try {
      await completeOnboardingUseCase();
      emit(OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError('Erro ao completar onboarding'));
    }
  }

  /// Handler: Selecionar tipo de usuário
  void _onSelectUserType(
    SelectUserTypeEvent event,
    Emitter<OnboardingState> emit,
  ) {
    // Aqui poderíamos salvar no repository também
    // Por enquanto, apenas emite o estado
    emit(UserTypeSelected(event.userType));
  }
}
