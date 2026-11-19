import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/current_user_provider.dart';
import '../../auth/models/account_type.dart';
import '../models/app_notification.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) async* {
  final session = await ref.watch(currentUserProvider.future);
  if (session == null) {
    yield const <AppNotification>[];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(session.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => List<AppNotification>.unmodifiable(
          snapshot.docs.map(AppNotification.fromFirestore),
        ),
      );
});

final recoveryApprovalNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);
      if (session == null) {
        yield const <AppNotification>[];
        return;
      }

      final recipientField = switch (session.accountType) {
        AccountType.family => 'familyUid',
        AccountType.caregiver => 'caregiverUid',
        _ => null,
      };
      if (recipientField == null) {
        yield const <AppNotification>[];
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('passwordRecoveryRequests')
          .where(recipientField, isEqualTo: session.uid)
          .where('status', whereIn: ['pending', 'rejected'])
          .snapshots()
          .map(
            (snapshot) => List<AppNotification>.unmodifiable(
              snapshot.docs
                  .where(
                    (document) =>
                        document.data()['status'] == 'rejected' ||
                        (document.data()['createdAt'] is Timestamp &&
                            DateTime.now().isBefore(
                              (document.data()['createdAt'] as Timestamp)
                                  .toDate()
                                  .add(const Duration(hours: 24)),
                            )),
                  )
                  .map(AppNotification.fromRecoveryRequest),
            ),
          );
    });

final recoveryDeliveryNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) async* {
      final session = await ref.watch(currentUserProvider.future);
      if (session == null ||
          !{
            AccountType.family,
            AccountType.caregiver,
          }.contains(session.accountType)) {
        yield const <AppNotification>[];
        return;
      }

      yield* FirebaseFirestore.instance
          .collection('passwordRecoveryRequests')
          .where('approvedByUid', isEqualTo: session.uid)
          .where('status', isEqualTo: 'approved')
          .where('deliveryForwardedToElder', isEqualTo: false)
          .snapshots()
          .map(
            (snapshot) => List<AppNotification>.unmodifiable(
              snapshot.docs.map(AppNotification.fromRecoveryDeliveryRequest),
            ),
          );
    });

Future<void> markNotificationAsRead({
  required String userId,
  required String notificationId,
}) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .doc(notificationId)
      .update({'read': true});
}

/// Marca várias notificações como lidas de uma vez (um único envio).
Future<void> markNotificationsAsRead({
  required String userId,
  required Iterable<String> notificationIds,
}) {
  final collection = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('notifications');

  final batch = FirebaseFirestore.instance.batch();
  for (final id in notificationIds) {
    batch.update(collection.doc(id), {'read': true});
  }

  return batch.commit();
}
