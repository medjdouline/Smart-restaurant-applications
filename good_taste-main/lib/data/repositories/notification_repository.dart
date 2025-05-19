// lib/data/repositories/notification_repository.dart
import 'package:good_taste/data/models/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'dart:math';

class NotificationRepository {
  // Singleton pattern pour garantir une seule instance
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal();
  
  // Liste des notifications en mémoire (simulée)
  final List<Notification> _notifications = [];
  
  // Générer un ID unique
  String _generateUniqueId() {
    final random = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           random.nextInt(9999).toString();
  }
  
  List<Notification> getNotifications() {
    // Si aucune notification n'est encore créée, initialiser avec des exemples
    if (_notifications.isEmpty) {
      _notifications.addAll([
        Notification(
          id: '1',
          message: 'Votre réservation pour le 15 avril a été confirmée',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          type: NotificationType.reservation,
        ),
        Notification(
          id: '2',
          message: 'Félicitations ! Vous avez gagné 50 points de fidélité avec votre dernière commande',
          date: DateTime.now().subtract(const Duration(hours: 5)),
          type: NotificationType.fidelity,
        ),
        Notification(
          id: '3',
          message: 'Nouvelle promotion : -20% sur les plats du jour ce weekend',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: NotificationType.fidelity,
        ),
      ]);
    }
    
    // Retourner la liste triée par date (plus récent en premier)
    return [..._notifications]..sort((a, b) => b.date.compareTo(a.date));
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index >= 0) {
      final notification = _notifications[index];
      _notifications[index] = notification.copyWith(isRead: true);
    }
    debugPrint('Marking notification $id as read');
  }
  
  // Créer une notification pour une réservation en retard
  Notification createLateReservationNotification(Reservation reservation) {
    final notification = Notification(
      id: _generateUniqueId(),
      message: 'Votre réservation du ${_formatDate(reservation.date)} à ${reservation.timeSlot} est en retard (10 minutes). '
               'Veuillez contacter le restaurant pour confirmer votre présence.',
      date: DateTime.now(),
      type: NotificationType.late,
      reservationId: reservation.id,
    );
    
    _notifications.insert(0, notification); // Ajouter au début de la liste
    debugPrint('Notification de retard créée pour la réservation: ${reservation.id}');
    return notification;
  }
  
  // Créer une notification pour une réservation annulée
  Notification createCanceledReservationNotification(Reservation reservation) {
    final notification = Notification(
      id: _generateUniqueId(),
      message: 'Votre réservation du ${_formatDate(reservation.date)} à ${reservation.timeSlot} a été automatiquement annulée '
               'en raison d\'un retard de plus de 20 minutes.',
      date: DateTime.now(),
      type: NotificationType.canceled,
      reservationId: reservation.id,
    );
    
    _notifications.insert(0, notification); // Ajouter au début de la liste
    debugPrint('Notification d\'annulation créée pour la réservation: ${reservation.id}');
    return notification;
  }
  
  // Helper pour formater la date
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
  
  // Récupérer le nombre de notifications non lues
  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }
  
  // Vérifier si une notification existe déjà pour une réservation
  bool hasNotificationForReservation(String reservationId, NotificationType type) {
    return _notifications.any((notification) => 
      notification.reservationId == reservationId && 
      notification.type == type
    );
  }
}