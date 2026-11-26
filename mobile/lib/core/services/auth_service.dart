import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:conviva/shared/utils/profile_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/recovery_config.dart';
import '../utils/family_link_id.dart';

class EmailVerificationRequiredException implements Exception {
  const EmailVerificationRequiredException();
}

class AuthRegister {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static String normalizeElderCode(String elderCode) {
    return elderCode.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String generateElderLinkCode(String seed) {
    final cleaned = seed.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    if (cleaned.isEmpty) {
      throw ArgumentError('Não foi possível gerar o código do idoso.');
    }

    final suffix = cleaned.length > 8
        ? cleaned.substring(0, 8)
        : cleaned.padLeft(8, '0');

    return 'ELD$suffix';
  }

  static String elderAuthEmail(String elderCode) {
    final normalizedCode = normalizeElderCode(elderCode);

    if (!RegExp(r'^ELD[A-Z0-9]{4,}$').hasMatch(normalizedCode)) {
      throw Exception('Informe um código de acesso válido.');
    }

    // Com a recuperação configurada, o e-mail interno cai numa caixa real.
    if (RecoveryConfig.isElderRecoveryConfigured) {
      return RecoveryConfig.elderAuthEmail(normalizedCode.toLowerCase());
    }

    return legacyElderAuthEmail(elderCode);
  }

  /// E-mail interno usado antes da recuperação de senha existir.
  /// Idosos já cadastrados continuam entrando por ele.
  static String legacyElderAuthEmail(String elderCode) {
    final normalizedCode = normalizeElderCode(elderCode);

    if (!RegExp(r'^ELD[A-Z0-9]{4,}$').hasMatch(normalizedCode)) {
      throw Exception('Informe um código de acesso válido.');
    }

    return '${normalizedCode.toLowerCase()}@elder.conviva.app';
  }

  Future<String> resolveInstitutionId(String institutionCode) async {
    final normalizedCode = institutionCode.trim();
    if (normalizedCode.isEmpty) {
      throw Exception('Informe o código da instituição.');
    }

    final institutionDoc = await _firestore
        .collection('institutions')
        .doc(normalizedCode)
        .get();

    if (institutionDoc.exists) {
      return institutionDoc.id;
    }

    final institutionQuery = await _firestore
        .collection('institutions')
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (institutionQuery.docs.isEmpty) {
      throw Exception('Código da instituição inválido.');
    }

    return institutionQuery.docs.first.id;
  }

  Future<String?> register({
    required String name,
    String? email,
    required String phone,
    String? institutionCode,
    String? password,
    required String accountType,
  }) async {
    final normalizedType = accountType.trim();
    final normalizedName = name.trim();
    final normalizedPhone = normalizePhone(phone);
    final normalizedPassword = password?.trim() ?? '';

    if (!{'idoso', 'caregiver', 'family'}.contains(normalizedType)) {
      throw Exception('Tipo de conta inválido.');
    }

    if (normalizedName.isEmpty) {
      throw Exception('Informe o nome completo.');
    }

    if (normalizedPhone.isEmpty) {
      throw Exception('Informe o número de telefone.');
    }

    if (normalizedPhone.length < 10 || normalizedPhone.length > 11) {
      throw Exception('Informe um número de telefone válido.');
    }

    if (normalizedPassword.isEmpty) {
      throw Exception('Informe a senha.');
    }

    if (institutionCode == null || institutionCode.trim().isEmpty) {
      throw Exception('Informe o código da instituição.');
    }

    final institutionId = await resolveInstitutionId(institutionCode);

    if (normalizedType == 'idoso') {
      return _registerElder(
        name: normalizedName,
        phone: normalizedPhone,
        password: normalizedPassword,
        institutionId: institutionId,
      );
    }

    if (email == null || email.trim().isEmpty) {
      throw Exception('Informe o e-mail.');
    }

    await _registerEmailUser(
      name: normalizedName,
      email: email.trim().toLowerCase(),
      phone: normalizedPhone,
      password: normalizedPassword,
      accountType: normalizedType,
      institutionId: institutionId,
    );

    return null;
  }

