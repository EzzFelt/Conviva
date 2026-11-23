import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conviva/features/auth/models/elder_recovery_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a recovery request with only one configured responsible', () {
    final request = ElderRecoveryRequest.fromMap(
      id: 'request-1',
      data: {
        'elderUid': 'elder-1',
        'institutionId': 'institution-1',
        'familyUid': null,
        'caregiverUid': 'caregiver-1',
        'requesterUid': 'anonymous-1',
        'status': 'approved',
        'approvedByUid': 'caregiver-1',
        'createdAt': Timestamp.now(),
      },
    );

    expect(request.familyUid, isNull);
    expect(request.caregiverUid, 'caregiver-1');
    expect(request.approvedByType, 'caregiver');
  });

  test('rejects recovery requests without a configured responsible', () {
    expect(
      () => ElderRecoveryRequest.fromMap(
        id: 'request-1',
        data: {
          'elderUid': 'elder-1',
          'institutionId': 'institution-1',
          'familyUid': null,
          'caregiverUid': null,
          'requesterUid': 'anonymous-1',
          'status': 'pending',
          'createdAt': Timestamp.now(),
        },
      ),
      throwsFormatException,
    );
  });

  test('derives the 24-hour expiry from the Firestore creation timestamp', () {
    final request = ElderRecoveryRequest.fromMap(
      id: 'request-1',
      data: {
        'elderUid': 'elder-1',
        'institutionId': 'institution-1',
        'familyUid': 'family-1',
        'caregiverUid': 'caregiver-1',
        'requesterUid': 'anonymous-1',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 25)),
        ),
      },
    );

    expect(request.isExpired, isTrue);
    expect(request.expiresAt, request.createdAt.add(const Duration(hours: 24)));
  });

  test('rejects request documents with unknown status values', () {
    expect(
      () => ElderRecoveryRequest.fromMap(
        id: 'request-1',
        data: {
          'elderUid': 'elder-1',
          'institutionId': 'institution-1',
          'familyUid': 'family-1',
          'caregiverUid': 'caregiver-1',
          'requesterUid': 'anonymous-1',
          'status': 'invalid',
          'createdAt': Timestamp.now(),
        },
      ),
      throwsFormatException,
    );
  });

  test('approved requests expire after the 24-hour window', () {
    final request = ElderRecoveryRequest.fromMap(
      id: 'request-1',
      data: {
        'elderUid': 'elder-1',
        'institutionId': 'institution-1',
        'familyUid': 'family-1',
        'caregiverUid': 'caregiver-1',
        'requesterUid': 'anonymous-1',
        'status': 'approved',
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
      },
    );

    expect(request.isExpired, isTrue);
  });

  test('accepts completed requests so the elder can see the final status', () {
    final request = ElderRecoveryRequest.fromMap(
      id: 'request-1',
      data: {
        'elderUid': 'elder-1',
        'institutionId': 'institution-1',
        'familyUid': 'family-1',
        'caregiverUid': 'caregiver-1',
        'requesterUid': 'anonymous-1',
        'status': 'completed',
        'createdAt': Timestamp.now(),
      },
    );

    expect(request.status, 'completed');
  });

  test('reads the approving responsible and forwarding state', () {
    final request = ElderRecoveryRequest.fromMap(
      id: 'request-1',
      data: {
        'elderUid': 'elder-1',
        'institutionId': 'institution-1',
        'familyUid': 'family-1',
        'caregiverUid': 'caregiver-1',
        'requesterUid': 'anonymous-1',
        'status': 'approved',
        'approvedByUid': 'family-1',
        'approvedByType': 'family',
        'linkDeliveredToApprover': true,
        'deliveryForwardedToElder': true,
        'resetEmailRequested': false,
        'createdAt': Timestamp.now(),
      },
    );

    expect(request.approvedByUid, 'family-1');
    expect(request.approvedByType, 'family');
    expect(request.linkDeliveredToApprover, isTrue);
    expect(request.deliveryForwardedToElder, isTrue);
    expect(request.resetEmailRequested, isFalse);
  });

  test('reads pending replacement email state', () {
    final request = ElderRecoveryRequest.fromMap(
      id: 'request-1',
      data: {
        'elderUid': 'elder-1',
        'institutionId': 'institution-1',
        'familyUid': 'family-1',
        'caregiverUid': 'caregiver-1',
        'requesterUid': 'anonymous-1',
        'status': 'approved',
        'resetEmailRequested': true,
        'createdAt': Timestamp.now(),
      },
    );

    expect(request.resetEmailRequested, isTrue);
  });

  test(
    'recovers approver identity from requests approved before this stage',
    () {
      final request = ElderRecoveryRequest.fromMap(
        id: 'request-1',
        data: {
          'elderUid': 'elder-1',
          'institutionId': 'institution-1',
          'familyUid': 'family-1',
          'caregiverUid': 'caregiver-1',
          'requesterUid': 'anonymous-1',
          'status': 'approved',
          'respondedBy': 'family-1',
          'createdAt': Timestamp.now(),
        },
      );

      expect(request.approvedByUid, 'family-1');
      expect(request.approvedByType, 'family');
      expect(request.linkDeliveredToApprover, isFalse);
      expect(request.deliveryForwardedToElder, isFalse);
      expect(request.resetEmailRequested, isFalse);
    },
  );
}
