// Dans reservation.dart - Ajout d'une méthode factory pour créer depuis l'API

class Reservation {
  final String id;
  final String userId;
  final DateTime date;
  final String timeSlot;
  final int numberOfPeople;
  final String tableNumber;
  final ReservationStatus status;

  Reservation({
    required this.id,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    required this.tableNumber,
    required this.status,
  });

  // Factory constructor pour créer depuis les données de l'API
  factory Reservation.fromApiData(Map<String, dynamic> data, String userId) {
    // Convertir la date_time du backend
    DateTime reservationDate;
    String timeSlot;
    
    try {
      final dateTimeStr = data['date_time'] as String;
      final dateTime = DateTime.parse(dateTimeStr);
      reservationDate = dateTime;
      
      // Extraire le timeSlot depuis la date_time
      final hour = dateTime.hour;
      timeSlot = '${hour}h-${hour + 2}h'; // Durée de 2h par défaut
    } catch (e) {
      reservationDate = DateTime.now();
      timeSlot = '18h-20h';
    }

    return Reservation(
      id: data['id'].toString(),
      userId: userId,
      date: reservationDate,
      timeSlot: timeSlot,
      numberOfPeople: data['party_size'] ?? 0,
      tableNumber: data['table']?['number']?.toString() ?? '1',
      status: _mapStatusFromApi(data['status']),
    );
  }

  // Méthode statique pour mapper les statuts
  static ReservationStatus _mapStatusFromApi(String? apiStatus) {
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

  // Getter pour le texte du statut
  String get statusText {
    switch (status) {
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.canceled:
        return 'Annulée';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.late:
        return 'En retard';
    }
  }
}

enum ReservationStatus {
  confirmed,
  pending,
  canceled,
  completed,
  late,
}