// lib/data/repositories/notification_repository.dart
import 'package:good_taste/data/models/notification_model.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  
  List<Notification> getNotifications() {
    
    return [
      Notification(
        id: '1',
        message: 'Votre réservation pour le 15 avril a été confirmée',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.reservation,
      ),
      Notification(
        id: '2',
        message:
            'Félicitations ! Vous avez gagné 50 points de fidélité avec votre dernière commande',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.fidelity,
      ),
      Notification(
        id: '3',
        message: 'Nouvelle promotion : -20% sur les plats du jour ce weekend',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.fidelity,
      ),
      Notification(
        id: '4',
        message: 'Votre réservation pour le 10 avril a été modifiée',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: NotificationType.reservation,
      ),
      Notification(
        id: '5',
        message:
            'Profitez de notre offre spéciale : un dessert offert pour chaque plat principal commandé',
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: NotificationType.fidelity,
      ),
      Notification(
        id: '6',
        message: 'Rappel : Votre réservation est prévue pour demain à 19h30',
        date: DateTime.now().subtract(const Duration(days: 4)),
        type: NotificationType.reservation,
      ),
    ];
  }

  void markAsRead(String id) {
    
    debugPrint('Marking notification $id as read');
  }
}
