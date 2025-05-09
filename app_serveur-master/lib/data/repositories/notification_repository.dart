// lib/data/repositories/notification_repository.dart
import 'dart:async';
import '../models/notification.dart';

class NotificationRepository {
  // Méthode pour récupérer les notifications (simulation en attendant l'API)
  Future<List<UserNotification>> getNotifications() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Données simulées pour les notifications
    return [
      UserNotification(
        id: '1',
        content: 'Nouvelle commande à la Table 5',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      UserNotification(
        id: '2',
        content: 'La commande de la Table 3 est prête à être servie',
        createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      UserNotification(
        id: '3',
        content: 'Un client demande l\'addition à la Table 2',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      UserNotification(
        id: '4',
        content: 'La cuisine signale un retard pour la Table 7',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  // Méthode pour marquer une notification comme lue (simulation)
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return;
  }

  // Méthode pour marquer toutes les notifications comme lues (simulation)
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }
}