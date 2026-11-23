import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/recovery_config.dart';
import '../../../core/services/auth_service.dart';

class RecoveryContact {
  const RecoveryContact({required this.uid, required this.name});

  final String uid;
  final String name;
}

class RecoveryContactsConfiguration {
  const RecoveryContactsConfiguration({
    required this.families,
    required this.caregivers,
    required this.familyUid,
    required this.caregiverUid,
  });

  final List<RecoveryContact> families;
  final List<RecoveryContact> caregivers;
  final String? familyUid;
  final String? caregiverUid;
}

class RecoveryContactsRepository {
  RecoveryContactsRepository._();

  static final instance = RecoveryContactsRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RecoveryContactsConfiguration> load() async {
    final elderUid = _auth.currentUser?.uid;
    if (elderUid == null) {
      throw StateError('Entre na conta do idoso para escolher responsáveis.');
    }

    final elderReference = _firestore.collection('users').doc(elderUid);
    final elderSnapshot = await elderReference.get();
    final elder = elderSnapshot.data();
    if (elder == null || elder['type'] != 'idoso') {
      throw StateError('A conta atual não é de um idoso.');
    }

    final institutionId = elder['institutionId']?.toString();
    if (institutionId == null || institutionId.isEmpty) {
      throw StateError('A conta do idoso não possui instituição válida.');
    }

    final familyLinks = await _firestore
        .collection('familyLinks')
        .where('elderId', isEqualTo: elderUid)
        .get();
    final familyUids = familyLinks.docs
        .where(
          (document) =>
              document.data()['status'] == 'active' &&
              document.data()['institutionId'] == institutionId,
        )
        .map((document) => document.data()['familiarId']?.toString() ?? '')
        .where((uid) => uid.isNotEmpty)
        .toSet();

    final familyDocuments = await Future.wait(
      familyUids.map((uid) => _firestore.collection('users').doc(uid).get()),
    );
    final families = <RecoveryContact>[
      for (final document in familyDocuments)
        if (document.data()?['type'] == 'family' &&
            document.data()?['status'] == 'active' &&
            document.data()?['institutionId'] == institutionId)
          RecoveryContact(
            uid: document.id,
            name: document.data()?['name']?.toString() ?? 'Familiar',
          ),
    ]..sort((first, second) => first.name.compareTo(second.name));

    final institutionUsers = await _firestore
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .get();
    final caregivers = <RecoveryContact>[
      for (final document in institutionUsers.docs)
        if (document.data()['type'] == 'caregiver' &&
            document.data()['status'] == 'active')
          RecoveryContact(
            uid: document.id,
            name: document.data()['name']?.toString() ?? 'Cuidador',
          ),
    ]..sort((first, second) => first.name.compareTo(second.name));

    final familyUid = elder['recoveryFamilyUid']?.toString();
    final caregiverUid = elder['recoveryCaregiverUid']?.toString();
    final configuration = RecoveryContactsConfiguration(
      families: List.unmodifiable(families),
      caregivers: List.unmodifiable(caregivers),
      familyUid: familyUid,
      caregiverUid: caregiverUid,
    );

    final elderLinkCode = elder['elderLinkCode']?.toString();
    if ((familyUid != null || caregiverUid != null) &&
        (familyUid == null ||
            families.any((contact) => contact.uid == familyUid)) &&
        (caregiverUid == null ||
            caregivers.any((contact) => contact.uid == caregiverUid)) &&
        elderLinkCode != null) {
      await _syncLookup(
        elderUid: elderUid,
        institutionId: institutionId,
        elderLinkCode: elderLinkCode,
        familyUid: familyUid,
        caregiverUid: caregiverUid,
      );
    }

    return configuration;
  }

  Future<void> save({
    String? familyUid,
    String? caregiverUid,
  }) async {
    final elderUid = _auth.currentUser?.uid;
    if (elderUid == null) {
      throw StateError('Entre na conta do idoso para escolher responsáveis.');
    }
    if (familyUid == null && caregiverUid == null) {
      throw StateError('Selecione ao menos um responsável.');
    }

    final configuration = await load();
    if (familyUid != null &&
        !configuration.families.any((contact) => contact.uid == familyUid)) {
      throw StateError('Selecione um familiar com vínculo ativo.');
    }
    if (caregiverUid != null &&
        !configuration.caregivers.any(
          (contact) => contact.uid == caregiverUid,
        )) {
      throw StateError('Selecione um cuidador ativo da instituição do idoso.');
    }

    final elderSnapshot = await _firestore
        .collection('users')
        .doc(elderUid)
        .get();
    final elder = elderSnapshot.data();
    final institutionId = elder?['institutionId']?.toString();
    final elderLinkCode = elder?['elderLinkCode']?.toString();
    if (institutionId == null ||
        institutionId.isEmpty ||
        elderLinkCode == null) {
      throw StateError('Não foi possível validar o perfil do idoso.');
    }

    final userReference = _firestore.collection('users').doc(elderUid);
    final lookupId = RecoveryConfig.elderRecoveryLookupId(
      AuthRegister.normalizeElderCode(elderLinkCode),
    );
    final batch = _firestore.batch()
      ..update(userReference, {
        'recoveryFamilyUid': familyUid,
        'recoveryCaregiverUid': caregiverUid,
      })
      ..set(
        _firestore.collection('elderRecoveryLookups').doc(lookupId),
        {
          'elderUid': elderUid,
          'institutionId': institutionId,
          'familyUid': familyUid,
          'caregiverUid': caregiverUid,
        },
      );
    await batch.commit();
  }

  Future<void> _syncLookup({
    required String elderUid,
    required String institutionId,
    required String elderLinkCode,
    required String? familyUid,
    required String? caregiverUid,
  }) async {
    final lookupId = RecoveryConfig.elderRecoveryLookupId(
      AuthRegister.normalizeElderCode(elderLinkCode),
    );
    await _firestore
        .collection('elderRecoveryLookups')
        .doc(lookupId)
        .set({
          'elderUid': elderUid,
          'institutionId': institutionId,
          'familyUid': familyUid,
          'caregiverUid': caregiverUid,
        });
  }
}
