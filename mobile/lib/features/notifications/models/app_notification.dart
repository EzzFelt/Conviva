import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AppNotificationType { message, task }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.chatId,
    this.elderId,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? chatId;
  final String? elderId;

  factory AppNotification.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];

    return AppNotification(
      id: document.id,
      type: data['type'] == AppNotificationType.task.name
          ? AppNotificationType.task
          : AppNotificationType.message,
      title: data['title']?.toString() ?? 'Notificação',
      body: data['body']?.toString() ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      isRead: data['read'] == true,
      chatId: data['chatId']?.toString(),
      elderId: data['elderId']?.toString(),
    );
  }
}
