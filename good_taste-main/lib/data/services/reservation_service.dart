// lib/data/services/reservation_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/services/table_service.dart';

class ReservationService {
  // Singleton pattern
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  // Liste de réservations en mémoire (simulée)
  final List<Reservation> _reservations = [];

 static const String _customTimeSlotsKey = 'custom_time_slots';

     Future<bool> saveCustomTimeSlots(List<String> customTimeSlots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customTimeSlotsKey, customTimeSlots);
      debugPrint('Créneaux personnalisés sauvegardés: $customTimeSlots');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des créneaux personnalisés: $e');
      return false;
    }
  }

   Future<List<String>> getCustomTimeSlots() async {
  try {
      final prefs = await SharedPreferences.getInstance();
      final customTimeSlots = prefs.getStringList(_customTimeSlotsKey) ?? [];
      debugPrint('Créneaux personnalisés récupérés: $customTimeSlots');
      return customTimeSlots;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des créneaux personnalisés: $e');
      return [];
    }
  }

  // Générer un ID unique
  String _generateUniqueId() {
    final random = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           random.nextInt(9999).toString();
  }

  // Ajouter une nouvelle réservation
  // Ajouter une nouvelle réservation
Future<Reservation> addReservation({
  required String userId,
  required DateTime date,
  required String timeSlot,
  required int numberOfPeople,
  String tableNumber = '5', // Valeur par défaut simulée
}) async {
  // Simuler un délai réseau
  await Future.delayed(const Duration(seconds: 1));
  
  final newReservation = Reservation(
    id: _generateUniqueId(),
    userId: userId, // Ajout de l'ID utilisateur
    date: date,
    timeSlot: timeSlot,
    numberOfPeople: numberOfPeople,
    tableNumber: tableNumber,
    status: ReservationStatus.pending, // Statut 'en attente' par défaut
  );
  
  _reservations.add(newReservation);
  debugPrint('Nouvelle réservation ajoutée: ${newReservation.id} pour utilisateur: $userId');
  
  return newReservation;
}

Future<bool> hasActiveReservation(String userId) async {
  // Simuler un délai réseau
  await Future.delayed(const Duration(milliseconds: 500));
  
 
  bool hasActive = _reservations.any((reservation) => 
    (reservation.userId ?? '') == userId && 
    (reservation.status == ReservationStatus.confirmed || 
     reservation.status == ReservationStatus.pending)
  );
  
  debugPrint('L\'utilisateur $userId a une réservation active: $hasActive');
  return hasActive;
}

// Récupérer toutes les réservations
Future<List<Reservation>> getReservations(User user) async {
  // Simuler un délai réseau
  await Future.delayed(const Duration(milliseconds: 800));
  
 
  if (_reservations.isEmpty) {
    _reservations.addAll([
      
    ]);
  }
  
  return [..._reservations];
}



  Future<bool> deleteReservation(String reservationId) async {
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final initialLength = _reservations.length;
    _reservations.removeWhere((reservation) => reservation.id == reservationId);
    
    final success = _reservations.length < initialLength;
    debugPrint('Réservation supprimée: $reservationId, Succès: $success');
    
    return success;
  }


Future<bool> cancelReservation(String reservationId) async {
  // Simuler un délai réseau
  await Future.delayed(const Duration(milliseconds: 500));
  
  final reservationIndex = _reservations.indexWhere(
    (reservation) => reservation.id == reservationId
  );
  
  if (reservationIndex >= 0) {
    // Vérifier si la réservation peut être annulée (confirmée ou en attente)
    final reservation = _reservations[reservationIndex];
    if (reservation.status == ReservationStatus.confirmed || 
        reservation.status == ReservationStatus.pending) {
      
      // Créer une nouvelle réservation avec le statut 'canceled'
      final updatedReservation = Reservation(
        id: reservation.id,
        userId: reservation.userId,
        date: reservation.date,
        timeSlot: reservation.timeSlot,
        numberOfPeople: reservation.numberOfPeople,
        tableNumber: reservation.tableNumber,
        status: ReservationStatus.canceled,
      );
      
      // Remplacer la réservation dans la liste
      _reservations[reservationIndex] = updatedReservation;
      debugPrint('Réservation annulée: $reservationId');
      return true;
    }
  }
  
  debugPrint('Échec de l\'annulation de la réservation: $reservationId');
  return false;
}
  // Vérifier si une table est disponible à une date et heure spécifique
