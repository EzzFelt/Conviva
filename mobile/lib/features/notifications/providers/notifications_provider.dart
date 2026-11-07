import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/current_user_provider.dart';
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
