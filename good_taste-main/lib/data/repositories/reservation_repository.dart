// lib/data/repositories/reservation_repository.dart
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/services/reservation_service.dart';

import 'package:good_taste/di/di.dart';

class ReservationRepository {
  final ReservationService _service;

  ReservationRepository() : _service = DependencyInjection.getReservationService();

  
  List<String> getAvailableTimeSlots({DateTime? selectedDate}) {
    final DateTime now = DateTime.now();
    final DateTime date = selectedDate ?? now;
    final bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    // Liste complète des horaires
    List<String> allTimeSlots = ['10h-12h', '12h-14h', '14h-16h', '18h-20h', '20h-22h', '22h-00h'];
    
    // Si la date est aujourd'hui, filtrer les horaires passés
    if (isToday) {
      return allTimeSlots.where((timeSlot) => !isTimeSlotPassed(timeSlot, now)).toList();
    }
    
    // Si la date est future, retourner tous les horaires
    return allTimeSlots;
  }

  bool isTimeSlotPassed(String timeSlot, DateTime now) {
    // Extraire l'heure de début du timeSlot (format: "10h-12h")
    final String startHourStr = timeSlot.split('h')[0];
    int startHour = int.parse(startHourStr);
    
    // Comparer avec l'heure actuelle
    return startHour <= now.hour;
  }

   bool isCustomTimeSlotPassed(String customTimeSlot, DateTime now) {
    // Format du timeSlot personnalisé: "10h-12h"
    final String startHourStr = customTimeSlot.split('h-')[0];
    int startHour = int.parse(startHourStr);
    
    // Comparer avec l'heure actuelle
    return startHour <= now.hour;
  }



 Future<Reservation> makeReservation({
    required String userId,
    required DateTime date,
    required String timeSlot,
    required int numberOfPeople,
    required String tableType,
  }) async {
    try {
      return await _service.addReservation(
        userId: userId,
        date: date,
        timeSlot: timeSlot,
        numberOfPeople: numberOfPeople,
        tableNumber: tableType,
      );
    } catch (e) {
      debugPrint('Reservation failed: $e');
      rethrow;
    }
  }

  Future<bool> hasActiveReservation(String userId) async {
    return await _service.hasActiveReservation(userId);
  }

 // Vérifier si une table est disponible
  Future<bool> isTableAvailable(String tableNumber, DateTime date, String timeSlot) async {
    return _service.isTableAvailable(tableNumber, date, timeSlot);
  }
  
  // Obtenir toutes les tables disponibles
  Future<List<String>> getAvailableTables(DateTime date, String timeSlot, int numberOfPeople) async {
    return _service.getAvailableTables(date, timeSlot, numberOfPeople);
  }
  
  // Suggérer une table alternative
  Future<String?> suggestAlternativeTable(DateTime date, String timeSlot, int numberOfPeople) async {
    return _service.suggestAlternativeTable(date, timeSlot, numberOfPeople);
  }

  bool isValidCustomTimeSlot(String customTimeSlot) {
  // Format attendu: "10h-12h"
  final RegExp timeSlotRegex = RegExp(r'^\d{1,2}h-\d{1,2}h$');
  if (!timeSlotRegex.hasMatch(customTimeSlot)) {
    return false;
  }
  
  try {
    // Extraire et valider les heures
    final int startHour = int.parse(customTimeSlot.split('h-')[0]);
    int endHour = int.parse(customTimeSlot.split('-')[1].split('h')[0]);
    
    // Convertir 0h en 24h pour les calculs
    if (endHour == 0) {
      endHour = 24;
    }
    
    // Vérifier que les heures sont valides (0-24) et que l'heure de fin est après l'heure de début
    return (startHour >= 0 && startHour <= 24 &&
            endHour >= 0 && endHour <= 24 &&
            endHour > startHour);
  } catch (e) {
    return false;
  }
}

  Future<List<Reservation>> checkAndUpdateLateReservations(List<Reservation> reservations) async {
    List<Reservation> updatedReservations = [];
    bool hasChanges = false;
    
    for (var reservation in reservations) {
      Reservation currentReservation = reservation;
      
      // Vérifier si la réservation est en retard et doit être mise à jour
      final Reservation? updatedReservation = await _service.updateReservationStatusBasedOnDelay(reservation);
      
      if (updatedReservation != null) {
        // Si une mise à jour est nécessaire, remplacer la réservation
        currentReservation = updatedReservation;
        hasChanges = true;
        
        // Mettre à jour dans la "base de données"
        if (updatedReservation.status == ReservationStatus.canceled) {
          await _service.cancelReservation(reservation.id);
        } else if (updatedReservation.status == ReservationStatus.late) {
          // Utiliser la nouvelle méthode pour marquer comme en retard
          await _service.markReservationAsLate(reservation.id);
        }
      }
      
      updatedReservations.add(currentReservation);
    }
    
    return updatedReservations;
  }
}