Future<bool> isTableAvailable(String tableNumber, DateTime date, String timeSlot) async {
  // Simuler un délai réseau
  await Future.delayed(const Duration(milliseconds: 300));
  
  final String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  
  // Extraire les heures de début et de fin du créneau demandé
  final int startHourRequested = int.parse(timeSlot.split('h')[0]);
  int endHourRequested = int.parse(timeSlot.split('-')[1].split('h')[0]);
  if (endHourRequested == 0) { // Si l'heure de fin est 00h, la considérer comme minuit (24h)
    endHourRequested = 24;
  }
  
  // Vérifier s'il existe une réservation pour cette table à cette date avec un créneau qui chevauche
  bool hasOverlap = _reservations.any((reservation) => 
    reservation.tableNumber == tableNumber && 
    "${reservation.date.year}-${reservation.date.month.toString().padLeft(2, '0')}-${reservation.date.day.toString().padLeft(2, '0')}" == dateStr &&
    (reservation.status == ReservationStatus.confirmed || reservation.status == ReservationStatus.pending) &&
    _hasTimeOverlap(reservation.timeSlot, timeSlot)
  );
  
  bool isAvailable = !hasOverlap;
  
  debugPrint('Table $tableNumber disponible le $dateStr à $timeSlot: $isAvailable');
  return isAvailable;
}

