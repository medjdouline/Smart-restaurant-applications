// notification_model.dart
import 'package:equatable/equatable.dart';

enum NotificationType {
  reservation,
  fidelity,
  late,      
  canceled,
  general // Added general type for API notifications
}

class Notification extends Equatable {
  final String id;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;

  const Notification({
    required this.id,
    required this.message,
    required this.date,
    this.type = NotificationType.general,
    this.isRead = false,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      date: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      type: _parseNotificationType(json['type'] ?? 'general'),
      isRead: json['read'] ?? false,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'reservation':
        return NotificationType.reservation;
      case 'fidelity':
        return NotificationType.fidelity;
      case 'late':
        return NotificationType.late;
      case 'canceled':
        return NotificationType.canceled;
      default:
        return NotificationType.general;
    }
  }

  @override
  List<Object?> get props => [id, message, date, type, isRead];

  Notification copyWith({
    String? id,
    String? message,
    DateTime? date,
    NotificationType? type,
    bool? isRead,
  }) {
    return Notification(
      id: id ?? this.id,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}