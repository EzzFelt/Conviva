import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../models/account_type.dart';
import '../models/auth_registration_result.dart';
import '../models/user_session.dart';

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserSession?>(
      CurrentUserNotifier.new,
    );

class CurrentUserNotifier extends AsyncNotifier<UserSession?> {
  final AuthService _authService = AuthService.instance;

  @override
  Future<UserSession?> build() => _loadCurrentSession();

  Future<AuthRegistrationResult> register({
    required String name,
    required String phone,
    required String institutionCode,
    required String password,
    required AccountType accountType,
    String? email,
  }) async {
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
        },
      );

      final session = await _requireCurrentSession();
      state = AsyncData(session);

      return AuthRegistrationResult(
        session: session,
        elderAccessCode: elderAccessCode,
      );
    } catch (error, stackTrace) {
      try {
        await _authService.signOut();
      } catch (_) {
        // O erro original do cadastro deve continuar sendo exibido.
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
          AccountType.elder => throw ArgumentError(
              'O idoso deve entrar usando o código de acesso.',
            ),
        },
      );

      final session = UserSession.fromMap(
        uid: userDocument.id,
        data: userDocument.data()!,
      );
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
  }) async {
    final currentSession = state.value;
    if (currentSession == null) {
      throw StateError('Usuário não autenticado.');
    }

    try {
      await _authService.updateCurrentUserProfile(
        name: name,
        phone: phone,
      );

      final updatedSession = currentSession.copyWith(
        name: name.trim(),
        phone: AuthRegister.normalizePhone(phone),
      );
      state = AsyncData(updatedSession);
      return updatedSession;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
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
    if (userId == null) {
      return null;
    }

    final userDocument = await _authService.getUserById(userId);
    final data = userDocument.data();
    if (data == null) {
      throw StateError('Perfil do usuário não encontrado.');
    }

    final session = UserSession.fromMap(
      uid: userDocument.id,
      data: data,
    );

    if (session.status != 'active') {
      throw StateError('Esta conta não está ativa.');
    }

    return session;
  }
}