// Nouvelle fonction pour vérifier si deux créneaux horaires se chevauchent
bool _hasTimeOverlap(String timeSlot1, String timeSlot2) {
  // Extraire les heures de début et de fin du premier créneau
  final int startHour1 = int.parse(timeSlot1.split('h')[0]);
  int endHour1 = int.parse(timeSlot1.split('-')[1].split('h')[0]);
  if (endHour1 == 0) { // Si l'heure de fin est 00h, la considérer comme minuit (24h)
    endHour1 = 24;
  }
  
  // Extraire les heures de début et de fin du deuxième créneau
  final int startHour2 = int.parse(timeSlot2.split('h')[0]);
  int endHour2 = int.parse(timeSlot2.split('-')[1].split('h')[0]);
  if (endHour2 == 0) { // Si l'heure de fin est 00h, la considérer comme minuit (24h)
    endHour2 = 24;
  }
  
  // Vérifier s'il y a chevauchement (une plage chevauche l'autre si le début de l'une est avant la fin de l'autre et vice versa)
  return (startHour1 < endHour2 && endHour1 > startHour2);
}

  // Obtenir toutes les tables disponibles à une date et heure spécifique
  Future<List<String>> getAvailableTables(DateTime date, String timeSlot, int numberOfPeople) async {
  // Simuler un délai réseau
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Obtenir toutes les tables du restaurant via le service de tables qui peuvent accueillir ce nombre de personnes
  final tableService = TableService();
  final allTables = tableService.getTablesByCapacity(numberOfPeople);
  
  // Filtrer les tables disponibles à l'horaire spécifié
  List<String> availableTables = [];
  
  for (var table in allTables) {
    // Vérifier si la table est disponible pour ce créneau horaire
    bool isAvailable = await isTableAvailable(table.number, date, timeSlot);
    if (isAvailable) {
      availableTables.add(table.number);
    }
  }
  
  debugPrint('Tables disponibles pour $numberOfPeople personnes le ${date.toString()} à $timeSlot: $availableTables');
  return availableTables;
}

  // Suggérer une table alternative
  Future<String?> suggestAlternativeTable(DateTime date, String timeSlot, int numberOfPeople) async {
    final availableTables = await getAvailableTables(date, timeSlot, numberOfPeople);
    
    if (availableTables.isNotEmpty) {
      // Retourner la première table disponible comme suggestion
      return availableTables.first;
    }
    
    return null; // Aucune table disponible
  }

  bool isReservationLate(Reservation reservation) {
    if (reservation.status != ReservationStatus.pending) {
      return false;
    }
    
    final DateTime now = DateTime.now();
    final DateTime reservationDateTime = _getReservationDateTime(reservation);
    
    // Calculer la différence en minutes
    final difference = now.difference(reservationDateTime).inMinutes;
    
    return difference >= 10; // En retard si 10 minutes ou plus
  }

   bool isReservationVeryLate(Reservation reservation) {
    if (reservation.status != ReservationStatus.pending && 
        reservation.status != ReservationStatus.late) {
      return false;
    }
    
    final DateTime now = DateTime.now();
    final DateTime reservationDateTime = _getReservationDateTime(reservation);
    
    // Calculer la différence en minutes
    final difference = now.difference(reservationDateTime).inMinutes;
    
    return difference >= 20; // Très en retard si 20 minutes ou plus
  }

    DateTime _getReservationDateTime(Reservation reservation) {
    // Extraire l'heure de début du timeSlot (format: "10h-12h")
    final String startHourStr = reservation.timeSlot.split('h')[0];
    final int startHour = int.parse(startHourStr);
    
    // Créer un DateTime combinant la date de réservation et l'heure de début
    return DateTime(
      reservation.date.year,
      reservation.date.month,
      reservation.date.day,
      startHour,
      0, // minutes
    );
  }

   Future<Reservation?> updateReservationStatusBasedOnDelay(Reservation reservation) async {
    // Vérifier si très en retard (20 minutes ou plus)
    if (isReservationVeryLate(reservation)) {
      // Annuler la réservation
      return Reservation(
        id: reservation.id,
        userId: reservation.userId,
        date: reservation.date,
        timeSlot: reservation.timeSlot,
        numberOfPeople: reservation.numberOfPeople,
        tableNumber: reservation.tableNumber,
        status: ReservationStatus.canceled, // Passer à annulé
      );
    } 
    // Vérifier si en retard (10 minutes ou plus)
    else if (isReservationLate(reservation)) {
      // Marquer comme en retard
      return Reservation(
        id: reservation.id,
        userId: reservation.userId,
        date: reservation.date,
        timeSlot: reservation.timeSlot,
        numberOfPeople: reservation.numberOfPeople,
        tableNumber: reservation.tableNumber,
        status: ReservationStatus.late, // Passer à en retard
      );
    }
    
    // Pas de changement nécessaire
    return null;
  }

    Future<bool> markReservationAsLate(String reservationId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    final reservationIndex = _reservations.indexWhere(
      (reservation) => reservation.id == reservationId
    );
    
    if (reservationIndex >= 0) {
      final reservation = _reservations[reservationIndex];
      if (reservation.status == ReservationStatus.pending) {
        // Créer une nouvelle réservation avec le statut 'late'
        final updatedReservation = Reservation(
          id: reservation.id,
          userId: reservation.userId,
          date: reservation.date,
          timeSlot: reservation.timeSlot,
          numberOfPeople: reservation.numberOfPeople,
          tableNumber: reservation.tableNumber,
          status: ReservationStatus.late,
        );
        
        // Remplacer la réservation dans la liste
        _reservations[reservationIndex] = updatedReservation;
        debugPrint('Réservation marquée en retard: $reservationId');
        return true;
      }
    }
    
    debugPrint('Échec du marquage en retard de la réservation: $reservationId');
    return false;
  }
}