// lib/logic/blocs/reservation_history/reservation_history_event.dart
part of 'reservation_history_bloc.dart';

abstract class ReservationHistoryEvent extends Equatable {
  const ReservationHistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadReservationHistory extends ReservationHistoryEvent {}

class DeleteReservation extends ReservationHistoryEvent {
  final String reservationId;

  const DeleteReservation(this.reservationId);

  @override
  List<Object> get props => [reservationId];
}

class CancelReservation extends ReservationHistoryEvent {
  final String reservationId;

  const CancelReservation(this.reservationId);

  @override
  List<Object> get props => [reservationId];
}

class CheckLateReservations extends ReservationHistoryEvent {
  const CheckLateReservations();

  @override
  List<Object> get props => [];
}