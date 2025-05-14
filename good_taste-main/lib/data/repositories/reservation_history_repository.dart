// lib/data/repositories/reservation_history_repository.dart
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/models/user.dart';
import 'package:good_taste/data/services/reservation_service.dart';

class ReservationHistoryRepository {
  final ReservationService _service = ReservationService();

  
  Future<List<Reservation>> getReservationHistory(User user) async {
    return _service.getReservations(user);
  }

  
  Future<bool> deleteReservation(String reservationId) async {
    return _service.deleteReservation(reservationId);
  }
 
Future<bool> cancelReservation(String reservationId) async {
  return _service.cancelReservation(reservationId);
}
}