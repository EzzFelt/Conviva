import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/recovery_config.dart';
import '../../features/auth/models/elder_recovery_request.dart';
import 'auth_service.dart';

class RecoveryRequestRejectedException implements Exception {
  const RecoveryRequestRejectedException();

  @override
  String toString() {
    return 'Não foi possível registrar o pedido. Confira o código e tente '
        'novamente mais tarde.';
  }
}

class RecoveryContactsNotConfiguredException implements Exception {
  const RecoveryContactsNotConfiguredException();

  @override
  String toString() {
    return 'Este idoso ainda não configurou um familiar e um cuidador '
        'responsáveis. Entre na conta do idoso e salve os responsáveis antes '
        'de solicitar a recuperação.';
  }
}

class ElderRecoveryRequestService {
  ElderRecoveryRequestService._();

  static final instance = ElderRecoveryRequestService._();

  static const _lookupCollection = 'elderRecoveryLookups';
  static const _proofCollection = 'passwordRecoveryProofs';
  static const _requestCollection = 'passwordRecoveryRequests';
  static const _rateLimitCollection = 'passwordRecoveryRateLimits';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// O texto digitado tem o formato de um código ELD (ELD + letras/números)?
  static bool isValidElderCode(String value) {
    return RegExp(
      r'^ELD[A-Z0-9]{4,}$',
    ).hasMatch(AuthRegister.normalizeElderCode(value));
  }

  /// O texto é um link de redefinição de senha emitido pelo Firebase deste
  /// projeto? Usado pela tela de suporte antes de liberar o botão.
  bool isValidResetLink(String value) => _isFirebasePasswordResetLink(value);

  Future<String> request(String elderCode) async {
    final normalizedCode = AuthRegister.normalizeElderCode(elderCode);
    final lookupId = RecoveryConfig.elderRecoveryLookupId(normalizedCode);
    final requester = await _ensureAnonymousUser();
    final lookupReference = _firestore
        .collection(_lookupCollection)
        .doc(lookupId);

    late final Map<String, dynamic> lookup;
    try {
      final lookupSnapshot = await lookupReference.get();
      final data = lookupSnapshot.data();
      if (!lookupSnapshot.exists || data == null) {
        throw const RecoveryRequestRejectedException();
      }
      lookup = data;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const RecoveryRequestRejectedException();
      }
      rethrow;
    }

    final elderUid = lookup['elderUid'];
    final institutionId = lookup['institutionId'];
    final familyUid = lookup['familyUid'];
    final caregiverUid = lookup['caregiverUid'];
    if (familyUid is! String || caregiverUid is! String) {
      throw const RecoveryContactsNotConfiguredException();
    }
    if (elderUid is! String || institutionId is! String) {
      throw const RecoveryRequestRejectedException();
    }

    final requestReference = _firestore.collection(_requestCollection).doc();
    final proofReference = _firestore
        .collection(_proofCollection)
        .doc(requestReference.id);
    final rateLimitReference = _firestore
        .collection(_rateLimitCollection)
        .doc(lookupId);
    final requestId = requestReference.id;