  Future<String> _registerElder({
    required String name,
    required String phone,
    required String password,
    required String institutionId,
  }) async {
    final codeSeed = _firestore.collection('users').doc().id;
    final elderLinkCode = generateElderLinkCode(codeSeed);
    final authEmail = elderAuthEmail(elderLinkCode);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: authEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Falha ao criar o acesso do idoso.');
    }

    try {
      await user.updateDisplayName(name.trim());
      final userReference = _firestore.collection('users').doc(user.uid);
      final lookupId = RecoveryConfig.elderRecoveryLookupId(elderLinkCode);
      final lookupReference = _firestore
          .collection('elderRecoveryLookups')
          .doc(lookupId);
      final batch = _firestore.batch()
        ..set(userReference, {
          'name': name.trim(),
          'elderLinkCode': elderLinkCode,
          'phone': phone,
          'type': 'idoso',
          'institutionId': institutionId,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..set(lookupReference, {
          'elderUid': user.uid,
          'institutionId': institutionId,
          'familyUid': null,
          'caregiverUid': null,
        });
      await batch.commit();
    } on FirebaseException catch (error) {
      await _deleteCreatedUser(user);

      if (error.code == 'permission-denied') {
        throw Exception(
          'O Firestore recusou a criação do perfil do idoso. '
          'Verifique se as regras publicadas aceitam o perfil e o índice '
          'de recuperação.',
        );
      }

      rethrow;
    } catch (_) {
      await _deleteCreatedUser(user);
      rethrow;
    }

    return elderLinkCode;
  }

  Future<void> _registerEmailUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String accountType,
    required String institutionId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Falha ao criar usuário.');
    }

    try {
      await user.updateDisplayName(name.trim());
      await AuthService.instance._savePendingEmailRegistration(
        uid: user.uid,
        registration: {
          'name': name.trim(),
          'email': email,
          'phone': phone,
          'type': accountType,
          'institutionId': institutionId,
        },
      );
    } catch (_) {
      try {
        await AuthService.instance._clearPendingEmailRegistration(user.uid);
      } catch (_) {
        // Keep the original persistence error as the registration failure.
      }
      await _deleteCreatedUser(user);
      rethrow;
    }

    await user.sendEmailVerification();
  }

  Future<void> _deleteCreatedUser(User user) async {
    try {
      await user.delete();
    } catch (_) {
      // A falha original do cadastro deve continuar sendo exibida.
    } finally {
      try {
        await _auth.signOut();
      } catch (_) {
        // A limpeza não deve esconder a causa original do cadastro.
      }
    }
  }
}

