// lib/data/models/notification_model.dart
import 'package:equatable/equatable.dart';

enum NotificationType {
  reservation,
  fidelity,
  late,      
  canceled    
}

class Notification extends Equatable {
  final String id;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;
  final String? reservationId;  

  const Notification({
    required this.id,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.reservationId, 
  });

  @override
  List<Object?> get props => [id, message, date, type, isRead, reservationId];

  Notification copyWith({
    String? id,
    String? message,
    DateTime? date,
    NotificationType? type,
    bool? isRead,
    String? reservationId,
  }) {
    return Notification(
      id: id ?? this.id,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      reservationId: reservationId ?? this.reservationId,
    );
  }
}