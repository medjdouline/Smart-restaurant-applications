// lib/data/repositories/reservation_history_repository.dart
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/services/reservation_service.dart';
import 'package:good_taste/data/repositories/notification_repository.dart';
import 'package:good_taste/di/di.dart';


class ReservationHistoryRepository {
  final ReservationService _service;
  final NotificationRepository _notificationRepository;
  
  ReservationHistoryRepository() 
    : _service = DependencyInjection.getReservationService(),
      _notificationRepository = NotificationRepository();

  
  // Garder une trace des notifications déjà créées pour éviter les doublons
  final Set<String> _lateNotificationsSent = {};
  final Set<String> _canceledNotificationsSent = {};

Future<List<Reservation>> getReservationHistory(User user) async {
  try {
    // Récupérer les réservations depuis l'API au lieu des données locales
    final reservations = await _service.getReservations(user);
    
    // Vérifier et mettre à jour les réservations en retard localement
    return await checkAndUpdateLateReservations(reservations);
  } catch (e) {
    debugPrint('Erreur lors de la récupération de l\'historique: $e');
    // En cas d'erreur, retourner une liste vide ou relancer l'exception
    rethrow;
  }
}

  Future<bool> deleteReservation(String reservationId) async {
    return _service.deleteReservation(reservationId);
  }
 
  Future<bool> cancelReservation(String reservationId) async {
  try {
    // Utiliser l'API pour annuler la réservation
    final success = await _service.cancelReservation(reservationId);
    
    if (success) {
      // Ajouter la réservation aux notifications d'annulation
      if (!_canceledNotificationsSent.contains(reservationId)) {
        // Vous pourriez vouloir récupérer les détails de la réservation pour la notification
        // Pour l'instant, on marque juste comme envoyée
        _canceledNotificationsSent.add(reservationId);
      }
    }
    
    return success;
  } catch (e) {
    debugPrint('Erreur lors de l\'annulation de la réservation: $e');
    return false;
  }
}

  Future<List<Reservation>> checkAndUpdateLateReservations(List<Reservation> reservations) async {
    List<Reservation> updatedReservations = [];
    bool hasChanges = false;
    
    for (var reservation in reservations) {
      Reservation currentReservation = reservation;
      
      // Vérifier seulement les réservations pending ou late
      if (reservation.status == ReservationStatus.pending || 
          reservation.status == ReservationStatus.late) {
        
        final Reservation? updatedReservation = await _service.updateReservationStatusBasedOnDelay(reservation);
        
        if (updatedReservation != null) {
          currentReservation = updatedReservation;
          hasChanges = true;
          
          // Gérer les notifications selon le nouveau statut
          if (updatedReservation.status == ReservationStatus.late &&
              !_lateNotificationsSent.contains(reservation.id)) {
            // Créer une notification de retard seulement si pas déjà envoyée
            _notificationRepository.createLateReservationNotification(updatedReservation);
            _lateNotificationsSent.add(reservation.id);
            
            // Mettre à jour dans le service
            await _service.markReservationAsLate(reservation.id);
          } 
          else if (updatedReservation.status == ReservationStatus.canceled &&
                   !_canceledNotificationsSent.contains(reservation.id)) {
            // Créer une notification d'annulation seulement si pas déjà envoyée
            _notificationRepository.createCanceledReservationNotification(updatedReservation);
            _canceledNotificationsSent.add(reservation.id);
            
            // Mettre à jour dans le service
            await _service.cancelReservation(reservation.id);
          }
        }
      }
      
      updatedReservations.add(currentReservation);
    }
    
    return updatedReservations;
  }
  
  // Méthode pour réinitialiser les sets de notifications (utile pour les tests)
  void resetNotificationTracking() {
    _lateNotificationsSent.clear();
    _canceledNotificationsSent.clear();
  }
}