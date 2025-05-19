// lib/data/repositories/reservation_history_repository.dart
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/services/reservation_service.dart';
import 'package:good_taste/data/repositories/notification_repository.dart';

class ReservationHistoryRepository {
  final ReservationService _service = ReservationService();
  final NotificationRepository _notificationRepository = NotificationRepository();
  
  // Garder une trace des notifications déjà créées pour éviter les doublons
  final Set<String> _lateNotificationsSent = {};
  final Set<String> _canceledNotificationsSent = {};

  Future<List<Reservation>> getReservationHistory(User user) async {
    final reservations = await _service.getReservations(user);
    // Vérifier et mettre à jour les réservations en retard lors du chargement
    return await checkAndUpdateLateReservations(reservations);
  }

  Future<bool> deleteReservation(String reservationId) async {
    return _service.deleteReservation(reservationId);
  }
 
  Future<bool> cancelReservation(String reservationId) async {
    return _service.cancelReservation(reservationId);
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