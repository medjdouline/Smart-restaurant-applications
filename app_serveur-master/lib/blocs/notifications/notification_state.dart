// lib/blocs/notifications/notification_state.dart
import '../../data/models/notification.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationState {
  final NotificationStatus status;
  final List<UserNotification> notifications;
  final String? errorMessage;

  NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<UserNotification>? notifications,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Récupérer le nombre de notifications non lues
  int get unreadCount => notifications.where((n) => !n.isRead).length;
}