    final batch = _firestore.batch()
      ..set(proofReference, {
        'requestId': requestId,
        'lookupHash': lookupId,
        'requesterUid': requester.uid,
        'elderUid': elderUid,
        'institutionId': institutionId,
        'familyUid': familyUid,
        'caregiverUid': caregiverUid,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(requestReference, {
        'requestId': requestId,
        'lookupHash': lookupId,
        'requesterUid': requester.uid,
        'elderUid': elderUid,
        'institutionId': institutionId,
        'familyUid': familyUid,
        'caregiverUid': caregiverUid,
        'status': 'pending',
        'familyDecision': 'pending',
        'caregiverDecision': 'pending',
        'linkDeliveredToApprover': false,
        'deliveryForwardedToElder': false,
        'resetEmailRequested': false,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(rateLimitReference, {
        'elderUid': elderUid,
        'requestId': requestId,
        'lastRequestedAt': FieldValue.serverTimestamp(),
      });

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const RecoveryRequestRejectedException();
      }
      rethrow;
    }

    try {
      await proofReference.delete();
    } on FirebaseException catch (error) {
      debugPrint('Falha ao remover a prova temporária do pedido: $error');
    }

    return requestId;
  }

  Future<ElderRecoveryRequest?> findLatestRequestForCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return null;

    final snapshot = await _firestore
        .collection(_requestCollection)
        .where('requesterUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final document = snapshot.docs.first;
    return ElderRecoveryRequest.fromMap(id: document.id, data: document.data());
  }

  Stream<ElderRecoveryRequest> watchRequestStatus(String requestId) {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw StateError('A sessão de recuperação não está ativa.');
    }

    return _firestore
        .collection(_requestCollection)
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            throw StateError('A solicitação não está mais disponível.');
          }
          return ElderRecoveryRequest.fromMap(id: snapshot.id, data: data);
        });
  }

  Stream<ElderRecoveryRequest> watchApprovalRequest(String requestId) {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Entre na sua conta para analisar o pedido.');
    }

    return _firestore
        .collection(_requestCollection)
        .doc(requestId)
        .snapshots()
        .asyncMap((snapshot) async {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            throw StateError('A solicitação não está mais disponível.');
          }

          final request = ElderRecoveryRequest.fromMap(
            id: snapshot.id,
            data: data,
          );
          final elderSnapshot = await _firestore
              .collection('users')
              .doc(request.elderUid)
              .get();
          final elderName = elderSnapshot.data()?['name']?.toString().trim();

          return request.copyWith(
            elderName: elderName == null || elderName.isEmpty
                ? 'O idoso'
                : elderName,
          );
        });
  }

  Future<void> respond({
    required String requestId,
    required bool approve,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Entre na sua conta para analisar o pedido.');
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final accountType = profile.data()?['type'];
    final decisionField = switch (accountType) {
      'family' => 'familyDecision',
      'caregiver' => 'caregiverDecision',
      _ => throw StateError('Sua conta não pode analisar este pedido.'),
    };
    try {
      final requestReference = _firestore
          .collection(_requestCollection)
          .doc(requestId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestReference);
        final data = snapshot.data();
        if (data == null || data['status'] != 'pending') {
          throw StateError(
            'O pedido já foi respondido ou não está disponível.',
          );
        }

        final familyDecision = data['familyDecision']?.toString() ?? 'pending';
        final caregiverDecision =
            data['caregiverDecision']?.toString() ?? 'pending';
        final ownDecision = accountType == 'family'
            ? familyDecision
            : caregiverDecision;
        if (ownDecision != 'pending') {
          throw StateError('Sua decisão para este pedido já foi registrada.');
        }

        final decision = approve ? 'approved' : 'rejected';
        final otherDecision = accountType == 'family'
            ? caregiverDecision
            : familyDecision;
        final updates = <String, dynamic>{
          decisionField: decision,
          '${accountType}RespondedAt': FieldValue.serverTimestamp(),
          'status': approve
              ? 'approved'
              : otherDecision == 'rejected'
              ? 'rejected'
              : 'pending',
        };
        if (approve) {
          updates['approvedByUid'] = user.uid;
          updates['approvedByType'] = accountType;
        }
        transaction.update(requestReference, updates);
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'not-found' ||
          error.code == 'failed-precondition') {
        throw StateError(
          'O pedido expirou, já foi respondido ou não pertence à sua conta.',
        );
      }
      rethrow;
    }
  }

  Future<void> deliverResetLink({
    required String requestId,
    required String resetLink,
  }) async {
    final user = _requireSignedInUser();
    final profile = await _firestore.collection('users').doc(user.uid).get();
    if (profile.data()?['type'] != 'support') {
      throw StateError('Sua conta não pode disponibilizar este link.');
    }

    final requestReference = _firestore
        .collection(_requestCollection)
        .doc(requestId);
    final requestSnapshot = await requestReference.get();
    final requestData = requestSnapshot.data();
    if (requestData == null) {
      throw StateError('O pedido não está mais disponível.');
    }
    final recoveryRequest = ElderRecoveryRequest.fromMap(
      id: requestId,
      data: requestData,
    );
    if (recoveryRequest.status != 'approved' ||
        recoveryRequest.isExpired ||
        recoveryRequest.approvedByUid == null ||
        recoveryRequest.linkDeliveredToApprover) {
      throw StateError(
        'O pedido expirou, não foi aprovado ou já recebeu um link.',
      );
    }
    if (!_isFirebasePasswordResetLink(resetLink)) {
      throw StateError('Informe um link válido de redefinição do Firebase.');
    }

    final deliveryReference = _firestore
        .collection('passwordRecoveryDeliveries')
        .doc(requestId);
    final batch = _firestore.batch()
      ..set(deliveryReference, {
        'requestId': requestId,
        'recipientUid': recoveryRequest.approvedByUid,
        'requesterUid': recoveryRequest.requesterUid,
        'elderUid': recoveryRequest.elderUid,
        'resetLink': resetLink.trim(),
        'forwardedToElder': false,
        'createdAt': FieldValue.serverTimestamp(),
        'deliveryExpiresAt': Timestamp.fromDate(
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        'forwardedAt': null,
      })
      ..update(requestReference, {
        'linkDeliveredToApprover': true,
        'linkDeliveredAt': FieldValue.serverTimestamp(),
        'resetEmailRequested': false,
        'resetEmailRequestedAt': FieldValue.delete(),
        'resetEmailRequestedBy': FieldValue.delete(),
      });

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'already-exists' ||
          error.code == 'not-found' ||
          error.code == 'failed-precondition') {
        throw StateError(
          'Não foi possível disponibilizar o link pelas regras atuais. '
          'Confira se o pedido continua aprovado, dentro de 24 horas e '
          'com a solicitação do e-mail registrada.',
        );
      }
      rethrow;
    }
  }

  Future<void> forwardResetLinkToElder(String requestId) async {
    final user = _requireSignedInUser();
    final requestReference = _firestore
        .collection(_requestCollection)
        .doc(requestId);
    final requestSnapshot = await requestReference.get();
    final data = requestSnapshot.data();
    if (data == null) {
      throw StateError('O pedido não está mais disponível.');
    }

    final recoveryRequest = ElderRecoveryRequest.fromMap(
      id: requestId,
      data: data,
    );
    if (recoveryRequest.status != 'approved' ||
        recoveryRequest.isExpired ||
        recoveryRequest.approvedByUid != user.uid ||
        !recoveryRequest.linkDeliveredToApprover ||
        recoveryRequest.deliveryForwardedToElder) {
      throw StateError(
        'Este link não está disponível para sua conta ou o pedido expirou.',
      );
    }

    final deliveryReference = _firestore
        .collection('passwordRecoveryDeliveries')
        .doc(requestId);
    final batch = _firestore.batch()
      ..update(deliveryReference, {
        'forwardedToElder': true,
        'forwardedAt': FieldValue.serverTimestamp(),
      })
      ..update(requestReference, {
        'deliveryForwardedToElder': true,
        'deliveryForwardedAt': FieldValue.serverTimestamp(),
      });

    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'not-found' ||
          error.code == 'failed-precondition') {
        throw StateError(
          'Não foi possível encaminhar o link. Ele pode ter expirado ou '
          'já ter sido encaminhado.',
        );
      }
      rethrow;
    }
  }

  Future<String> getResetLinkForCurrentSession(String requestId) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw StateError('A sessão temporária de recuperação não está ativa.');
    }

    final snapshot = await _firestore
        .collection('passwordRecoveryDeliveries')
        .doc(requestId)
        .get();
    final resetLink = snapshot.data()?['resetLink'];
    if (resetLink is! String || !_isFirebasePasswordResetLink(resetLink)) {
      throw StateError('O link de recuperação não está disponível.');
    }
    return resetLink;
  }

  Future<void> requestResetEmail({
    required String requestId,
    required String elderCode,
  }) async {
    final user = _requireSignedInUser();
    final profile = await _firestore.collection('users').doc(user.uid).get();
    if (profile.data()?['type'] != 'support') {
      throw StateError('Sua conta não pode solicitar outro link.');
    }

    final normalizedCode = AuthRegister.normalizeElderCode(elderCode);
    if (!RegExp(r'^ELD[A-Z0-9]{4,}$').hasMatch(normalizedCode)) {
      throw StateError('Informe um código ELD válido.');
    }
    final lookupHash = RecoveryConfig.elderRecoveryLookupId(normalizedCode);
    final requestReference = _firestore
        .collection(_requestCollection)
        .doc(requestId);
    final deliveryReference = _firestore
        .collection('passwordRecoveryDeliveries')
        .doc(requestId);

    final requestSnapshot = await requestReference.get();
    final initialData = requestSnapshot.data();
    if (initialData == null) {
      throw StateError('O pedido não está mais disponível.');
    }

    final request = ElderRecoveryRequest.fromMap(
      id: requestId,
      data: initialData,
    );
    if (request.status != 'approved' ||
        initialData['lookupHash'] != lookupHash) {
      throw StateError(
        'O código não corresponde ao pedido ou o pedido não está aprovado.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestReference);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('O pedido não está mais disponível.');
      }
      final currentRequest = ElderRecoveryRequest.fromMap(
        id: requestId,
        data: data,
      );
      if (currentRequest.status != 'approved' ||
          data['lookupHash'] != lookupHash) {
        throw StateError(
          'O código não corresponde ao pedido ou o pedido não está aprovado.',
        );
      }

      transaction.update(requestReference, {
        'resetEmailAttemptAt': FieldValue.serverTimestamp(),
        'resetEmailAttemptBy': user.uid,
      });
    });

    await _auth.sendPasswordResetEmail(
      email: AuthRegister.elderAuthEmail(normalizedCode),
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestReference);
      final data = snapshot.data();
      if (data == null ||
          data['status'] != 'approved' ||
          data['resetEmailAttemptBy'] != user.uid ||
          data['resetEmailAttemptAt'] == null) {
        throw StateError(
          'O Firebase aceitou o envio, mas não foi possível registrar '
          'a solicitação. Contate o suporte antes de repetir.',
        );
      }

      transaction.update(requestReference, {
        'linkDeliveredToApprover': false,
        'deliveryForwardedToElder': false,
        'resetEmailRequested': true,
        'resetEmailRequestedAt': FieldValue.serverTimestamp(),
        'resetEmailRequestedBy': user.uid,
        'linkDeliveredAt': FieldValue.delete(),
        'deliveryForwardedAt': FieldValue.delete(),
      });
      if (data['linkDeliveredToApprover'] == true) {
        transaction.delete(deliveryReference);
      }
    });
  }

  Future<int> completeForwardedRequestsAfterElderLogin() async {
    final user = _requireSignedInUser();
    final profile = await _firestore.collection('users').doc(user.uid).get();
    if (profile.data()?['type'] != 'idoso') {
      throw StateError('Somente o idoso autenticado pode concluir o pedido.');
    }

    var completedCount = 0;
    while (true) {
      final requests = await _firestore
          .collection(_requestCollection)
          .where('elderUid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .where('deliveryForwardedToElder', isEqualTo: true)
          .limit(200)
          .get();
      if (requests.docs.isEmpty) return completedCount;

      final batch = _firestore.batch();
      for (final request in requests.docs) {
        batch
          ..update(request.reference, {
            'status': 'completed',
            'completedBy': user.uid,
            'completedAt': FieldValue.serverTimestamp(),
            'resetEmailRequested': false,
            'resetEmailRequestedAt': FieldValue.delete(),
            'resetEmailRequestedBy': FieldValue.delete(),
            'resetEmailAttemptAt': FieldValue.delete(),
            'resetEmailAttemptBy': FieldValue.delete(),
            'linkDeliveredAt': FieldValue.delete(),
            'deliveryForwardedAt': FieldValue.delete(),
          })
          ..delete(
            _firestore.collection('passwordRecoveryDeliveries').doc(request.id),
          );
      }

      try {
        await batch.commit();
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied' ||
            error.code == 'not-found' ||
            error.code == 'failed-precondition') {
          throw StateError(
            'A entrada ocorreu, mas não foi possível encerrar o pedido. '
            'Tente novamente ou contate o suporte.',
          );
        }
        rethrow;
      }

      completedCount += requests.docs.length;
    }
  }

  Future<User> _ensureAnonymousUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      if (!currentUser.isAnonymous) {
        throw StateError('Encerre a sessão antes de solicitar a recuperação.');
      }
      return currentUser;
    }

    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Não foi possível iniciar a sessão de recuperação.');
    }
    return user;
  }

  User _requireSignedInUser() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Entre na sua conta para acessar esta função.');
    }
    return user;
  }

  bool _isFirebasePasswordResetLink(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;

    final options = _auth.app.options;
    final authDomain =
        options.authDomain ?? '${options.projectId}.firebaseapp.com';
    return uri.scheme == 'https' &&
        uri.host == authDomain &&
        uri.path == '/__/auth/action' &&
        uri.queryParameters['mode'] == 'resetPassword' &&
        (uri.queryParameters['oobCode']?.isNotEmpty ?? false);
  }
}