/// Tamanho máximo (em caracteres) do data URI da foto de perfil.
/// Deve ser igual ao limite usado no firestore.rules.
const int maxProfilePhotoLength = 300000;

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferencesAsync _localStore = SharedPreferencesAsync();

  static const String _pendingRegistrationPrefix =
      'conviva_pending_email_registration_';

  String? get currentUserId => _auth.currentUser?.uid;

  /// A sessão ativa é a temporária usada na recuperação de senha do idoso?
  /// Ela existe só no Firebase Auth e não tem perfil em `users`.
  bool get isCurrentUserAnonymous => _auth.currentUser?.isAnonymous ?? false;

  Future<DocumentSnapshot<Map<String, dynamic>>> loginWithEmailAndPassword({
    required String email,
    required String password,
    required String accountType,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );

    try {
      final user = credential.user;
      if (accountType != 'idoso' &&
          accountType != 'support' &&
          user?.emailVerified != true) {
        throw const EmailVerificationRequiredException();
      }

      if (accountType == 'family' || accountType == 'caregiver') {
        await completePendingEmailRegistration();
      }

      return await _validatedUserDocument(
        credential: credential,
        expectedAccountType: accountType,
      );
    } on EmailVerificationRequiredException {
      rethrow;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> loginElderWithCodeAndPassword({
    required String elderCode,
    required String password,
  }) async {
    final primaryEmail = AuthRegister.elderAuthEmail(elderCode);
    final legacyEmail = AuthRegister.legacyElderAuthEmail(elderCode);

    try {
      return await loginWithEmailAndPassword(
        email: primaryEmail,
        password: password,
        accountType: 'idoso',
      );
    } on FirebaseAuthException catch (error) {
      const credentialErrors = {
        'invalid-credential',
        'invalid-login-credentials',
        'user-not-found',
        'wrong-password',
      };

      // Idosos cadastrados antes da recuperação usam o e-mail antigo.
      if (primaryEmail == legacyEmail ||
          !credentialErrors.contains(error.code)) {
        rethrow;
      }

      try {
        return await loginWithEmailAndPassword(
          email: legacyEmail,
          password: password,
          accountType: 'idoso',
        );
      } on FirebaseAuthException {
        throw error;
      }
    }
  }

  String? get currentUserEmail => _auth.currentUser?.email;

  /// O e-mail da conta já foi confirmado pelo link enviado?
  Future<bool> isCurrentEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (!user.emailVerified) await user.reload();
    final refreshedUser = _auth.currentUser;
    final isVerified = refreshedUser?.emailVerified ?? false;
    if (isVerified) {
      await refreshedUser!.getIdToken(true);
    }
    return isVerified;
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    await user.sendEmailVerification();
  }

  Future<bool> hasPendingEmailRegistration() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    return await _localStore.getString(_pendingEmailRegistrationKey(uid)) !=
        null;
  }

  Future<void> completePendingEmailRegistration() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    if (!user.emailVerified) {
      throw const EmailVerificationRequiredException();
    }

    await user.getIdToken(true);
    final userDocument = _firestore.collection('users').doc(user.uid);
    final existing = await userDocument.get();
    if (existing.exists) {
      await _clearPendingEmailRegistration(user.uid);
      return;
    }

    final pendingJson = await _localStore.getString(
      _pendingEmailRegistrationKey(user.uid),
    );
    if (pendingJson == null) {
      throw StateError(
        'Os dados pendentes do cadastro não foram encontrados neste '
        'dispositivo. Entre em contato com o suporte.',
      );
    }

    final decoded = jsonDecode(pendingJson);
    if (decoded is! Map) {
      throw const FormatException('Dados pendentes de cadastro inválidos.');
    }
    final registration = Map<String, dynamic>.from(decoded);
    if (registration['email'] != user.email ||
        !{'caregiver', 'family'}.contains(registration['type'])) {
      throw const FormatException(
        'Os dados pendentes não correspondem à conta autenticada.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final currentDocument = await transaction.get(userDocument);
      if (currentDocument.exists) return;

      transaction.set(userDocument, {
        ...registration,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    await _clearPendingEmailRegistration(user.uid);
  }

  static String _pendingEmailRegistrationKey(String uid) =>
      '$_pendingRegistrationPrefix$uid';

  Future<void> _savePendingEmailRegistration({
    required String uid,
    required Map<String, dynamic> registration,
  }) async {
    await _localStore.setString(
      _pendingEmailRegistrationKey(uid),
      jsonEncode(registration),
    );
  }

  Future<void> _clearPendingEmailRegistration(String uid) async {
    await _localStore.remove(_pendingEmailRegistrationKey(uid));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _validatedUserDocument({
    required UserCredential credential,
    required String expectedAccountType,
  }) async {
    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Falha ao autenticar o usuário.');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data();

    if (!userDoc.exists || userData == null) {
      throw Exception('Perfil do usuário não encontrado.');
    }

    if (userData['type']?.toString() != expectedAccountType) {
      throw Exception('Tipo de conta inválido para este login.');
    }

    if (userData['status']?.toString() != 'active') {
      throw Exception('Esta conta não está ativa.');
    }

    return userDoc;
  }

  Future<Map<String, dynamic>?> getActiveLinkedElderForFamily(
    String familyUid,
  ) async {
    final activeLink = await _firestore
        .collection('familyLinks')
        .where('familiarId', isEqualTo: familyUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (activeLink.docs.isEmpty) {
      return null;
    }

    final elderId = activeLink.docs.first.data()['elderId']?.toString();
    if (elderId == null || elderId.isEmpty) {
      return null;
    }

    final elderDoc = await _firestore.collection('users').doc(elderId).get();
    final elderData = elderDoc.data();

    if (!elderDoc.exists ||
        elderData == null ||
        elderData['type']?.toString() != 'idoso') {
      return null;
    }

    return {'id': elderDoc.id, ...elderData};
  }

  Future<Map<String, dynamic>> linkFamilyMemberToElder({
    required String familyUid,
    required String elderLinkCode,
    required bool receiveNotifications,
  }) async {
    final normalizedFamilyUid = familyUid.trim();
    final normalizedElderLinkCode = AuthRegister.normalizeElderCode(
      elderLinkCode,
    );

    if (normalizedFamilyUid.isEmpty) {
      throw Exception('Usuário familiar não identificado.');
    }

    if (normalizedElderLinkCode.isEmpty) {
      throw Exception('Informe o código do idoso.');
    }

    final familyDoc = await _firestore
        .collection('users')
        .doc(normalizedFamilyUid)
        .get();
    final familyData = familyDoc.data();

    if (!familyDoc.exists || familyData == null) {
      throw Exception('Perfil do familiar não encontrado.');
    }

    final familyInstitutionId = familyData['institutionId']?.toString();
    if (familyInstitutionId == null || familyInstitutionId.isEmpty) {
      throw Exception(
        'O responsável não está vinculado a uma instituição válida.',
      );
    }

    final elderQuery = await _firestore
        .collection('users')
        .where('institutionId', isEqualTo: familyInstitutionId)
        .where('type', isEqualTo: 'idoso')
        .where('elderLinkCode', isEqualTo: normalizedElderLinkCode)
        .limit(2)
        .get();

    if (elderQuery.docs.isEmpty) {
      throw Exception('Código do idoso não encontrado.');
    }

    if (elderQuery.docs.length > 1) {
      throw Exception('Mais de um idoso encontrado para este código.');
    }

    final elderDoc = elderQuery.docs.first;
    final elderData = elderDoc.data();
    final elderInstitutionId = elderData['institutionId']?.toString();

    if (elderInstitutionId == null || elderInstitutionId.isEmpty) {
      throw Exception('O idoso não possui instituição válida.');
    }

    if (elderInstitutionId != familyInstitutionId) {
      throw Exception(
        'O idoso e o familiar devem pertencer à mesma instituição.',
      );
    }

    final linkId = FamilyLinkId.forUsers(
      elderId: elderDoc.id,
      familyId: normalizedFamilyUid,
    );
    final linkReference = _firestore.collection('familyLinks').doc(linkId);
    final existingLink = await linkReference.get();
    final existingStatus = existingLink.data()?['status']?.toString();

    if (existingLink.exists && existingStatus == 'active') {
      throw Exception('Você já está vinculado a este idoso.');
    }

    if (existingLink.exists && existingStatus == 'pending') {
      throw Exception(
        'Você já enviou uma solicitação para este idoso. '
        'Aguarde ele aceitar.',
      );
    }

    if (existingLink.exists) {
      // Solicitação recusada antes: o familiar pode pedir de novo.
      await linkReference.update({
        'createdAt': FieldValue.serverTimestamp(),
        'receiveNotifications': receiveNotifications,
        'status': 'pending',
      });
    } else {
      // O vínculo só vira 'active' quando o próprio idoso aceitar.
      await linkReference.set({
        'createdAt': FieldValue.serverTimestamp(),
        'elderId': elderDoc.id,
        'familiarId': normalizedFamilyUid,
        'institutionId': elderInstitutionId,
        'receiveNotifications': receiveNotifications,
        'status': 'pending',
      });
    }

    return {'id': elderDoc.id, 'linkStatus': 'pending', ...elderData};
  }

  /// O familiar tem alguma solicitação aguardando resposta do idoso?
  Future<bool> hasPendingLinkForFamily(String familyUid) async {
    final pending = await _firestore
        .collection('familyLinks')
        .where('familiarId', isEqualTo: familyUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return pending.docs.isNotEmpty;
  }

  /// O idoso aceita ou recusa o pedido de vínculo de um familiar.
  Future<void> respondToFamilyLinkRequest({
    required String linkId,
    required bool accept,
  }) {
    return _firestore.collection('familyLinks').doc(linkId).update({
      'status': accept ? 'active' : 'rejected',
    });
  }

  Future<void> unlinkFamilyRelationship(String linkId) {
    final normalizedLinkId = linkId.trim();
    if (normalizedLinkId.isEmpty) {
      throw ArgumentError('O vínculo não foi identificado.');
    }

    return _firestore.collection('familyLinks').doc(normalizedLinkId).delete();
  }

  /// Confirma a senha de quem está logado (usada para mostrar o código do
  /// idoso). Não altera a sessão.
  /// Envia o link de redefinição de senha (familiar e cuidador).
  /// Não revela se o e-mail existe ou não.
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      throw Exception('Informe o e-mail.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') return;
      rethrow;
    }
  }

  Future<void> verifyCurrentPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw Exception('Senha incorreta.');
        case 'too-many-requests':
          throw Exception(
            'Muitas tentativas. Tente novamente em alguns minutos.',
          );
        default:
          throw Exception('Não foi possível confirmar a senha.');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String phone,
    String? jobTitle,
    String? workShift,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    final normalizedName = name.trim();
    final normalizedPhone = AuthRegister.normalizePhone(phone);

    if (normalizedName.isEmpty) {
      throw Exception('Informe o nome completo.');
    }

    if (normalizedPhone.length < 10 || normalizedPhone.length > 11) {
      throw Exception('Informe um número de telefone válido.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'name': normalizedName,
      'phone': normalizedPhone,
      if (jobTitle != null) 'jobTitle': jobTitle.trim(),
      if (workShift != null) 'workShift': workShift.trim(),
    });

    try {
      await user.updateDisplayName(normalizedName);
    } catch (_) {
      // O documento do Firestore é a fonte principal do perfil no app.
    }
  }

  /// Salva a foto de perfil como data URI (base64) em `users/{uid}.photoUrl`.
  ///
  /// A imagem já chega reduzida (400x400, qualidade 70) pelo ImagePicker,
  /// então fica bem abaixo do limite de 1 MB de um documento do Firestore.
  Future<String> saveProfilePhoto({
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    final mimeType = switch (extension.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final dataUri = buildProfileDataUri(bytes, mimeType: mimeType);

    if (dataUri.length > maxProfilePhotoLength) {
      throw Exception('A imagem é muito grande. Escolha uma menor.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': dataUri,
    });

    return dataUri;
  }

  Future<void> removeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'photoUrl': FieldValue.delete(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getInstitutionById(
    String institutionId,
  ) async {
    final normalizedId = institutionId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Instituição não identificada.');
    }

    final institution = await _firestore
        .collection('institutions')
        .doc(normalizedId)
        .get();

    if (!institution.exists || institution.data() == null) {
      throw Exception('Instituição não encontrada.');
    }

    return institution;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(
    String userId,
  ) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('Usuário não encontrado.');
    }

    return userDoc;
  }
}
