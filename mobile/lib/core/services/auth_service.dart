import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/family_link_id.dart';

class AuthRegister {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  static String normalizeElderCode(String elderCode) {
    return elderCode
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String generateElderLinkCode(String seed) {
    final cleaned = seed
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

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
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'elderLinkCode': elderLinkCode,
        'phone': phone,
        'type': 'idoso',
        'institutionId': institutionId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      await _deleteCreatedUser(user);

      if (error.code == 'permission-denied') {
        throw Exception(
          'O Firestore recusou a criação do perfil do idoso. '
          'Verifique se as regras publicadas aceitam elderLinkCode.',
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
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email,
        'phone': phone,
        'type': accountType,
        'institutionId': institutionId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      await _deleteCreatedUser(user);

      if (error.code == 'permission-denied') {
        throw Exception(
          'O Firestore recusou a criação do perfil. '
          'Verifique as regras publicadas.',
        );
      }

      rethrow;
    } catch (_) {
      await _deleteCreatedUser(user);
      rethrow;
    }
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

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

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
      return await _validatedUserDocument(
        credential: credential,
        expectedAccountType: accountType,
      );
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> loginElderWithCodeAndPassword({
    required String elderCode,
    required String password,
  }) {
    return loginWithEmailAndPassword(
      email: AuthRegister.elderAuthEmail(elderCode),
      password: password,
      accountType: 'idoso',
    );
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

    return {
      'id': elderDoc.id,
      ...elderData,
    };
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
    final existingLink = await _firestore
        .collection('familyLinks')
        .doc(linkId)
        .get();

    if (existingLink.exists &&
        existingLink.data()?['status']?.toString() == 'active') {
      throw Exception('Você já está vinculado a este idoso.');
    }

    await _firestore.collection('familyLinks').doc(linkId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'elderId': elderDoc.id,
      'familiarId': normalizedFamilyUid,
      'institutionId': elderInstitutionId,
      'receiveNotifications': receiveNotifications,
      'status': 'active',
    });

    return {
      'id': elderDoc.id,
      ...elderData,
    };
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String phone,
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
    });

    try {
      await user.updateDisplayName(normalizedName);
    } catch (_) {
      // O documento do Firestore é a fonte principal do perfil no app.
    }
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
