import 'package:good_taste/data/api/notification_api_service.dart';
import 'package:good_taste/data/models/notification_model.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:flutter/foundation.dart';
import 'package:good_taste/di/di.dart';

class NotificationRepository {
  // Singleton pattern
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  
  final NotificationApiService _notificationApiService;

  NotificationRepository._internal() 
      : _notificationApiService = DependencyInjection.getNotificationApiService();

  Future<List<Notification>> getNotifications() async {
    try {
      final response = await _notificationApiService.getNotifications();
      
      if (response.success) {
        return (response.data as List).map((json) => Notification.fromJson(json)).toList();
      } else {
        debugPrint('Error fetching notifications: ${response.error}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception in getNotifications: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _notificationApiService.markAsRead(notificationId);
      return response.success;
    } catch (e) {
      debugPrint('Exception in markAsRead: $e');
      return false;
    }
  }

  // Add these if you still need them
  Notification createLateReservationNotification(Reservation reservation) {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: 'Votre réservation du ${_formatDate(reservation.date)} à ${reservation.timeSlot} est en retard',
      date: DateTime.now(),
      type: NotificationType.late,
    );
    return notification;
  }

  Notification createCanceledReservationNotification(Reservation reservation) {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: 'Votre réservation du ${_formatDate(reservation.date)} a été annulée',
      date: DateTime.now(),
      type: NotificationType.canceled,
    );
    return notification;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}