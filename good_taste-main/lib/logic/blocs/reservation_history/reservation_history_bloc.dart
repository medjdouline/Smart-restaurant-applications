// lib/logic/blocs/reservation_history/reservation_history_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/repositories/reservation_history_repository.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';

part 'reservation_history_event.dart';
part 'reservation_history_state.dart';

class ReservationHistoryBloc extends Bloc<ReservationHistoryEvent, ReservationHistoryState> {
  final ReservationHistoryRepository repository;
  final AuthBloc authBloc;

  ReservationHistoryBloc({
    required this.repository,
    required this.authBloc,
  }) : super(ReservationHistoryInitial()) {
    on<LoadReservationHistory>(_onLoadReservationHistory);
    on<DeleteReservation>(_onDeleteReservation);
    on<CancelReservation>(_onCancelReservation);
  }

  void _onLoadReservationHistory(
    LoadReservationHistory event,
    Emitter<ReservationHistoryState> emit,
  ) async {
    emit(ReservationHistoryLoading());
    try {
      final user = authBloc.state.user;
      final reservations = await repository.getReservationHistory(user);
      emit(ReservationHistoryLoaded(reservations: reservations));
    } catch (e) {
      emit(ReservationHistoryError(message: e.toString()));
    }
  }

  void _onDeleteReservation(
    DeleteReservation event,
    Emitter<ReservationHistoryState> emit,
  ) async {
    if (state is ReservationHistoryLoaded) {
      final currentState = state as ReservationHistoryLoaded;
      emit(ReservationHistoryLoading());
      
      try {
        final result = await repository.deleteReservation(event.reservationId);
        if (result) {
          // Supprimer la réservation de la liste
          final updatedReservations = currentState.reservations
              .where((reservation) => reservation.id != event.reservationId)
              .toList();
              
          emit(ReservationHistoryLoaded(reservations: updatedReservations));
        } else {
          emit(ReservationHistoryError(message: "Échec de la suppression"));
        }
      } catch (e) {
        emit(ReservationHistoryError(message: e.toString()));
      }
    }
  }

void _onCancelReservation(
    CancelReservation event,
    Emitter<ReservationHistoryState> emit,
  ) async {
    if (state is ReservationHistoryLoaded) {
      final currentState = state as ReservationHistoryLoaded;
      emit(ReservationHistoryLoading());
      
      try {
        final result = await repository.cancelReservation(event.reservationId);
        if (result) {
          // Mettre à jour la réservation dans la liste
          final updatedReservations = currentState.reservations.map((reservation) {
            if (reservation.id == event.reservationId) {
              // Créer une nouvelle réservation avec le statut 'canceled'
              return Reservation(
                id: reservation.id,
                userId: reservation.userId,
                date: reservation.date,
                timeSlot: reservation.timeSlot,
                numberOfPeople: reservation.numberOfPeople,
                tableNumber: reservation.tableNumber,
                status: ReservationStatus.canceled,
              );
            }
            return reservation;
          }).toList();
              
          emit(ReservationHistoryLoaded(reservations: updatedReservations));
        } else {
          emit(ReservationHistoryError(message: "Échec de l'annulation"));
        }
      } catch (e) {
        emit(ReservationHistoryError(message: e.toString()));
      }
    }
  }
}

