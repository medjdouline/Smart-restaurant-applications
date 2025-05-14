// lib/data/models/reservation.dart
import 'package:equatable/equatable.dart';

enum ReservationStatus {
  confirmed,
  pending,
  canceled,
  completed
}

class Reservation extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final String timeSlot;
  final int numberOfPeople;
  final String tableNumber;
  final ReservationStatus status;

  const Reservation({
    required this.id,
    required this.userId,
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    required this.tableNumber,
    required this.status,
  });

  @override
  List<Object?> get props => [id, userId, date, timeSlot, numberOfPeople, tableNumber, status];

  // Pour transformer le statut en texte français pour l'affichage
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
    }
  }

  // Pour obtenir la couleur du statut
  String get statusColor {
    switch (status) {
      case ReservationStatus.confirmed:
        return '#2E582C'; // Vert
      case ReservationStatus.pending:
        return '#E8B38C'; // Orange clair
      case ReservationStatus.canceled:
        return '#B85C38'; // Rouge
      case ReservationStatus.completed:
        return '#888888'; // Gris
    }
  }
}




