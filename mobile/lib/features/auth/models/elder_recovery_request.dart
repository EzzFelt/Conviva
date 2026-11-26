import 'package:cloud_firestore/cloud_firestore.dart';

class ElderRecoveryRequest {
  const ElderRecoveryRequest({
    required this.id,
    required this.elderUid,
    required this.institutionId,
    required this.familyUid,
    required this.caregiverUid,
    required this.requesterUid,
    required this.status,
    required this.createdAt,
    this.approvedByUid,
    this.approvedByType,
    this.linkDeliveredToApprover = false,
    this.deliveryForwardedToElder = false,
    this.resetEmailRequested = false,
    this.resetEmailRequestedAt,
    this.resetEmailAttemptAt,
    this.elderName,
  });

  final String id;
  final String elderUid;
  final String institutionId;
  final String? familyUid;
  final String? caregiverUid;
  final String requesterUid;
  final String status;
  final DateTime createdAt;
  final String? approvedByUid;
  final String? approvedByType;
  final bool linkDeliveredToApprover;
  final bool deliveryForwardedToElder;
  final bool resetEmailRequested;
  final DateTime? resetEmailRequestedAt;
  final DateTime? resetEmailAttemptAt;
  final String? elderName;

  /// Intervalo mínimo que as regras do Firestore exigem entre dois pedidos de
  /// e-mail de redefinição feitos pelo suporte.
  static const resetEmailCooldown = Duration(minutes: 5);

  DateTime get expiresAt => createdAt.add(const Duration(hours: 24));

  /// Tempo que ainda falta para o suporte poder pedir outro e-mail.
  Duration get resetEmailCooldownRemaining {
    DateTime? last;
    for (final moment in [resetEmailAttemptAt, resetEmailRequestedAt]) {
      if (moment != null && (last == null || moment.isAfter(last))) {
        last = moment;
      }
    }
    if (last == null) return Duration.zero;

    final remaining = last.add(resetEmailCooldown).difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired =>
      status != 'completed' &&
      status != 'rejected' &&
      !DateTime.now().isBefore(expiresAt);

  factory ElderRecoveryRequest.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) {
      throw const FormatException('Data do pedido inválida.');
    }

    String requiredString(String key) {
      final value = data[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Campo $key inválido no pedido.');
      }
      return value;
    }

    final status = requiredString('status');
    if (!{'pending', 'approved', 'rejected', 'completed'}.contains(status)) {
      throw const FormatException('Status do pedido inválido.');
    }

    String? optionalResponsibleUid(String key) {
      final value = data[key];
      if (value == null) return null;
      if (value is! String || value.isEmpty) {
        throw FormatException('Campo $key inválido no pedido.');
      }
      return value;
    }

    final familyUid = optionalResponsibleUid('familyUid');
    final caregiverUid = optionalResponsibleUid('caregiverUid');
    if (familyUid == null && caregiverUid == null) {
      throw const FormatException('O pedido não possui responsável.');
    }
    final approvedByUid =
        data['approvedByUid']?.toString() ??
        (status == 'approved' ? data['respondedBy']?.toString() : null);
    final approvedByType =
        data['approvedByType']?.toString() ??
        (approvedByUid != null &&
                familyUid != null &&
                approvedByUid == familyUid
            ? 'family'
            : approvedByUid != null &&
                  caregiverUid != null &&
                  approvedByUid == caregiverUid
            ? 'caregiver'
            : null);
    if (approvedByType != null &&
        !{'family', 'caregiver'}.contains(approvedByType)) {
      throw const FormatException('Tipo de aprovador inválido.');
    }

    return ElderRecoveryRequest(
      id: id,
      elderUid: requiredString('elderUid'),
      institutionId: requiredString('institutionId'),
      familyUid: familyUid,
      caregiverUid: caregiverUid,
      requesterUid: requiredString('requesterUid'),
      status: status,
      createdAt: createdAt.toDate(),
      approvedByUid: approvedByUid,
      approvedByType: approvedByType,
      linkDeliveredToApprover: data['linkDeliveredToApprover'] == true,
      deliveryForwardedToElder: data['deliveryForwardedToElder'] == true,
      resetEmailRequested: data['resetEmailRequested'] == true,
      resetEmailRequestedAt: _optionalDate(data['resetEmailRequestedAt']),
      resetEmailAttemptAt: _optionalDate(data['resetEmailAttemptAt']),
      elderName: data['elderName']?.toString(),
    );
  }

  static DateTime? _optionalDate(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }

  ElderRecoveryRequest copyWith({String? elderName}) {
    return ElderRecoveryRequest(
      id: id,
      elderUid: elderUid,
      institutionId: institutionId,
      familyUid: familyUid,
      caregiverUid: caregiverUid,
      requesterUid: requesterUid,
      status: status,
      createdAt: createdAt,
      approvedByUid: approvedByUid,
      approvedByType: approvedByType,
      linkDeliveredToApprover: linkDeliveredToApprover,
      deliveryForwardedToElder: deliveryForwardedToElder,
      resetEmailRequested: resetEmailRequested,
      resetEmailRequestedAt: resetEmailRequestedAt,
      resetEmailAttemptAt: resetEmailAttemptAt,
      elderName: elderName ?? this.elderName,
    );
  }
}
