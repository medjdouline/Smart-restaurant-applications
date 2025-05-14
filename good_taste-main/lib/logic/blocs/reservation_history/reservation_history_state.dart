// lib/logic/blocs/reservation_history/reservation_history_state.dart
part of 'reservation_history_bloc.dart';

abstract class ReservationHistoryState extends Equatable {
  const ReservationHistoryState();
  
  @override
  List<Object> get props => [];
}

class ReservationHistoryInitial extends ReservationHistoryState {}

class ReservationHistoryLoading extends ReservationHistoryState {}

class ReservationHistoryLoaded extends ReservationHistoryState {
  final List<Reservation> reservations;

  const ReservationHistoryLoaded({required this.reservations});

  @override
  List<Object> get props => [reservations];
}

class ReservationHistoryError extends ReservationHistoryState {
  final String message;

  const ReservationHistoryError({required this.message});

  @override
  List<Object> get props => [message];
}