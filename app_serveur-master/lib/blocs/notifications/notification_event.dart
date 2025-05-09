// lib/blocs/notifications/notification_event.dart
abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;
  
  MarkNotificationAsRead({required this.notificationId});
}

class MarkAllNotificationsAsRead extends NotificationEvent {}