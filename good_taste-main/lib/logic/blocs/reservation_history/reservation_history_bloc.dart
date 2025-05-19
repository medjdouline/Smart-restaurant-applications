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
    on<CheckLateReservations>(_onCheckLateReservations);
  }

  void _onLoadReservationHistory(
    LoadReservationHistory event,
    Emitter<ReservationHistoryState> emit,
  ) async {
    emit(ReservationHistoryLoading());
    try {
      final user = authBloc.state.user;
      final reservations = await repository.getReservationHistory(user);
      
      // Vérifier et mettre à jour les réservations en retard
      final updatedReservations = await repository.checkAndUpdateLateReservations(reservations);
      
      emit(ReservationHistoryLoaded(reservations: updatedReservations));
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

  void _onCheckLateReservations(
    CheckLateReservations event,
    Emitter<ReservationHistoryState> emit,
  ) async {
    if (state is ReservationHistoryLoaded) {
      final currentState = state as ReservationHistoryLoaded;
      
      try {
        // Vérifier et mettre à jour les réservations en retard
        // Cette méthode va maintenant aussi créer des notifications
        final updatedReservations = await repository.checkAndUpdateLateReservations(currentState.reservations);
        
        // Émettre le nouvel état uniquement si des changements ont été effectués
        if (!_areReservationsEqual(currentState.reservations, updatedReservations)) {
          emit(ReservationHistoryLoaded(reservations: updatedReservations));
        }
      } catch (e) {
        emit(ReservationHistoryError(message: e.toString()));
      }
    }
  }

  bool _areReservationsEqual(List<Reservation> list1, List<Reservation> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].status != list2[i].status) return false;
    }
    
    return true;
  }
}