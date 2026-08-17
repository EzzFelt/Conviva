import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRegister {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password.trim())).toString();
  }

  static String generateElderLinkCode(String elderId) {
    final cleaned = elderId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.isEmpty) {
      return 'ELD${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

    final code = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned.padLeft(6, '0');
    return 'ELD$code';
  }

  Future<String> resolveInstitutionId(String institutionCode) async {
    final normalizedCode = institutionCode.trim();
    if (normalizedCode.isEmpty) {
      throw Exception('Informe o código da instituição.');
    }

    final institutionDoc = await _firestore.collection('institutions').doc(normalizedCode).get();
    if (institutionDoc.exists) {
      return institutionDoc.id;
    }

    final institutionQuery = await _firestore
        .collection('institutions')
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (institutionQuery.docs.isEmpty) {
      throw Exception('Código da instituição inválido');
    }

    return institutionQuery.docs.first.id;
  }

  Future<void> register({
    required String name,
    String? email,
    required String phone,
    String? institutionCode,
    String? password,
    required String accountType,
    String? pin,
  }) async {
    final normalizedType = accountType.trim();

    if (normalizedType == 'idoso') {
      if (institutionCode == null || institutionCode.trim().isEmpty) {
        throw Exception('Informe o código da instituição do idoso.');
      }

      if (password == null || password.trim().isEmpty) {
        throw Exception('Senha obrigatória para o idoso.');
      }

      final institutionId = await resolveInstitutionId(institutionCode);
      final elderDocRef = _firestore.collection('users').doc();
      final elderLinkCode = generateElderLinkCode(elderDocRef.id);

      await elderDocRef.set({
        'name': name.trim(),
        'elderLinkCode': elderLinkCode,
        'phone': phone.trim(),
        'passwordHash': hashPassword(password),
        'type': 'idoso',
        'institutionId': institutionId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return;
    }

    if (email == null || email.trim().isEmpty) {
      throw Exception('E-mail obrigatório para este tipo de cadastro.');
    }

    if (password == null || password.trim().isEmpty) {
      throw Exception('Senha obrigatória para este tipo de cadastro.');
    }

    String? institutionId;

    if (normalizedType == 'caregiver') {
      if (institutionCode == null || institutionCode.trim().isEmpty) {
        throw Exception('Código da instituição inválido');
      }

      institutionId = await resolveInstitutionId(institutionCode);
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Falha ao criar usuário');
    }

    final userData = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'type': normalizedType,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (institutionId != null) {
      userData['institutionId'] = institutionId;
    }

    await _firestore.collection('users').doc(user.uid).set(userData);
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String findMatchingElderUser({
    required List<Map<String, dynamic>> elderUsers,
    required String password,
  }) {
    final enteredHash = AuthRegister.hashPassword(password);
    final matches = elderUsers.where((user) {
      final storedHash = user['passwordHash']?.toString() ?? '';
      return storedHash.isNotEmpty && storedHash == enteredHash;
    }).toList();

    if (matches.isEmpty) {
      throw Exception('Senha incorreta para esta instituição.');
    }

    if (matches.length > 1) {
      throw StateError(
        'Mais de um idoso foi identificado com a mesma senha dentro da instituição.',
      );
    }

    final matchedId = matches.first['id']?.toString();
    if (matchedId == null || matchedId.isEmpty) {
      throw Exception('Não foi possível identificar o idoso autenticado.');
    }

    return matchedId;
  }

  Future<String> _resolveInstitutionId(String institutionCode) async {
    final normalizedCode = institutionCode.trim();
    if (normalizedCode.isEmpty) {
      throw Exception('Informe o código da instituição.');
    }

    final directDoc = await _firestore.collection('institutions').doc(normalizedCode).get();
    if (directDoc.exists) {
      return directDoc.id;
    }

    final query = await _firestore
        .collection('institutions')
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Instituição inválida ou não encontrada.');
    }

    return query.docs.first.id;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> loginWithPhoneAndPassword({
    required String phone,
    required String password,
    required String accountType,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (normalizedPhone.isEmpty) {
      throw Exception('Informe o número de telefone.');
    }

    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: normalizedPhone)
        .where('type', isEqualTo: accountType)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Usuário não encontrado.');
    }

    final data = query.docs.first.data();
    final email = data['email']?.toString();
    if (email == null || email.isEmpty) {
      throw Exception('Usuário sem e-mail de acesso válido.');
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw Exception('Falha ao autenticar o usuário.');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('Perfil do usuário não encontrado.');
    }

    if (userDoc.data()!['type'] != accountType) {
      throw Exception('Tipo de conta inválido para este login.');
    }

    return userDoc;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> loginWithInstitutionAndPassword({
    required String institutionId,
    required String password,
  }) async {
    final resolvedInstitutionId = await _resolveInstitutionId(institutionId);

    final elderQuery = await _firestore
        .collection('users')
        .where('institutionId', isEqualTo: resolvedInstitutionId)
        .where('type', isEqualTo: 'idoso')
        .get();

    if (elderQuery.docs.isEmpty) {
      throw Exception('Instituição inválida ou não encontrada.');
    }

    final elderUsers = elderQuery.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    final matchedElderId = findMatchingElderUser(
      elderUsers: elderUsers,
      password: password,
    );

    final matchedDoc = elderQuery.docs.firstWhere(
      (doc) => doc.id == matchedElderId,
      orElse: () => throw Exception('Usuário idoso não encontrado.'),
    );

    return matchedDoc;
  }

  Future<void> linkFamilyMemberToElder({
    required String familyUid,
    required String elderLinkCode,
  }) async {
    final normalizedFamilyUid = familyUid.trim();
    final normalizedElderLinkCode = elderLinkCode.trim().toUpperCase();

    if (normalizedFamilyUid.isEmpty) {
      throw Exception('Usuário familiar não identificado.');
    }

    if (normalizedElderLinkCode.isEmpty) {
      throw Exception('Informe o código do idoso.');
    }

    final familyDoc = await _firestore.collection('users').doc(normalizedFamilyUid).get();
    if (!familyDoc.exists || familyDoc.data() == null) {
      throw Exception('Perfil do familiar não encontrado.');
    }

    final familyData = familyDoc.data()!;
    final familyInstitutionId = familyData['institutionId']?.toString();
    if (familyInstitutionId == null || familyInstitutionId.isEmpty) {
      throw Exception('O responsável não está vinculado a uma instituição válida.');
    }

    final elderQuery = await _firestore
        .collection('users')
        .where('type', isEqualTo: 'idoso')
        .where('elderLinkCode', isEqualTo: normalizedElderLinkCode)
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
    final elderUid = elderDoc.id;

    if (elderInstitutionId == null || elderInstitutionId.isEmpty) {
      throw Exception('O idoso não possui instituição válida.');
    }

    if (elderInstitutionId != familyInstitutionId) {
      throw Exception('O idoso e o familiar devem pertencer à mesma instituição.');
    }

    final existingLink = await _firestore
        .collection('familyLinks')
        .where('elderId', isEqualTo: elderUid)
        .where('familiarId', isEqualTo: normalizedFamilyUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existingLink.docs.isNotEmpty) {
      throw Exception('Você já está vinculado a este idoso.');
    }

    await _firestore.collection('familyLinks').add({
      'createdAt': FieldValue.serverTimestamp(),
      'elderId': elderUid,
      'familiarId': normalizedFamilyUid,
      'institutionId': elderInstitutionId,
      'status': 'active',
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    return userDoc.data();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception('Usuário não encontrado.');
    }

    return userDoc;
  }
}

class ElderAuthService {
  ElderAuthService._();

  static final ElderAuthService instance = ElderAuthService._();

  Future<DocumentSnapshot<Map<String, dynamic>>> loginWithInstitutionAndPassword({
    required String institutionId,
    required String password,
  }) async {
    return AuthService.instance.loginWithInstitutionAndPassword(
      institutionId: institutionId,
      password: password,
    );
  }
}
