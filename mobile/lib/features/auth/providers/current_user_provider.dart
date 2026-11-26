import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../tutorial/services/elder_tutorial_storage.dart';
import '../models/account_type.dart';
import '../models/auth_registration_result.dart';
import '../models/user_session.dart';

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserSession?>(
      CurrentUserNotifier.new,
      retry: (retryCount, error) => null,
    );

class CurrentUserNotifier extends AsyncNotifier<UserSession?> {
  late final AuthService _authService = AuthService.instance;

  @override
  Future<UserSession?> build() => _loadCurrentSession();

  /// Inicializa as preferências sem impedir a autenticação
  /// caso ocorra algum problema no carregamento.
  Future<void> _initializeSettings(String? userId) async {
    try {
      await ref.read(appSettingsProvider.notifier).initialize(userId: userId);
    } catch (_) {
      // As preferências não devem bloquear a autenticação.
    }
  }

  Future<AuthRegistrationResult> register({
    required String name,
    required String phone,
    required String institutionCode,
    required String password,
    required AccountType accountType,
    String? email,
  }) async {
    if (accountType == AccountType.support) {
      throw StateError('Contas de suporte são criadas pelo administrador.');
    }

    state = const AsyncLoading();

    try {
      final elderAccessCode = await AuthRegister().register(
        name: name,
        email: email,
        phone: phone,
        institutionCode: institutionCode,
        password: password,
        accountType: switch (accountType) {
          AccountType.elder => 'idoso',
          AccountType.caregiver => 'caregiver',
          AccountType.family => 'family',
          AccountType.support => throw StateError(
            'Contas de suporte não podem ser cadastradas pelo aplicativo.',
          ),
        },
      );

      if (accountType != AccountType.elder) {
        await _initializeSettings(null);
        state = const AsyncData(null);
        return const AuthRegistrationResult(
          session: null,
          requiresEmailVerification: true,
        );
      }

      final session = await _requireCurrentSession();

      // Idoso recém-cadastrado: depois do cadastro, o app pergunta se ele
      // quer fazer o tutorial.
      await ElderTutorialStorage.markPending(session.uid);

      state = AsyncData(session);

      return AuthRegistrationResult(
        session: session,
        elderAccessCode: elderAccessCode,
      );
    } catch (error, stackTrace) {
      try {
        await _authService.signOut();
        await _initializeSettings(null);
      } catch (_) {
        // Preserva o erro original do cadastro.
      }

      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UserSession> loginWithEmail({
    required String email,
    required String password,
    required AccountType accountType,
  }) async {
    state = const AsyncLoading();

    try {
      final userDocument = await _authService.loginWithEmailAndPassword(
        email: email,
        password: password,
        accountType: switch (accountType) {
          AccountType.caregiver => 'caregiver',
          AccountType.family => 'family',
          AccountType.support => 'support',
          AccountType.elder => throw ArgumentError(
            'O idoso deve entrar usando o código de acesso.',
          ),
        },
      );

      final session = UserSession.fromMap(
        uid: userDocument.id,
        data: userDocument.data()!,
      );

      await _initializeSettings(session.uid);

      state = AsyncData(session);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UserSession> loginElder({
    required String elderCode,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final userDocument = await _authService.loginElderWithCodeAndPassword(
        elderCode: elderCode,
        password: password,
      );

      final session = UserSession.fromMap(
        uid: userDocument.id,
        data: userDocument.data()!,
      );

      await _initializeSettings(session.uid);

      state = AsyncData(session);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UserSession?> refresh() async {
    state = const AsyncLoading();

    try {
      final session = await _loadCurrentSession();
      state = AsyncData(session);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<UserSession> updateProfile({
    required String name,
    required String phone,
    String? jobTitle,
    String? workShift,
  }) async {
    final currentSession = state.value;

    if (currentSession == null) {
      throw StateError('Usuário não autenticado.');
    }

    try {
      final isCaregiver = currentSession.accountType == AccountType.caregiver;
      final updatedJobTitle = isCaregiver
          ? (jobTitle ?? currentSession.jobTitle).trim()
          : null;
      final updatedWorkShift = isCaregiver
          ? (workShift ?? currentSession.workShift).trim()
          : null;

      await _authService.updateCurrentUserProfile(
        name: name,
        phone: phone,
        jobTitle: updatedJobTitle,
        workShift: updatedWorkShift,
      );

      final updatedSession = currentSession.copyWith(
        name: name.trim(),
        phone: AuthRegister.normalizePhone(phone),
        jobTitle: updatedJobTitle,
        workShift: updatedWorkShift,
      );

      state = AsyncData(updatedSession);
      return updatedSession;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<UserSession> updateProfilePhoto({
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final currentSession = state.value;

    if (currentSession == null) {
      throw StateError('Usuário não autenticado.');
    }

    final photoUrl = await _authService.saveProfilePhoto(
      bytes: bytes,
      extension: extension,
    );

    final updatedSession = currentSession.copyWith(photoUrl: photoUrl);
    state = AsyncData(updatedSession);
    return updatedSession;
  }

  Future<UserSession> removeProfilePhoto() async {
    final currentSession = state.value;

    if (currentSession == null) {
      throw StateError('Usuário não autenticado.');
    }

    await _authService.removeProfilePhoto();

    final updatedSession = currentSession.copyWith(clearPhotoUrl: true);
    state = AsyncData(updatedSession);
    return updatedSession;
  }

  Future<void> signOut() async {
    await _authService.signOut();

    await _initializeSettings(null);

    state = const AsyncData(null);
  }

  Future<UserSession> _requireCurrentSession() async {
    final session = await _loadCurrentSession();

    if (session == null) {
      throw StateError('A sessão não foi criada após a autenticação.');
    }

    return session;
  }

  Future<UserSession?> _loadCurrentSession() async {
    final userId = _authService.currentUserId;

    // A sessão anônima da recuperação de senha não tem perfil em `users`.
    // Ela não é uma conta do app: segue sem sessão (vai para o início) e é
    // mantida para a recuperação continuar quando a pessoa voltar a ela.
    if (userId == null || _authService.isCurrentUserAnonymous) {
      await _initializeSettings(null);
      return null;
    }

    final userDocument = await _authService.getUserById(userId);
    final data = userDocument.data();

    if (data == null) {
      await _initializeSettings(null);
      return null;
    }

    final session = UserSession.fromMap(uid: userDocument.id, data: data);

    if (session.status != 'active') {
      throw StateError('Esta conta não está ativa.');
    }

    await _initializeSettings(session.uid);

    return session;
  }
}
