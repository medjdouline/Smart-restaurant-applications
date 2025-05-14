// lib/data/models/notification.dart
import 'package:intl/intl.dart';

class UserNotification {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? type;
  final String? relatedId;
  final Map<String, dynamic>? relatedEntity;
  final String? priority;
  final String? recipientType;

  UserNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.relatedId,
    this.relatedEntity,
    this.priority,
    this.recipientType,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    // Gestion des différents noms de champs possibles
    String notificationTitle = json['title'] ?? 'Notification';
    String notificationContent = json['message'] ?? json['content'] ?? '';
    
    // Gestion des différents formats de date
    DateTime parsedDate;
    try {
      if (json['created_at'] is String) {
        parsedDate = DateTime.parse(json['created_at']);
      } else if (json['created_at'] != null && json['created_at'].runtimeType.toString().contains('Timestamp')) {
        // Gestion du Timestamp Firebase
        parsedDate = DateTime.fromMillisecondsSinceEpoch(
          json['created_at'].seconds * 1000 + 
          (json['created_at'].nanoseconds ~/ 1000000)
        );
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }
    
    return UserNotification(
      id: json['id'] ?? '',
      title: notificationTitle,
      content: notificationContent,
      createdAt: parsedDate,
      isRead: json['read'] ?? json['isRead'] ?? false,
      type: json['type'],
      relatedId: json['related_id'],
      relatedEntity: json['related_entity'],
      priority: json['priority'],
      recipientType: json['recipient_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'read': isRead,
      'type': type,
      'related_id': relatedId,
      'related_entity': relatedEntity,
      'priority': priority,
      'recipient_type': recipientType,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}