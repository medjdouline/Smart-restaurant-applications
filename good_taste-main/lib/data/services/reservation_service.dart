// lib/data/services/reservation_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/services/table_service.dart';
import 'package:flutter/material.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_taste/data/api/api_client.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/models/user.dart';

class ReservationService {
  final ApiClient _apiClient;
  final AuthRepository _authRepo;

  ReservationService({
    required ApiClient apiClient,
    required AuthRepository authRepo, // Ajouté
  }) : _apiClient = apiClient, _authRepo = authRepo;


  Future<Reservation> addReservation({
  required String userId,
  required DateTime date,
  required String timeSlot,
  required int numberOfPeople,
  required String tableNumber, // Doit être un numéro ("1", "2", etc.)
}) async {
  try {
    // 1. Validation des données
    if (numberOfPeople <= 0 || numberOfPeople > 8) {
      throw Exception('Le nombre de personnes doit être entre 1 et 8');
    }

    if (!RegExp(r'^\d+h-\d+h$').hasMatch(timeSlot)) {
      throw Exception('Format de créneau horaire invalide (ex: 18h-20h)');
    }

    // 2. Formatage des données
    final dateStr = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    final startTime = '${timeSlot.split('h')[0]}:00'; // "18h-20h" → "18:00"
    final firestoreTableId = 'table$tableNumber'; // "3" → "table3"

    // 3. Récupération du token
    final token = await _getAuthToken(); 
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non authentifié');
    }

    // 4. Appel API
    final response = await _apiClient.post(
      'client-mobile/reservations/create/', // URL corrigée
      {
        'date': dateStr,
        'time': startTime,
        'party_size': numberOfPeople,
        'table_id': firestoreTableId, // Envoie l'ID complet "table3"
      },
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // 5. Gestion de la réponse
    if (response.success) {
      return Reservation(
        id: response.data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        date: date,
        timeSlot: timeSlot,
        numberOfPeople: numberOfPeople,
        tableNumber: tableNumber, // Garde le numéro simple côté Flutter
        status: ReservationStatus.confirmed,
      );
    } else {
      // Gestion des erreurs spécifiques du backend
      final errorMsg = response.error ?? 'Erreur inconnue';
      if (errorMsg.contains('Table not found')) {
        throw Exception('Table $tableNumber non trouvée');
      } else if (errorMsg.contains('insufficient capacity')) {
        throw Exception('La table $tableNumber ne peut pas accueillir $numberOfPeople personnes');
      } else {
        throw Exception(errorMsg);
      }
    }
  } catch (e) {
    debugPrint('Erreur de réservation - ${e.toString()}');
    rethrow; // Important pour que le bloc puisse catcher l'erreur
  }
} 

  Future<bool> hasActiveReservation(String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _apiClient.post(
        'client-mobile/reservations/',
        {},
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.success && (response.data['has_active'] ?? false);
    } catch (e) {
      debugPrint('Error checking active reservation: $e');
      return false;
    }
  }

Future<String?> _getAuthToken() async {
  return _authRepo.getAuthToken(); // Use the AuthRepository method instead
}


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



// Récupérer toutes les réservations
Future<List<Reservation>> getReservations(User user) async {
  try {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiClient.get(
      'client-mobile/reservations/',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.success) {
      final List<dynamic> reservationsData = response.data;
      
      return reservationsData.map((data) {
        // Convertir la date_time du backend
        DateTime reservationDate;
        String timeSlot;
        
        try {
          final dateTimeStr = data['date_time'] as String;
          final dateTime = DateTime.parse(dateTimeStr);
          reservationDate = dateTime;
          
          // Extraire le timeSlot depuis la date_time
          // Supposons un format comme "18:00" pour l'heure de début
          final hour = dateTime.hour;
          timeSlot = '${hour}h-${hour + 2}h'; // Durée de 2h par défaut
        } catch (e) {
          debugPrint('Erreur parsing date_time: $e');
          reservationDate = DateTime.now();
          timeSlot = '18h-20h';
        }

        return Reservation(
          id: data['id'].toString(),
          userId: user.id,
          date: reservationDate,
          timeSlot: timeSlot,
          numberOfPeople: data['party_size'] ?? 0,
          tableNumber: data['table']?['number']?.toString() ?? '1',
          status: _mapStatusFromApi(data['status']),
        );
      }).toList();
    } else {
      if (response.error?.contains('No reservations found') == true) {
        return []; // Retourner liste vide si aucune réservation
      }
      throw Exception(response.error ?? 'Erreur lors de la récupération des réservations');
    }
  } catch (e) {
    debugPrint('Erreur getReservations: $e');
    throw Exception('Impossible de récupérer les réservations: $e');
  }
}
ReservationStatus _mapStatusFromApi(String? apiStatus) {
  switch (apiStatus?.toLowerCase()) {
    case 'confirmed':
      return ReservationStatus.confirmed;
    case 'pending':
      return ReservationStatus.pending;
    case 'cancelled':
    case 'canceled':
      return ReservationStatus.canceled;
    case 'completed':
      return ReservationStatus.completed;
    case 'late':
      return ReservationStatus.late;
    default:
      return ReservationStatus.pending;
  }
}

Future<bool> cancelReservation(String reservationId) async {
  try {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiClient.post(
      'reservations/$reservationId/cancel/', 
      {},
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.success) {
      debugPrint('Réservation annulée avec succès: $reservationId');
      return true;
    } else {
      debugPrint('Erreur annulation réservation: ${response.error}');
      return false;
    }
  } catch (e) {
    debugPrint('Exception lors de l\'annulation: $e');
    return false;
  }
}

Future<bool> deleteReservation(String reservationId) async {
  // Pour l'instant, on garde la logique locale
  // Vous pourrez ajouter un endpoint backend plus tard si nécessaire
  await Future.delayed(const Duration(milliseconds: 500));
  
  final initialLength = _reservations.length;
  _reservations.removeWhere((reservation) => reservation.id == reservationId);
  
  final success = _reservations.length < initialLength;
  debugPrint('Réservation supprimée: $reservationId, Succès: $success');
  
  return success;
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