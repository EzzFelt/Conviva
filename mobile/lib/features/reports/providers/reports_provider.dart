import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/account_type.dart';
import '../../auth/models/user_session.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/report_draft.dart';

class ReportTarget {
  const ReportTarget({required this.id, required this.name, this.photoUrl});

  final String id;
  final String name;
  final String? photoUrl;
}

final reportTargetsProvider = FutureProvider.autoDispose
    .family<List<ReportTarget>, OffenderKind>((ref, offenderKind) async {
      final session = await ref.watch(currentUserProvider.future);
      if (session == null) {
        throw StateError('Usuário não autenticado.');
      }

      final firestore = FirebaseFirestore.instance;
      switch (offenderKind) {
        case OffenderKind.caregiver:
          final snapshot = await firestore
              .collection('users')
              .where('institutionId', isEqualTo: session.institutionId)
              .where('type', isEqualTo: 'caregiver')
              .get();
          return snapshot.docs.map(_targetFromUser).toList();
        case OffenderKind.relative:
          return _loadLinkedFamilyTargets(firestore, session);
        case OffenderKind.institution:
          final document = await firestore
              .collection('institutions')
              .doc(session.institutionId)
              .get();
          if (!document.exists) return const [];
          final data = document.data() ?? <String, dynamic>{};
          return [
            ReportTarget(
              id: document.id,
              name: _firstString(data, const ['name', 'title']) ?? document.id,
              photoUrl: _firstString(data, const ['photoUrl', 'imageUrl']),
            ),
          ];
      }
    });

Future<List<ReportTarget>> _loadLinkedFamilyTargets(
  FirebaseFirestore firestore,
  UserSession session,
) async {
  final field = session.accountType == AccountType.elder
      ? 'elderId'
      : 'familiarId';
  final linkedField = session.accountType == AccountType.elder
      ? 'familiarId'
      : 'elderId';
  final links = await firestore
      .collection('familyLinks')
      .where(field, isEqualTo: session.uid)
      .get();

  final ids = links.docs
      .where(
        (document) =>
            document.data()['institutionId'] == session.institutionId &&
            document.data()['status'] == 'active',
      )
      .map((document) => document.data()[linkedField]?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();

  final targets = <ReportTarget>[];
  for (final id in ids) {
    final user = await firestore.collection('users').doc(id).get();
    if (user.exists) targets.add(_targetFromUser(user));
  }
  return targets;
}

ReportTarget _targetFromUser(DocumentSnapshot<Map<String, dynamic>> document) {
  final data = document.data() ?? <String, dynamic>{};
  return ReportTarget(
    id: document.id,
    name: data['name']?.toString().trim().isNotEmpty == true
        ? data['name'].toString().trim()
        : document.id,
    photoUrl: _firstString(data, const ['photoUrl', 'imageUrl']),
  );
}

String? _firstString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

Future<String> submitReport({
  required ReportDraft draft,
  required ReportTarget target,
  required UserSession session,
}) async {
  final reference = FirebaseFirestore.instance.collection('reports').doc();
  await reference.set({
    'reportId': reference.id,
    'institutionId': session.institutionId,
    'reporterId': session.uid,
    'reporterType': _accountTypeValue(session.accountType),
    'targetType': _reportKindValue(draft.kind),
    'description': draft.description.trim(),
    'isRecent': draft.isRecent,
    'isRecurrent': draft.happenedBefore,
    'offenderType': _offenderKindValue(draft.offender),
    'offenderId': target.id,
    'offenderName': target.name,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
  return reference.id;
}

String _accountTypeValue(AccountType type) => switch (type) {
  AccountType.elder => 'idoso',
  AccountType.family => 'family',
  AccountType.caregiver => 'caregiver',
};

String _reportKindValue(ReportKind? kind) => switch (kind) {
  ReportKind.personal => 'personal',
  ReportKind.thirdParty => 'third_party',
  null => throw StateError('Tipo da denúncia não informado.'),
};

String _offenderKindValue(OffenderKind? kind) => switch (kind) {
  OffenderKind.relative => 'parent',
  OffenderKind.caregiver => 'caregiver',
  OffenderKind.institution => 'institution',
  null => throw StateError('Tipo do acusado não informado.'),
};
